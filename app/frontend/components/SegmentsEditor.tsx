import { router } from '@inertiajs/react'
import { useState } from 'react'
import { PencilSimple, Trash, Plus, MapPin } from '@phosphor-icons/react'
import { formatTime } from '../lib/time'

export interface Segment {
  id: string
  title: string | null
  startSeconds: number
  endSeconds: number | null
}

// Editable in-video chapters: add (capturing the player's current time), rename/retime, delete,
// and seek. Server CRUD lives in App::SegmentsController; every change round-trips and Inertia
// re-renders the list from fresh props.
export default function SegmentsEditor({
  videoId,
  segments,
  onSeek,
  getCurrentTime,
}: {
  videoId: number
  segments: Segment[]
  onSeek: (seconds: number) => void
  getCurrentTime: () => number
}) {
  const [adding, setAdding] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const ordered = [...segments].sort((a, b) => a.startSeconds - b.startSeconds)

  return (
    <div className="mt-4">
      <div className="mb-2 flex items-center justify-between">
        <h3 className="text-xs font-semibold uppercase tracking-wide text-neutral-400">Segments</h3>
        {!adding && (
          <button
            onClick={() => setAdding(true)}
            className="flex items-center gap-1 text-xs font-medium text-amber-600 hover:text-amber-700"
          >
            <Plus size={13} weight="bold" /> Add at current time
          </button>
        )}
      </div>

      {adding && (
        <SegmentForm
          videoId={videoId}
          initialStart={Math.floor(getCurrentTime())}
          getCurrentTime={getCurrentTime}
          onDone={() => setAdding(false)}
        />
      )}

      {ordered.length === 0 && !adding ? (
        <p className="text-xs text-neutral-400">No segments yet — break the video into labelled chapters.</p>
      ) : (
        <ul className="space-y-1">
          {ordered.map((s) =>
            editingId === s.id ? (
              <li key={s.id}>
                <SegmentForm videoId={videoId} segment={s} getCurrentTime={getCurrentTime} onDone={() => setEditingId(null)} />
              </li>
            ) : (
              <li key={s.id} className="group flex items-center gap-2">
                <button
                  onClick={() => onSeek(s.startSeconds)}
                  className="flex min-w-0 flex-1 items-center gap-2 rounded-lg border border-neutral-200 px-2.5 py-1.5 text-left text-sm hover:border-amber-400"
                >
                  <MapPin size={13} className="flex-none text-neutral-400" />
                  <span className="font-mono text-xs text-neutral-400">
                    {formatTime(s.startSeconds)}{s.endSeconds != null && `–${formatTime(s.endSeconds)}`}
                  </span>
                  <span className="truncate">{s.title ?? 'Segment'}</span>
                </button>
                <button
                  onClick={() => setEditingId(s.id)}
                  className="flex-none rounded p-1 text-neutral-300 opacity-0 transition hover:text-neutral-600 group-hover:opacity-100"
                  title="Edit"
                >
                  <PencilSimple size={14} />
                </button>
                <button
                  onClick={() => router.delete(`/segments/${s.id}`, { preserveScroll: true })}
                  className="flex-none rounded p-1 text-neutral-300 opacity-0 transition hover:text-red-500 group-hover:opacity-100"
                  title="Delete"
                >
                  <Trash size={14} />
                </button>
              </li>
            ),
          )}
        </ul>
      )}
    </div>
  )
}

function SegmentForm({
  videoId,
  segment,
  initialStart,
  getCurrentTime,
  onDone,
}: {
  videoId: number
  segment?: Segment
  initialStart?: number
  getCurrentTime: () => number
  onDone: () => void
}) {
  const [title, setTitle] = useState(segment?.title ?? '')
  const [start, setStart] = useState(segment?.startSeconds ?? initialStart ?? 0)
  const [end, setEnd] = useState<number | null>(segment?.endSeconds ?? null)

  const save = () => {
    const payload = { video_id: videoId, title, start_seconds: start, end_seconds: end }
    if (segment) {
      router.patch(`/segments/${segment.id}`, payload, { preserveScroll: true, onSuccess: onDone })
    } else {
      router.post('/segments', payload, { preserveScroll: true, onSuccess: onDone })
    }
  }

  return (
    <div className="space-y-2 rounded-lg border border-neutral-200 bg-neutral-50 p-2">
      <input
        autoFocus
        placeholder="Segment title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        onKeyDown={(e) => e.key === 'Enter' && save()}
        className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
      />
      <div className="flex items-center gap-2 text-xs">
        <button onClick={() => setStart(Math.floor(getCurrentTime()))} className="rounded bg-neutral-900 px-2 py-1 font-mono text-white hover:bg-amber-500">
          start {formatTime(start)}
        </button>
        {end == null ? (
          <button onClick={() => setEnd(Math.floor(getCurrentTime()))} className="rounded border border-neutral-300 px-2 py-1 text-neutral-500 hover:border-amber-400">
            + set end
          </button>
        ) : (
          <>
            <button onClick={() => setEnd(Math.floor(getCurrentTime()))} className="rounded bg-neutral-700 px-2 py-1 font-mono text-white hover:bg-amber-500">
              end {formatTime(end)}
            </button>
            <button onClick={() => setEnd(null)} className="text-neutral-400 hover:text-neutral-600">clear</button>
          </>
        )}
      </div>
      <div className="flex gap-2">
        <button onClick={save} className="rounded bg-amber-400 px-3 py-1 text-xs font-medium text-neutral-950 hover:bg-amber-300">
          {segment ? 'Save' : 'Add segment'}
        </button>
        <button onClick={onDone} className="rounded px-3 py-1 text-xs text-neutral-500 hover:bg-neutral-200">Cancel</button>
      </div>
    </div>
  )
}
