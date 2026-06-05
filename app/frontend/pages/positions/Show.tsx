import { Head, Link } from '@inertiajs/react'
import AppShell from '../../components/AppShell'
import { formatTime } from '../../lib/time'

interface Position { id: number; name: string; category: string; dominance: string }
interface NoteRow { id: string; title: string | null; videoId: number | null; startSeconds: number | null }

export default function PositionShow({ position, notes }: { position: Position; notes: NoteRow[] }) {
  return (
    <AppShell>
      <Head title={`${position.name} · Pinpoint`} />
      <Link href="/positions" className="text-sm text-neutral-500 hover:text-neutral-900">← Positions</Link>
      <h1 className="mt-2 text-2xl font-semibold tracking-tight">{position.name}</h1>
      <p className="mt-1 text-sm text-neutral-500">{position.category} · {position.dominance}</p>

      <h2 className="mt-6 text-sm font-medium uppercase tracking-wide text-neutral-400">All material for this position</h2>
      <ul className="mt-3 space-y-2">
        {notes.length === 0 && <li className="rounded-xl border border-dashed border-neutral-300 p-8 text-center text-neutral-400">No notes tagged with this position yet.</li>}
        {notes.map((n) => (
          <li key={n.id} className="rounded-xl border border-neutral-200 bg-white p-3 text-sm">
            {n.videoId && n.startSeconds != null && (
              <Link href={`/videos/${n.videoId}`} className="font-mono text-xs text-amber-600">{formatTime(n.startSeconds)}</Link>
            )}{' '}
            <span className="font-medium">{n.title}</span>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}
