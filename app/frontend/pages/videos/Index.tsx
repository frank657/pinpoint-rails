import { Head, Link, useForm, router } from '@inertiajs/react'
import { useRef, useState, type FormEvent } from 'react'
import axios from 'axios'
import { MagnifyingGlass } from '@phosphor-icons/react'
import AppShell from '../../components/AppShell'
import { VodUploader, type UploaderState } from '../../lib/vodUploader'
import { formatTime } from '../../lib/time'

interface VideoCard {
  id: string
  title: string
  source: 'upload' | 'youtube'
  status: string
  durationSeconds: number | null
  poster: string | null
  noteCount: number
  athletes: string[]
  tags: string[]
  createdAt: string
}

interface Filters {
  q: string | null
  tag: string | null
  athlete: string | null
  source: string | null
  addedFrom: string | null
  addedTo: string | null
}

interface Props {
  videos: VideoCard[]
  tags: string[]
  athletes: string[]
  sources: string[]
  filters: Filters
}

export default function VideosIndex({ videos, tags, athletes, sources, filters }: Props) {
  return (
    <AppShell>
      <Head title="Library · Pinpoint" />
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Library</h1>
        <span className="text-sm text-neutral-400">{videos.length} {videos.length === 1 ? 'video' : 'videos'}</span>
      </div>

      <AddVideo />

      <FilterBar tags={tags} athletes={athletes} sources={sources} filters={filters} />

      {videos.length === 0 ? (
        <div className="mt-10 rounded-xl border border-dashed border-neutral-300 p-12 text-center text-neutral-400">
          No videos match — adjust the filters, or add one above.
        </div>
      ) : (
        <ul className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {videos.map((v) => (
            <VideoCardItem key={v.id} video={v} />
          ))}
        </ul>
      )}
    </AppShell>
  )
}

function VideoCardItem({ video }: { video: VideoCard }) {
  const added = new Date(video.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
  return (
    <li className="overflow-hidden rounded-2xl border border-neutral-200 bg-white transition hover:border-amber-300 hover:shadow-sm">
      <Link href={`/videos/${video.id}`} className="group block">
        <div className="relative aspect-video bg-gradient-to-br from-neutral-800 via-neutral-700 to-neutral-900">
          {video.poster ? (
            <img src={video.poster} alt="" className="h-full w-full object-cover" loading="lazy" />
          ) : (
            <div className="flex h-full items-center justify-center text-xs font-medium tracking-wide text-neutral-300">
              {video.status === 'uploading'
                ? 'Uploading…'
                : video.status === 'uploaded'
                  ? 'Processing…'
                  : video.source.toUpperCase()}
            </div>
          )}
          {video.durationSeconds != null && (
            <span className="absolute bottom-1.5 right-1.5 rounded bg-black/70 px-1.5 py-0.5 font-mono text-[11px] text-white">
              {formatTime(video.durationSeconds)}
            </span>
          )}
        </div>
        <div className="p-3">
          <span className="line-clamp-2 font-medium leading-snug group-hover:text-amber-600">
            {video.title}
          </span>
          <div className="mt-1 text-xs text-neutral-400">
            {added}
            {video.noteCount > 0 && ` · ${video.noteCount} ${video.noteCount === 1 ? 'note' : 'notes'}`}
          </div>
          {(video.athletes.length > 0 || video.tags.length > 0) && (
            <div className="mt-2 flex flex-wrap gap-1">
              {video.athletes.map((a) => (
                <span key={a} className="rounded-full bg-teal/10 px-2 py-0.5 text-[11px] font-medium text-teal">{a}</span>
              ))}
              {video.tags.map((t) => (
                <span key={t} className="rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-medium text-amber-700">#{t}</span>
              ))}
            </div>
          )}
        </div>
      </Link>
    </li>
  )
}

function FilterBar({ tags, athletes, sources, filters }: { tags: string[]; athletes: string[]; sources: string[]; filters: Filters }) {
  const [q, setQ] = useState(filters.q ?? '')

  // Round-trip to the server, preserving scroll/state, dropping empty values.
  const apply = (patch: Partial<Filters>) => {
    const next: Record<string, string> = {}
    const merged = { ...filters, ...patch }
    if (merged.q) next.q = merged.q
    if (merged.tag) next.tag = merged.tag
    if (merged.athlete) next.athlete = merged.athlete
    if (merged.source) next.source = merged.source
    if (merged.addedFrom) next.added_from = merged.addedFrom
    if (merged.addedTo) next.added_to = merged.addedTo
    router.get('/videos', next, { preserveState: true, preserveScroll: true, replace: true })
  }

  const search = (e: FormEvent) => { e.preventDefault(); apply({ q }) }
  const active = filters.tag || filters.athlete || filters.source || filters.addedFrom || filters.addedTo || filters.q

  const select = 'rounded-lg border border-neutral-300 bg-white px-2.5 py-1.5 text-sm focus:border-ember focus:outline-none'

  return (
    <div className="mt-6 flex flex-wrap items-center gap-2">
      <form onSubmit={search} className="relative min-w-[180px] flex-1">
        <MagnifyingGlass size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-neutral-400" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search titles…"
          className="w-full rounded-lg border border-neutral-300 bg-white py-1.5 pl-8 pr-3 text-sm focus:border-ember focus:outline-none"
        />
      </form>

      <select value={filters.tag ?? ''} onChange={(e) => apply({ tag: e.target.value || null })} className={select}>
        <option value="">All tags</option>
        {tags.map((t) => <option key={t} value={t}>#{t}</option>)}
      </select>

      <select value={filters.athlete ?? ''} onChange={(e) => apply({ athlete: e.target.value || null })} className={select}>
        <option value="">All athletes</option>
        {athletes.map((a) => <option key={a} value={a}>{a}</option>)}
      </select>

      <select value={filters.source ?? ''} onChange={(e) => apply({ source: e.target.value || null })} className={select}>
        <option value="">Any source</option>
        {sources.map((s) => <option key={s} value={s}>{s}</option>)}
      </select>

      <input
        type="date"
        value={filters.addedFrom ?? ''}
        onChange={(e) => apply({ addedFrom: e.target.value || null })}
        className={select}
        title="Added from"
      />
      <input
        type="date"
        value={filters.addedTo ?? ''}
        onChange={(e) => apply({ addedTo: e.target.value || null })}
        className={select}
        title="Added until"
      />

      {active && (
        <button onClick={() => router.get('/videos', {}, { preserveScroll: true, replace: true })} className="text-sm text-neutral-500 hover:text-neutral-900">
          Clear
        </button>
      )}
    </div>
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
