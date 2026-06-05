import { Head, Link, router, useForm } from '@inertiajs/react'
import AppShell from '../../components/AppShell'
import { formatTime } from '../../lib/time'

interface NoteRow {
  id: string
  noteType: 'timestamp' | 'rich_text'
  videoId: number | null
  title: string | null
  body: string
  startSeconds: number | null
  category: string | null
  tags: string[]
}

interface Category {
  id: number
  name: string
}

export default function NotesIndex({
  notes,
  categories,
  filters,
}: {
  notes: NoteRow[]
  categories: Category[]
  tags: string[]
  filters: { categoryId: string | null; tag: string | null; q: string | null }
}) {
  const form = useForm({ q: filters.q ?? '', category_id: filters.categoryId ?? '' })
  const applyFilters = () => router.get('/notes', { q: form.data.q, category_id: form.data.category_id }, { preserveState: true })

  return (
    <AppShell>
      <Head title="Notes · Pinpoint" />
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Notes</h1>
        <Link href="/notes/new" className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">
          + Rich note
        </Link>
      </div>

      <div className="mt-4 flex gap-2">
        <input
          placeholder="Search notes…"
          value={form.data.q}
          onChange={(e) => form.setData('q', e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
          className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
        />
        <select
          value={form.data.category_id}
          onChange={(e) => { form.setData('category_id', e.target.value); setTimeout(applyFilters, 0) }}
          className="rounded-lg border border-neutral-300 px-3 py-2 text-sm"
        >
          <option value="">All categories</option>
          {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
        <button onClick={applyFilters} className="rounded-lg border border-neutral-300 px-4 py-2 text-sm hover:bg-neutral-50">Search</button>
      </div>

      <ul className="mt-6 space-y-3">
        {notes.length === 0 && <li className="rounded-xl border border-dashed border-neutral-300 p-12 text-center text-neutral-400">No notes found.</li>}
        {notes.map((note) => (
          <li key={note.id} className="rounded-xl border border-neutral-200 bg-white p-4">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                {note.videoId && note.startSeconds != null && (
                  <Link href={`/videos/${note.videoId}`} className="font-mono text-xs text-amber-600">
                    {formatTime(note.startSeconds)}
                  </Link>
                )}
                {note.title && <p className="font-medium">{note.title}</p>}
                {note.body && (
                  <div className="prose prose-sm mt-1 max-w-none text-neutral-600" dangerouslySetInnerHTML={{ __html: note.body }} />
                )}
                <div className="mt-2 flex flex-wrap gap-1.5 text-xs">
                  {note.category && <span className="rounded bg-neutral-100 px-1.5 py-0.5 text-neutral-500">{note.category}</span>}
                  {note.tags.map((t) => <span key={t} className="text-amber-600">#{t}</span>)}
                </div>
              </div>
              <div className="flex shrink-0 flex-col items-end gap-1">
                <button onClick={() => router.post('/review', { note_id: note.id })} className="text-xs text-amber-600 hover:underline">+ Review</button>
                <button onClick={() => router.delete(`/notes/${note.id}`)} className="text-xs text-neutral-300 hover:text-red-500">Delete</button>
              </div>
            </div>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}
