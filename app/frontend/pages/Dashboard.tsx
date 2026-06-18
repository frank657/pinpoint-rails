import { Head, Link, usePage } from '@inertiajs/react'
import AppShell, { type AppSharedProps } from '../components/AppShell'
import { formatTime } from '../lib/time'

interface ContinueItem { id: string; title: string; resumeSeconds: number }
interface NoteRow {
  id: string
  noteType: 'timestamp' | 'rich_text'
  videoId: number | null
  title: string | null
  startSeconds: number | null
  categories: { id: string; name: string }[]
  tags: string[]
}

export default function Dashboard({
  continueWatching,
  recentNotes,
  noteCount,
  videoCount,
}: {
  continueWatching: ContinueItem[]
  recentNotes: NoteRow[]
  noteCount: number
  videoCount: number
}) {
  const { currentWorkspace, currentUser } = usePage<AppSharedProps>().props
  const name = currentUser?.email?.split('@')[0] ?? 'there'

  return (
    <AppShell>
      <Head title="Pinpoint — Home" />

      {/* greeting */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-[34px] font-medium leading-none tracking-tight">Welcome back, {name}.</h1>
          <p className="mt-2.5 text-[15px] text-neutral-500">{currentWorkspace?.name ?? 'Your workspace'} · pick up where you left off.</p>
        </div>
        <div className="flex gap-3 text-sm">
          <Stat n={videoCount} label="videos" />
          <Stat n={noteCount} label="notes" accent />
        </div>
      </div>

      {/* continue watching */}
      <Section title="Jump back in" href="/videos" cta="All videos →" />
      {continueWatching.length > 0 ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {continueWatching.map((v) => (
            <Link key={v.id} href={`/videos/${v.id}`} className="group overflow-hidden rounded-2xl border border-neutral-200 bg-surface transition hover:-translate-y-0.5 hover:shadow-[0_18px_40px_-28px_rgba(120,80,40,0.55)]">
              <div className="relative aspect-video bg-gradient-to-br from-[#7a5f44] to-[#33271c]">
                <span className="absolute bottom-2 right-2 rounded bg-black/60 px-1.5 font-display text-[11px] text-white">{formatTime(v.resumeSeconds)}</span>
              </div>
              <div className="p-3.5">
                <div className="font-medium leading-snug group-hover:text-amber-600">{v.title}</div>
                <div className="mt-1 text-[12.5px] text-neutral-400">Resume at {formatTime(v.resumeSeconds)}</div>
              </div>
            </Link>
          ))}
        </div>
      ) : (
        <EmptyHint text="Nothing in progress yet — open a video and start taking timestamped notes." href="/videos" cta="Browse the library →" />
      )}

      {/* today: recent notes */}
      <Section title="Today" />
      <div className="rounded-2xl border border-neutral-200 bg-surface p-6">
        <div className="mb-1 flex items-center justify-between">
          <p className="font-display text-lg italic">Recent notes</p>
          <Link href="/notes" className="text-[13px] font-medium text-amber-600">All notes →</Link>
        </div>
        {recentNotes.length === 0 ? (
          <p className="py-6 text-sm text-neutral-400">No notes yet.</p>
        ) : (
          <ul>
            {recentNotes.map((n) => (
              <li key={n.id} className="border-b border-neutral-100 py-2.5 last:border-0">
                <Link href={n.videoId ? `/videos/${n.videoId}` : '/notes'} className="flex items-center gap-2.5">
                  {n.noteType === 'timestamp' && n.startSeconds != null ? (
                    <span className="flex-none rounded bg-teal px-1.5 py-0.5 font-display text-[11px] tabular-nums text-white">{formatTime(n.startSeconds)}</span>
                  ) : (
                    <span className="flex-none rounded bg-gold/15 px-1.5 py-0.5 text-[10px] font-semibold uppercase text-gold">note</span>
                  )}
                  <span className="truncate text-sm text-neutral-700">{n.title ?? 'Untitled note'}</span>
                  {n.categories.length > 0 && <span className="ml-auto flex-none text-xs text-neutral-400">{n.categories.map((c) => c.name).join(', ')}</span>}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* quick links */}
      <Section title="Go to" />
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          { label: 'Library', href: '/videos', icon: '▦' },
          { label: 'Notes', href: '/notes', icon: '▤' },
          { label: 'Positions', href: '/positions', icon: '⌥' },
          { label: 'Search', href: '/search', icon: '⌕' },
        ].map((q) => (
          <Link key={q.label} href={q.href} className="flex items-center gap-3 rounded-2xl border border-neutral-200 bg-surface p-4 transition hover:-translate-y-0.5 hover:border-ember">
            <span className="grid h-9 w-9 place-items-center rounded-xl bg-amber-400/12 text-ember">{q.icon}</span>
            <span className="font-medium">{q.label}</span>
          </Link>
        ))}
      </div>
    </AppShell>
  )
}

function Stat({ n, label, accent }: { n: number; label: string; accent?: boolean }) {
  return (
    <div className="rounded-xl border border-neutral-200 bg-surface px-4 py-2 text-center">
      <div className={`font-display text-xl font-semibold leading-none ${accent ? 'text-ember' : ''}`}>{n}</div>
      <div className="mt-1 text-[11.5px] text-neutral-400">{label}</div>
    </div>
  )
}

function Section({ title, href, cta }: { title: string; href?: string; cta?: string }) {
  return (
    <div className="mb-3.5 mt-9 flex items-baseline justify-between">
      <h2 className="font-display text-[22px] font-medium italic">{title}</h2>
      {href && cta && <Link href={href} className="text-[13px] font-semibold text-amber-600">{cta}</Link>}
    </div>
  )
}

function EmptyHint({ text, href, cta }: { text: string; href: string; cta: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-neutral-300 bg-surface px-6 py-12 text-center">
      <p className="text-sm text-neutral-500">{text}</p>
      <Link href={href} className="mt-4 inline-block rounded-lg bg-ember px-4 py-2 text-sm font-medium text-white hover:bg-amber-500">{cta}</Link>
    </div>
  )
}
