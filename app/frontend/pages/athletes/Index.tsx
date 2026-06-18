import { Head, Link, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Athlete { id: string; name: string; videoCount: number }

export default function AthletesIndex({ athletes }: { athletes: Athlete[] }) {
  const form = useForm({ name: '' })
  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (!form.data.name.trim()) return
    form.post('/athletes', { onSuccess: () => form.reset('name') })
  }

  return (
    <AppShell>
      <Head title="Athletes · Pinpoint" />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Athletes</h1>
          <p className="mt-1 text-sm text-neutral-500">People featured across your videos.</p>
        </div>
        <form onSubmit={submit} className="flex gap-2">
          <input
            placeholder="New athlete"
            value={form.data.name}
            onChange={(e) => form.setData('name', e.target.value)}
            className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm focus:border-ember focus:outline-none"
          />
          <button className="rounded-lg bg-ember px-4 py-1.5 text-sm font-medium text-white hover:bg-amber-500">Add</button>
        </form>
      </div>

      {athletes.length === 0 ? (
        <p className="mt-10 text-center text-sm text-neutral-400">
          No athletes yet. Add one above, or assign athletes from a video page.
        </p>
      ) : (
        <ul className="mt-6 grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {athletes.map((a) => (
            <li key={a.id}>
              <Link
                href={`/athletes/${a.id}`}
                className="flex items-center justify-between rounded-xl border border-neutral-200 bg-white px-4 py-3 hover:border-amber-300"
              >
                <span className="flex items-center gap-3">
                  <span className="grid h-8 w-8 place-items-center rounded-full bg-gradient-to-br from-ember to-gold text-xs font-bold text-white">
                    {a.name[0]?.toUpperCase()}
                  </span>
                  <span className="font-medium">{a.name}</span>
                </span>
                <span className="text-xs text-neutral-400">{a.videoCount} {a.videoCount === 1 ? 'video' : 'videos'}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </AppShell>
  )
}
