import { Head, Link } from '@inertiajs/react'
import AppShell from '../../components/AppShell'
import { formatTime } from '../../lib/time'

interface Athlete { id: number; name: string }
interface VideoCard {
  id: number
  title: string
  source: 'upload' | 'youtube'
  status: string
  durationSeconds: number | null
  poster: string | null
  createdAt: string
}

export default function AthleteShow({ athlete, videos }: { athlete: Athlete; videos: VideoCard[] }) {
  return (
    <AppShell>
      <Head title={`${athlete.name} · Pinpoint`} />
      <Link href="/athletes" className="text-sm text-neutral-500 hover:text-neutral-900">← Athletes</Link>
      <h1 className="mt-2 text-2xl font-semibold tracking-tight">{athlete.name}</h1>
      <p className="mt-1 text-sm text-neutral-500">{videos.length} {videos.length === 1 ? 'video' : 'videos'} featuring this athlete</p>

      {videos.length === 0 ? (
        <div className="mt-8 rounded-xl border border-dashed border-neutral-300 p-12 text-center text-neutral-400">
          No videos yet. Assign this athlete from a video page.
        </div>
      ) : (
        <ul className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {videos.map((v) => (
            <li key={v.id} className="overflow-hidden rounded-2xl border border-neutral-200 bg-white transition hover:border-amber-300 hover:shadow-sm">
              <Link href={`/videos/${v.id}`} className="block">
                <div className="relative aspect-video bg-gradient-to-br from-neutral-800 via-neutral-700 to-neutral-900">
                  {v.poster ? (
                    <img src={v.poster} alt="" className="h-full w-full object-cover" loading="lazy" />
                  ) : (
                    <div className="flex h-full items-center justify-center text-xs font-medium uppercase tracking-widest text-neutral-300">
                      {v.source}
                    </div>
                  )}
                  {v.durationSeconds != null && (
                    <span className="absolute bottom-1.5 right-1.5 rounded bg-black/70 px-1.5 py-0.5 font-mono text-[11px] text-white">
                      {formatTime(v.durationSeconds)}
                    </span>
                  )}
                </div>
                <div className="p-3">
                  <span className="line-clamp-2 font-medium leading-snug">{v.title}</span>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </AppShell>
  )
}
