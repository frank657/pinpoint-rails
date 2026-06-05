// Uploads a file directly to Aliyun OSS using the STS credentials minted by the server
// (POST /videos/upload). The credentials are Base64-encoded JSON with Aliyun's CamelCase
// keys. ali-oss is imported dynamically so it is only pulled in when a user actually
// uploads (it's a large, Node-oriented SDK). See docs/roadmap/phases/phase-2.

export interface UploadCredentials {
  uploadAddress: string // base64 JSON: { Endpoint, Bucket, FileName }
  uploadAuth: string // base64 JSON: { AccessKeyId, AccessKeySecret, SecurityToken, ... }
}

export async function uploadToOss(
  file: File,
  creds: UploadCredentials,
  onProgress?: (percent: number) => void,
): Promise<void> {
  const { default: OSS } = await import('ali-oss')

  const address = JSON.parse(atob(creds.uploadAddress))
  const auth = JSON.parse(atob(creds.uploadAuth))

  const client = new OSS({
    endpoint: address.Endpoint,
    bucket: address.Bucket,
    accessKeyId: auth.AccessKeyId,
    accessKeySecret: auth.AccessKeySecret,
    stsToken: auth.SecurityToken,
    secure: true,
  })

  await client.multipartUpload(address.FileName, file, {
    progress: (p: number) => onProgress?.(Math.round(p * 100)),
  })
}
