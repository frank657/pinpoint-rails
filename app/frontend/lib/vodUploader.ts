// Orchestrates the full Aliyun VOD direct-upload flow for one video file.
//
// Lifecycle:
//   idle → requesting → uploading → verifying → uploaded
//                   ↘ failed
//                   ↘ aborted
//
// Usage:
//   const up = new VodUploader(file, { filename: file.name, onState, onProgress })
//   const { signedId } = await up.start()
//   // Then call POST /videos with the signedId to create the Video record.
//
// Key design choices (matching the reference mini-program implementation):
//   - Resolve as soon as the backend confirms "uploaded" (mezzanine playable).
//     Don't block on transcoding — the caller can attach the video immediately.
//   - On 403 from OSS (STS token expired mid-upload), retry ONCE from the top.
//   - STS credentials are checked for expiry (30s grace) before the OSS call.

import axios from 'axios'

export type UploaderState =
  | 'idle'
  | 'requesting'
  | 'uploading'
  | 'verifying'
  | 'uploaded'
  | 'failed'
  | 'aborted'

export interface VodUploaderOptions {
  filename: string
  title?: string
  onState?: (state: UploaderState) => void
  onProgress?: (percent: number) => void
}

export interface UploadResult {
  signedId: string
}

const POLL_INTERVAL_MS = 1500
const POLL_MAX_ATTEMPTS = 30 // ~45s ceiling

export class VodUploader {
  private _state: UploaderState = 'idle'
  private _aborted = false
  private _retried = false
  private _signedId = ''

  constructor(
    private file: File,
    private opts: VodUploaderOptions,
  ) {}

  get state(): UploaderState {
    return this._state
  }
  get signedId(): string {
    return this._signedId
  }

  abort() {
    this._aborted = true
    this._setState('aborted')
  }

  start(): Promise<UploadResult> {
    return this._run()
  }

  private _setState(next: UploaderState) {
    if (this._state === next) return
    this._state = next
    this.opts.onState?.(next)
  }

  private async _run(): Promise<UploadResult> {
    if (this._aborted) throw new Error('aborted')
    this._setState('requesting')

    const { data: creds } = await axios.post<{
      signedId: string
      uploadAddress: string
      uploadAuth: string
    }>('/vod/direct_uploads', {
      filename: this.opts.filename,
      title: this.opts.title ?? this.opts.filename,
    })

    if (this._aborted) throw new Error('aborted')
    this._signedId = creds.signedId

    // Reject before even starting the OSS upload if the STS token is already expired.
    const auth = JSON.parse(atob(creds.uploadAuth))
    const expireAt: string | undefined = auth.ExpireUTCTime ?? auth.Expiration
    if (expireAt && isExpired(expireAt)) {
      if (!this._retried) {
        this._retried = true
        return this._run()
      }
      throw new Error('vod: credentials expired on arrival')
    }

    this._setState('uploading')
    this.opts.onProgress?.(0)

    try {
      await this._uploadToOss(creds.uploadAddress, creds.uploadAuth)
    } catch (e: any) {
      // STS token expired mid-upload (OSS returns 403). Retry once from the top.
      if ((e?.status === 403 || e?.statusCode === 403) && !this._retried) {
        this._retried = true
        return this._run()
      }
      throw e
    }

    if (this._aborted) throw new Error('aborted')
    this._setState('verifying')

    await this._pollUntilUploaded()

    if (this._aborted) throw new Error('aborted')
    this._setState('uploaded')

    return { signedId: this._signedId }
  }

  private async _uploadToOss(uploadAddress: string, uploadAuth: string): Promise<void> {
    const { default: OSS } = await import('ali-oss')
    const address = JSON.parse(atob(uploadAddress))
    const auth = JSON.parse(atob(uploadAuth))

    const client = new OSS({
      endpoint: address.Endpoint,
      bucket: address.Bucket,
      accessKeyId: auth.AccessKeyId,
      accessKeySecret: auth.AccessKeySecret,
      stsToken: auth.SecurityToken,
      secure: true,
    })

    await client.multipartUpload(address.FileName, this.file, {
      progress: (p: number) => {
        if (!this._aborted) this.opts.onProgress?.(Math.round(p * 100))
      },
    })
  }

  // Poll /vod/status/:signedId until the backend confirms the file has at least landed
  // (status = "uploaded"). We don't wait for transcoding ("ready") — the mezzanine
  // (original file) is immediately playable via the mediaUrl the server returns.
  private async _pollUntilUploaded(): Promise<void> {
    for (let i = 0; i < POLL_MAX_ATTEMPTS; i++) {
      if (this._aborted) throw new Error('aborted')

      const { data } = await axios.get<{ status: string; ready: boolean }>(
        `/vod/status/${encodeURIComponent(this._signedId)}`,
      )
      if (data.status === 'uploaded' || data.status === 'ready' || data.ready) return

      await sleep(POLL_INTERVAL_MS)
    }
    throw new Error('vod: status poll timed out (~45s)')
  }
}

function isExpired(isoString: string, skewMs = 30_000): boolean {
  const exp = new Date(isoString).getTime()
  if (Number.isNaN(exp)) return false
  return Date.now() >= exp - skewMs
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}
