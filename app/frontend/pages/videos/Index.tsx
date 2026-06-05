import { Head, Link, useForm, router } from '@inertiajs/react'
import { useRef, useState, type FormEvent } from 'react'
import axios from 'axios'
import AppShell from '../../components/AppShell'
import { uploadToOss, type UploadCredentials } from '../../lib/uploadToOss'

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

function UploadForm() {
  const inputRef = useRef<HTMLInputElement>(null)
  const [progress, setProgress] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)

  const onFile = async (file: File) => {
    setError(null)
    setProgress(0)
    try {
      const { data } = await axios.post<UploadCredentials & { videoId: number }>('/videos/upload', {
        filename: file.name,
        title: file.name,
      })
      await uploadToOss(file, data, setProgress)
      await pollUntilProcessed(data.videoId)
      router.visit(`/videos/${data.videoId}`)
    } catch (e) {
      setError('Upload failed. Check your connection and try again.')
      setProgress(null)
    }
  }

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
        disabled={progress !== null}
        className="rounded-lg border border-neutral-300 px-4 py-2 text-sm hover:bg-neutral-50 disabled:opacity-50"
      >
        {progress === null ? 'Choose a video file' : `Uploading… ${progress}%`}
      </button>
      {error && <p className="mt-2 text-xs text-red-500">{error}</p>}
    </div>
  )
}

async function pollUntilProcessed(videoId: number) {
  for (let i = 0; i < 150; i++) {
    const { data } = await axios.get<{ status: string; playable: boolean }>(`/videos/${videoId}/status`)
    if (data.playable || data.status !== 'uploading') return
    await new Promise((r) => setTimeout(r, 2000))
  }
}
