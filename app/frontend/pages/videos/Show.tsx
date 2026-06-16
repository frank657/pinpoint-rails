import { Head, Link, router } from '@inertiajs/react'
import { useRef, useEffect, useState, useCallback } from 'react'
import axios from 'axios'
import { PencilSimple, Check, X } from '@phosphor-icons/react'
import AppShell from '../../components/AppShell'
import VideoPlayer, { type Playback, type PlayerHandle } from '../../components/VideoPlayer'
import NotesPanel, { type Note, type TaxonomyRef } from '../../components/NotesPanel'
import TokenInput from '../../components/TokenInput'
import { formatTime } from '../../lib/time'

interface VideoDetail {
  id: number
  title: string
  source: 'upload' | 'youtube'
  durationSeconds: number | null
  tags: string[]
  athletes: string[]
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
  athletes,
  positions,
  techniques,
}: {
  video: VideoDetail
  playback: Playback
  resumeSeconds: number
  notes: Note[]
  segments: Segment[]
  categories: Category[]
  tags: string[]
  athletes: string[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
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
      <VideoMeta video={video} allTags={tags} allAthletes={athletes} />

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
            positions={positions}
            techniques={techniques}
            onSeek={seek}
            getCurrentTime={getCurrentTime}
          />
        </div>
      </div>
    </AppShell>
  )
}

// Inline editor for a video's free tags and featured athletes. Displays chips read-only until
// you hit "Edit", then swaps to TokenInputs and PATCHes /videos/:id on save.
function VideoMeta({ video, allTags, allAthletes }: { video: VideoDetail; allTags: string[]; allAthletes: string[] }) {
  const [editing, setEditing] = useState(false)
  const [tags, setTags] = useState(video.tags)
  const [people, setPeople] = useState(video.athletes)

  const save = () => {
    router.patch(`/videos/${video.id}`, { tag_names: tags, athlete_names: people }, {
      preserveScroll: true,
      onSuccess: () => setEditing(false),
    })
  }

  const cancel = () => { setTags(video.tags); setPeople(video.athletes); setEditing(false) }

  if (!editing) {
    return (
      <div className="mt-3 flex flex-wrap items-center gap-1.5">
        {video.athletes.map((a) => (
          <span key={a} className="rounded-full bg-teal/10 px-2.5 py-0.5 text-xs font-medium text-teal">{a}</span>
        ))}
        {video.tags.map((t) => (
          <span key={t} className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-700">#{t}</span>
        ))}
        <button onClick={() => setEditing(true)} className="rounded-full border border-dashed border-neutral-300 px-2.5 py-0.5 text-xs text-neutral-500 hover:border-neutral-400 hover:text-neutral-700">
          {video.tags.length || video.athletes.length ? 'Edit tags & athletes' : '+ Tags & athletes'}
        </button>
      </div>
    )
  }

  return (
    <div className="mt-3 space-y-2 rounded-xl border border-neutral-200 bg-white p-3">
      <div>
        <label className="mb-1 block text-[11px] font-semibold uppercase tracking-wide text-neutral-400">Athletes</label>
        <TokenInput value={people} onChange={setPeople} suggestions={allAthletes} placeholder="Add an athlete…" chipClassName="bg-teal/10 text-teal" />
      </div>
      <div>
        <label className="mb-1 block text-[11px] font-semibold uppercase tracking-wide text-neutral-400">Tags</label>
        <TokenInput value={tags} onChange={setTags} suggestions={allTags} placeholder="Add a tag…" />
      </div>
      <div className="flex gap-2">
        <button onClick={save} className="rounded-lg bg-ember px-3 py-1.5 text-sm font-medium text-white hover:bg-amber-500">Save</button>
        <button onClick={cancel} className="rounded-lg px-3 py-1.5 text-sm text-neutral-500 hover:bg-neutral-100">Cancel</button>
      </div>
    </div>
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
