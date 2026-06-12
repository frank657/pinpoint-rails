import { Head, Link, useForm, router } from '@inertiajs/react'
import { useRef, useState, type FormEvent } from 'react'
import axios from 'axios'
import AppShell from '../../components/AppShell'
import { VodUploader, type UploaderState } from '../../lib/vodUploader'

interface VideoSummary {
  id: number
  title: string
  source: 'upload' | 'youtube'
  status: string
  durationSeconds: number | null
}

export default function VideosIndex({ videos }: { videos: VideoSummary[] }) {
  return (
    <AppShell>
      <Head title="Videos · Pinpoint" />
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Videos</h1>
      </div>

      <AddVideo />

      {videos.length === 0 ? (
        <div className="mt-10 rounded-xl border border-dashed border-neutral-300 p-12 text-center text-neutral-400">
          No videos yet — paste a YouTube link or upload a file above.
        </div>
      ) : (
        <ul className="mt-8 grid grid-cols-1 gap-3 sm:grid-cols-2">
          {videos.map((v) => (
            <li key={v.id} className="rounded-xl border border-neutral-200 bg-white p-4">
              <Link href={`/videos/${v.id}`} className="font-medium hover:text-amber-600">
                {v.title}
              </Link>
              <div className="mt-1 text-xs uppercase tracking-wide text-neutral-400">
                {v.source}
                {v.status !== 'ready' && ` · ${v.status}`}
              </div>
            </li>
          ))}
        </ul>
      )}
    </AppShell>
  )
}

function AddVideo() {
  const [tab, setTab] = useState<'youtube' | 'upload'>('youtube')
  return (
    <div className="mt-6 rounded-xl border border-neutral-200 bg-white p-4">
      <div className="mb-4 flex gap-2 text-sm">
        <TabButton active={tab === 'youtube'} onClick={() => setTab('youtube')}>Paste YouTube link</TabButton>
        <TabButton active={tab === 'upload'} onClick={() => setTab('upload')}>Upload a file</TabButton>
      </div>
      {tab === 'youtube' ? <YoutubeForm /> : <UploadForm />}
    </div>
  )
}

function TabButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-lg px-3 py-1.5 ${active ? 'bg-neutral-900 text-white' : 'text-neutral-500 hover:bg-neutral-100'}`}
    >
      {children}
    </button>
  )
}

function YoutubeForm() {
  const form = useForm({ url: '' })
  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.post('/videos/youtube')
  }
  return (
    <form onSubmit={submit} className="flex gap-2">
      <input
        type="url"
        required
        placeholder="https://www.youtube.com/watch?v=…"
        value={form.data.url}
        onChange={(e) => form.setData('url', e.target.value)}
        className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
      />
      <button
        type="submit"
        disabled={form.processing}
        className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300 disabled:opacity-50"
      >
        Add
      </button>
      {form.errors.url && <p className="text-xs text-red-500">{form.errors.url}</p>}
    </form>
  )
}

const STATE_LABEL: Partial<Record<UploaderState, string>> = {
  requesting: 'Preparing…',
  uploading:  'Uploading…',
  verifying:  'Confirming…',
  uploaded:   'Creating video…',
}

function UploadForm() {
  const inputRef = useRef<HTMLInputElement>(null)
  const [uploaderState, setUploaderState] = useState<UploaderState | null>(null)
  const [progress, setProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)

  const onFile = async (file: File) => {
    setError(null)
    setUploaderState('idle')

    const uploader = new VodUploader(file, {
      filename:   file.name,
      title:      file.name,
      onState:    setUploaderState,
      onProgress: setProgress,
    })

    try {
      // Steps 1–3: provision Vod → upload to OSS → poll until uploaded.
      const { signedId } = await uploader.start()

      // Step 4: create the Video record now that the file has landed on Aliyun.
      const { data } = await axios.post<{ videoId: number }>('/videos', {
        signed_id: signedId,
        title:     file.name,
      })
      router.visit(`/videos/${data.videoId}`)
    } catch {
      if (uploader.state !== 'aborted') {
        setError('Upload failed. Check your connection and try again.')
      }
      setUploaderState(null)
    }
  }

  const busy = uploaderState !== null && uploaderState !== 'uploaded'
  const label =
    (uploaderState && STATE_LABEL[uploaderState]
      ? `${STATE_LABEL[uploaderState]}${uploaderState === 'uploading' ? ` ${progress}%` : ''}`
      : 'Choose a video file')

  return (
    <div>
      <input
        ref={inputRef}
        type="file"
        accept="video/*"
        className="hidden"
        onChange={(e) => e.target.files?.[0] && onFile(e.target.files[0])}
      />
      <button
        onClick={() => inputRef.current?.click()}
        disabled={busy}
        className="rounded-lg border border-neutral-300 px-4 py-2 text-sm hover:bg-neutral-50 disabled:opacity-50"
      >
        {label}
      </button>
      {error && <p className="mt-2 text-xs text-red-500">{error}</p>}
    </div>
  )
}
