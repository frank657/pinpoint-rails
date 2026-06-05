import { Head, Link, usePage } from '@inertiajs/react'
import AppShell, { type AppSharedProps } from '../components/AppShell'
import { formatTime } from '../lib/time'

interface ContinueItem { id: number; title: string; resumeSeconds: number }

export default function Dashboard({ continueWatching }: { continueWatching: ContinueItem[] }) {
  const { currentWorkspace } = usePage<AppSharedProps>().props

  return (
    <AppShell>
      <Head title="Pinpoint — Dashboard" />
      <h1 className="text-3xl font-semibold tracking-tight">{currentWorkspace?.name ?? 'Your workspace'}</h1>
      <p className="mt-3 text-neutral-500">Pin every moment worth learning.</p>

      {continueWatching.length > 0 && (
        <section className="mt-10">
          <h2 className="text-sm font-medium uppercase tracking-wide text-neutral-400">Continue watching</h2>
          <ul className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
            {continueWatching.map((v) => (
              <li key={v.id} className="rounded-xl border border-neutral-200 bg-white p-4">
                <Link href={`/videos/${v.id}`} className="font-medium hover:text-amber-600">{v.title}</Link>
                <p className="mt-1 text-xs text-neutral-400">Resume at {formatTime(v.resumeSeconds)}</p>
              </li>
            ))}
          </ul>
        </section>
      )}

      <Link
        href="/videos"
        className="mt-10 inline-block rounded-lg bg-amber-400 px-5 py-2.5 font-medium text-neutral-950 hover:bg-amber-300"
      >
        Go to videos →
      </Link>
    </AppShell>
  )
}
