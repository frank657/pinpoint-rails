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
  categories: { id: string; name: string }[]
  tags: string[]
}
interface Category { id: string; name: string }

interface Props {
  notes: NoteRow[]
  categories: Category[]
  tags: string[]
  filters: { categoryId: string | null; tag: string | null; q: string | null }
}

const excerpt = (html: string) => {
  const text = html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  return text.length > 160 ? text.slice(0, 160) + '…' : text
}

export default function NotesIndex({ notes, categories, filters }: Props) {
  const form = useForm({ q: filters.q ?? '' })
  const go = (params: Record<string, string | undefined>) =>
    router.get('/notes', { q: filters.q ?? undefined, category_id: filters.categoryId ?? undefined, ...params }, { preserveState: true, preserveScroll: true })

  const activeCat = filters.categoryId ?? null

  return (
    <AppShell>
      <Head title="Notes · Pinpoint" />

      <div className="flex items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl font-medium tracking-tight">Notes</h1>
          <p className="mt-1 text-[15px] text-neutral-500">Every timestamped insight and rich note across your library.</p>
        </div>
        <Link href="/notes/new" className="rounded-xl bg-ember px-4 py-2.5 text-sm font-semibold text-white shadow-[0_10px_22px_-10px_rgba(226,87,31,0.6)] hover:bg-amber-500">
          + New note
        </Link>
      </div>

      <form onSubmit={(e) => { e.preventDefault(); go({ q: form.data.q || undefined }) }} className="mt-5">
        <input
          value={form.data.q}
          onChange={(e) => form.setData('q', e.target.value)}
          placeholder="Search your notes…"
          className="w-full rounded-xl border border-neutral-200 bg-surface px-4 py-2.5 text-sm focus:border-ember focus:outline-none"
        />
      </form>

      {categories.length > 0 && (
        <div className="mt-3 flex flex-wrap gap-2">
          <button
            onClick={() => go({ category_id: undefined })}
            className={`rounded-full px-3 py-1 text-xs ${activeCat === null ? 'bg-neutral-900 text-white' : 'border border-neutral-200 text-neutral-600 hover:bg-neutral-100'}`}
          >
            All
          </button>
          {categories.map((c) => (
            <button
              key={c.id}
              onClick={() => go({ category_id: String(c.id) })}
              className={`rounded-full px-3 py-1 text-xs ${activeCat === String(c.id) ? 'bg-neutral-900 text-white' : 'border border-neutral-200 text-neutral-600 hover:bg-neutral-100'}`}
            >
              {c.name}
            </button>
          ))}
        </div>
      )}

      {notes.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-dashed border-neutral-300 bg-surface px-6 py-16 text-center">
          <p className="font-display text-xl text-neutral-700">Nothing here yet</p>
          <p className="mt-1 text-sm text-neutral-500">Take a timestamped note on a video, or write a rich note.</p>
          <Link href="/notes/new" className="mt-5 inline-block rounded-lg bg-ember px-4 py-2 text-sm font-medium text-white hover:bg-amber-500">+ New note</Link>
        </div>
      ) : (
        <ul className="mt-5 space-y-3">
          {notes.map((n) => {
            const point = n.noteType === 'timestamp'
            const href = n.videoId ? `/videos/${n.videoId}` : '/notes/new'
            return (
              <li key={n.id}>
                <Link
                  href={href}
                  className="group block rounded-2xl border border-neutral-200 bg-surface p-4 transition hover:-translate-y-0.5 hover:shadow-[0_14px_30px_-22px_rgba(120,80,40,0.55)]"
                >
                  <div className="flex items-center gap-2.5">
                    {point && n.startSeconds != null ? (
                      <span className="rounded-md bg-teal px-2 py-0.5 font-display text-xs tabular-nums text-white">{formatTime(n.startSeconds)}</span>
                    ) : (
                      <span className="rounded-md bg-gold/15 px-2 py-0.5 text-[11px] font-semibold uppercase tracking-wide text-gold">note</span>
                    )}
                    {n.title && <span className="font-medium text-neutral-900">{n.title}</span>}
                    {n.categories.length > 0 && <span className="ml-auto text-xs text-neutral-400">{n.categories.map((c) => c.name).join(', ')}</span>}
                  </div>
                  {n.body && excerpt(n.body) && (
                    <p className="mt-2 line-clamp-2 text-sm text-neutral-600">{excerpt(n.body)}</p>
                  )}
                  {n.tags.length > 0 && (
                    <div className="mt-2.5 flex flex-wrap gap-1.5">
                      {n.tags.map((t) => (
                        <span key={t} className="rounded-full border border-neutral-200 px-2 py-0.5 text-[11.5px] text-neutral-500">#{t}</span>
                      ))}
                    </div>
                  )}
                </Link>
              </li>
            )
          })}
        </ul>
      )}
    </AppShell>
  )
}
