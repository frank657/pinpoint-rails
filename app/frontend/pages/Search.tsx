import { Head, Link, router, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../components/AppShell'
import { formatTime } from '../lib/time'

interface NoteHit { id: string; title: string | null; videoId: number | null; startSeconds: number | null }
interface VideoHit { id: number; title: string; source: 'upload' | 'youtube'; poster: string | null }
interface Results { notes: NoteHit[]; videos: VideoHit[] }

export default function Search({ q, results }: { q: string; results: Results }) {
  const form = useForm({ q })
  const submit = (e: FormEvent) => { e.preventDefault(); router.get('/search', { q: form.data.q }, { preserveState: true }) }

  return (
    <AppShell>
      <Head title="Search · Pinpoint" />
      <h1 className="text-2xl font-semibold tracking-tight">Search</h1>
      <form onSubmit={submit} className="mt-4">
        <input
          autoFocus
          placeholder="Search notes & videos…"
          value={form.data.q}
          onChange={(e) => form.setData('q', e.target.value)}
          className="w-full rounded-lg border border-neutral-300 px-4 py-2.5 focus:border-amber-400 focus:outline-none"
        />
      </form>

      {q && (
        <div className="mt-6 space-y-8">
          <section>
            <h2 className="text-sm font-medium uppercase tracking-wide text-neutral-400">Videos</h2>
            <ul className="mt-2 space-y-1">
              {results.videos.length === 0 && <li className="text-sm text-neutral-400">No video matches.</li>}
              {results.videos.map((v) => (
                <li key={v.id}>
                  <Link href={`/videos/${v.id}`} className="flex items-center gap-3 rounded px-2 py-1.5 text-sm hover:bg-neutral-100">
                    <span className="grid h-9 w-16 flex-none place-items-center overflow-hidden rounded bg-neutral-800 text-[10px] uppercase text-neutral-400">
                      {v.poster ? <img src={v.poster} alt="" className="h-full w-full object-cover" /> : v.source}
                    </span>
                    {v.title}
                  </Link>
                </li>
              ))}
            </ul>
          </section>

          <section>
            <h2 className="text-sm font-medium uppercase tracking-wide text-neutral-400">Notes</h2>
            <ul className="mt-2 space-y-1">
              {results.notes.length === 0 && <li className="text-sm text-neutral-400">No note matches.</li>}
              {results.notes.map((n) => (
                <li key={n.id}>
                  <Link href={n.videoId ? `/videos/${n.videoId}` : '/notes'} className="block rounded px-2 py-1.5 text-sm hover:bg-neutral-100">
                    {n.startSeconds != null && <span className="font-mono text-xs text-amber-600">{formatTime(n.startSeconds)} </span>}
                    {n.title}
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        </div>
      )}
    </AppShell>
  )
}
