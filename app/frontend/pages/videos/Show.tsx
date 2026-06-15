import { Head, Link, router } from '@inertiajs/react'
import { useRef, useEffect, useState, useCallback } from 'react'
import axios from 'axios'
import { PencilSimple, Check, X } from '@phosphor-icons/react'
import AppShell from '../../components/AppShell'
import VideoPlayer, { type Playback, type PlayerHandle } from '../../components/VideoPlayer'
import NotesPanel, { type Note } from '../../components/NotesPanel'
import { formatTime } from '../../lib/time'

interface VideoDetail {
  id: number
  title: string
  source: 'upload' | 'youtube'
  durationSeconds: number | null
}

interface Segment {
  id: string
  title: string | null
  startSeconds: number
  endSeconds: number | null
}

interface Category {
  id: number
  name: string
}

export default function VideoShow({
  video,
  playback,
  resumeSeconds,
  notes,
  segments,
  categories,
  tags,
}: {
  video: VideoDetail
  playback: Playback
  resumeSeconds: number
  notes: Note[]
  segments: Segment[]
  categories: Category[]
  tags: string[]
}) {
  const player = useRef<PlayerHandle>(null)
  const seek = (s: number) => player.current?.seek(s)
  const getCurrentTime = () => player.current?.currentTime() ?? 0

  // Resume where the user left off, then persist progress periodically (Axis 3, Phase 7).
  useEffect(() => {
    const save = () => {
      const cur = Math.floor(getCurrentTime())
      if (cur > 0) axios.post('/progress', { trackable_type: 'Video', trackable_id: video.id, resume_seconds: cur })
    }
    const resume = setTimeout(() => { if (resumeSeconds > 1) seek(resumeSeconds) }, 1500)
    const interval = setInterval(save, 10000)
    return () => { clearTimeout(resume); clearInterval(interval); save() }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [video.id])

  return (
    <AppShell>
      <Head title={`${video.title} · Pinpoint`} />
      <Link href="/videos" className="text-sm text-neutral-500 hover:text-neutral-900">← All videos</Link>
      <VideoTitle videoId={video.id} title={video.title} />

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-[1fr_380px]">
        <div>
          <VideoPlayer ref={player} playback={playback} />
          {segments.length > 0 && (
            <div className="mt-4 flex flex-wrap gap-2">
              {segments.map((s) => (
                <button
                  key={s.id}
                  onClick={() => seek(s.startSeconds)}
                  className="rounded-full border border-neutral-200 px-3 py-1 text-xs hover:border-amber-400"
                >
                  <span className="font-mono text-neutral-400">{formatTime(s.startSeconds)}</span>{' '}
                  {s.title ?? 'Segment'}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="lg:h-[70vh]">
          <NotesPanel
            videoId={video.id}
            notes={notes}
            categories={categories}
            tags={tags}
            onSeek={seek}
            getCurrentTime={getCurrentTime}
          />
        </div>
      </div>
    </AppShell>
  )
}

function VideoTitle({ videoId, title }: { videoId: number; title: string }) {
  const [editing, setEditing] = useState(false)
  const [value, setValue] = useState(title)

  const submit = useCallback(() => {
    const trimmed = value.trim()
    if (!trimmed || trimmed === title) { setEditing(false); setValue(title); return }
    router.patch(`/videos/${videoId}`, { title: trimmed }, { onSuccess: () => setEditing(false) })
  }, [videoId, value, title])

  if (editing) {
    return (
      <div className="mt-2 flex items-center gap-2">
        <input
          autoFocus
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') submit(); if (e.key === 'Escape') { setEditing(false); setValue(title) } }}
          className="flex-1 rounded-lg border border-neutral-300 bg-white px-3 py-1.5 text-2xl font-semibold tracking-tight focus:border-ember focus:outline-none"
        />
        <button onClick={submit} className="flex items-center gap-1 rounded-lg bg-ember px-3 py-2 text-sm font-medium text-white hover:bg-amber-500">
          <Check size={14} weight="bold" /> Save
        </button>
        <button onClick={() => { setEditing(false); setValue(title) }} className="rounded-lg p-2 text-neutral-400 hover:bg-neutral-100 hover:text-neutral-700">
          <X size={14} weight="bold" />
        </button>
      </div>
    )
  }

  return (
    <div className="group mt-2 flex items-center gap-2">
      <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
      <button
        onClick={() => setEditing(true)}
        className="rounded-md p-1 text-neutral-300 opacity-0 transition hover:text-neutral-600 group-hover:opacity-100"
        title="Rename"
      >
        <PencilSimple size={16} />
      </button>
    </div>
  )
}
