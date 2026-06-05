import { useForm, router } from '@inertiajs/react'
import { useMemo, useState, type FormEvent } from 'react'
import { formatTime } from '../lib/time'

export interface Note {
  id: string
  noteType: 'timestamp' | 'rich_text'
  startSeconds: number | null
  endSeconds: number | null
  title: string | null
  body: string
  categoryId: number | null
  category: string | null
  tags: string[]
}

interface Category {
  id: number
  name: string
}

export default function NotesPanel({
  videoId,
  notes,
  categories,
  tags,
  onSeek,
  getCurrentTime,
}: {
  videoId: number
  notes: Note[]
  categories: Category[]
  tags: string[]
  onSeek: (seconds: number) => void
  getCurrentTime: () => number
}) {
  const [filterCategory, setFilterCategory] = useState<number | null>(null)
  const [filterTag, setFilterTag] = useState<string | null>(null)

  const visible = useMemo(
    () =>
      notes
        .filter((n) => (filterCategory ? n.categoryId === filterCategory : true))
        .filter((n) => (filterTag ? n.tags.includes(filterTag) : true))
        .sort((a, b) => (a.startSeconds ?? 0) - (b.startSeconds ?? 0)),
    [notes, filterCategory, filterTag],
  )

  return (
    <aside className="flex h-full flex-col rounded-xl border border-neutral-200 bg-white">
      <div className="border-b border-neutral-100 p-4">
        <NewNoteForm videoId={videoId} categories={categories} tags={tags} getCurrentTime={getCurrentTime} />
      </div>

      {(categories.length > 0 || tags.length > 0) && (
        <div className="flex flex-wrap gap-2 border-b border-neutral-100 p-3 text-xs">
          <select
            value={filterCategory ?? ''}
            onChange={(e) => setFilterCategory(e.target.value ? Number(e.target.value) : null)}
            className="rounded border border-neutral-300 px-2 py-1"
          >
            <option value="">All categories</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
          {filterTag && (
            <button onClick={() => setFilterTag(null)} className="rounded bg-amber-100 px-2 py-1 text-amber-700">
              #{filterTag} ✕
            </button>
          )}
        </div>
      )}

      <ul className="flex-1 divide-y divide-neutral-100 overflow-y-auto">
        {visible.length === 0 && <li className="p-6 text-center text-sm text-neutral-400">No notes yet.</li>}
        {visible.map((note) => (
          <li key={note.id} className="group p-3 hover:bg-neutral-50">
            <div className="flex items-start gap-3">
              <button
                onClick={() => note.startSeconds != null && onSeek(note.startSeconds)}
                className="mt-0.5 shrink-0 rounded bg-neutral-900 px-1.5 py-0.5 font-mono text-xs text-white hover:bg-amber-500"
              >
                {formatTime(note.startSeconds)}
                {note.endSeconds != null && `–${formatTime(note.endSeconds)}`}
              </button>
              <div className="min-w-0 flex-1">
                {note.title && <p className="text-sm font-medium">{note.title}</p>}
                {note.body && (
                  <div
                    className="prose prose-sm mt-0.5 max-w-none text-neutral-600"
                    dangerouslySetInnerHTML={{ __html: note.body }}
                  />
                )}
                <div className="mt-1 flex flex-wrap items-center gap-1.5 text-xs">
                  {note.category && (
                    <span className="rounded bg-neutral-100 px-1.5 py-0.5 text-neutral-500">{note.category}</span>
                  )}
                  {note.tags.map((t) => (
                    <button key={t} onClick={() => setFilterTag(t)} className="text-amber-600 hover:underline">
                      #{t}
                    </button>
                  ))}
                </div>
              </div>
              <button
                onClick={() => router.delete(`/notes/${note.id}`)}
                className="shrink-0 text-xs text-neutral-300 opacity-0 group-hover:opacity-100 hover:text-red-500"
              >
                Delete
              </button>
            </div>
          </li>
        ))}
      </ul>
    </aside>
  )
}

function NewNoteForm({
  videoId,
  categories,
  tags,
  getCurrentTime,
}: {
  videoId: number
  categories: Category[]
  tags: string[]
  getCurrentTime: () => number
}) {
  const [open, setOpen] = useState(false)
  const [useRange, setUseRange] = useState(false)
  const form = useForm({
    note_type: 'timestamp',
    video_id: videoId,
    start_seconds: 0,
    end_seconds: null as number | null,
    title: '',
    body: '',
    category_id: '' as string | number,
    tag_names: '',
  })

  const startCapture = () => {
    form.setData((d) => ({ ...d, start_seconds: Math.floor(getCurrentTime()) }))
    setOpen(true)
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.post('/notes', { onSuccess: () => { form.reset(); setOpen(false); setUseRange(false) } })
  }

  if (!open) {
    return (
      <button
        onClick={startCapture}
        className="w-full rounded-lg bg-amber-400 px-3 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300"
      >
        + Note at current time
      </button>
    )
  }

  return (
    <form onSubmit={submit} className="space-y-2">
      <div className="flex items-center gap-2 text-sm">
        <span className="rounded bg-neutral-900 px-2 py-1 font-mono text-xs text-white">
          {formatTime(form.data.start_seconds)}
        </span>
        <label className="flex items-center gap-1 text-xs text-neutral-500">
          <input type="checkbox" checked={useRange} onChange={(e) => {
            setUseRange(e.target.checked)
            form.setData('end_seconds', e.target.checked ? Math.floor(getCurrentTime()) + 5 : null)
          }} />
          range
        </label>
        {useRange && (
          <span className="rounded bg-neutral-700 px-2 py-1 font-mono text-xs text-white">
            →{formatTime(form.data.end_seconds)}
          </span>
        )}
      </div>
      <input
        autoFocus
        placeholder="Title"
        value={form.data.title}
        onChange={(e) => form.setData('title', e.target.value)}
        className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
      />
      <textarea
        placeholder="Notes…"
        value={form.data.body}
        onChange={(e) => form.setData('body', e.target.value)}
        rows={2}
        className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
      />
      <div className="flex gap-2">
        <select
          value={form.data.category_id}
          onChange={(e) => form.setData('category_id', e.target.value)}
          className="flex-1 rounded border border-neutral-300 px-2 py-1.5 text-sm"
        >
          <option value="">No category</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        <input
          placeholder="tags, comma…"
          list="tag-options"
          value={form.data.tag_names}
          onChange={(e) => form.setData('tag_names', e.target.value)}
          className="flex-1 rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
        />
        <datalist id="tag-options">
          {tags.map((t) => <option key={t} value={t} />)}
        </datalist>
      </div>
      <div className="flex gap-2">
        <button type="submit" disabled={form.processing} className="flex-1 rounded bg-amber-400 px-3 py-1.5 text-sm font-medium text-neutral-950 hover:bg-amber-300 disabled:opacity-50">
          Save note
        </button>
        <button type="button" onClick={() => setOpen(false)} className="rounded px-3 py-1.5 text-sm text-neutral-500 hover:bg-neutral-100">
          Cancel
        </button>
      </div>
    </form>
  )
}
