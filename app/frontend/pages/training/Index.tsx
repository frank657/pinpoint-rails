import { Head, router, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Session {
  id: number; date: string; gi: boolean; kind: string; durationMinutes: number | null
  location: string | null; partners: string | null; reflection: string | null; noteCount: number
}
interface Stats { totalSessions: number; totalMinutes: number; streak: number }

const KINDS = ['drill', 'roll', 'positional', 'class_session', 'competition']

export default function TrainingIndex({ sessions, stats }: { sessions: Session[]; stats: Stats }) {
  const form = useForm({
    date: new Date().toISOString().slice(0, 10),
    gi: true, kind: 'roll', duration_minutes: 60, partners: '', reflection: '',
  })
  const submit = (e: FormEvent) => { e.preventDefault(); form.post('/training_sessions', { onSuccess: () => form.reset('partners', 'reflection') }) }

  return (
    <AppShell>
      <Head title="Training log · Pinpoint" />
      <h1 className="text-2xl font-semibold tracking-tight">Training log</h1>

      <div className="mt-4 grid grid-cols-3 gap-4">
        <Stat label="Sessions" value={stats.totalSessions} />
        <Stat label="Mat time" value={`${Math.round(stats.totalMinutes / 60)}h`} />
        <Stat label="Streak" value={`${stats.streak}d`} />
      </div>

      <form onSubmit={submit} className="mt-6 grid grid-cols-2 gap-3 rounded-xl border border-neutral-200 bg-white p-4 sm:grid-cols-3">
        <input type="date" value={form.data.date} onChange={(e) => form.setData('date', e.target.value)} className="rounded-lg border border-neutral-300 px-3 py-2 text-sm" />
        <select value={form.data.kind} onChange={(e) => form.setData('kind', e.target.value)} className="rounded-lg border border-neutral-300 px-3 py-2 text-sm">
          {KINDS.map((k) => <option key={k} value={k}>{k.replace('_', ' ')}</option>)}
        </select>
        <label className="flex items-center gap-2 text-sm text-neutral-600">
          <input type="checkbox" checked={form.data.gi} onChange={(e) => form.setData('gi', e.target.checked)} /> Gi
        </label>
        <input type="number" placeholder="Minutes" value={form.data.duration_minutes} onChange={(e) => form.setData('duration_minutes', Number(e.target.value))} className="rounded-lg border border-neutral-300 px-3 py-2 text-sm" />
        <input placeholder="Partners" value={form.data.partners} onChange={(e) => form.setData('partners', e.target.value)} className="rounded-lg border border-neutral-300 px-3 py-2 text-sm" />
        <input placeholder="Reflection" value={form.data.reflection} onChange={(e) => form.setData('reflection', e.target.value)} className="col-span-2 rounded-lg border border-neutral-300 px-3 py-2 text-sm sm:col-span-3" />
        <button className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">Log session</button>
      </form>

      <ul className="mt-6 space-y-2">
        {sessions.map((s) => (
          <li key={s.id} className="flex items-center justify-between rounded-xl border border-neutral-200 bg-white p-3 text-sm">
            <div>
              <span className="font-mono text-xs text-neutral-400">{s.date}</span>{' '}
              <span className="font-medium">{s.kind.replace('_', ' ')}</span>{' '}
              <span className="text-neutral-400">{s.gi ? 'gi' : 'no-gi'}{s.durationMinutes ? ` · ${s.durationMinutes}m` : ''}</span>
              {s.reflection && <p className="mt-0.5 text-neutral-500">{s.reflection}</p>}
            </div>
            <button onClick={() => router.delete(`/training_sessions/${s.id}`)} className="text-xs text-neutral-300 hover:text-red-500">Delete</button>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-xl border border-neutral-200 bg-white p-4">
      <p className="text-2xl font-semibold">{value}</p>
      <p className="mt-1 text-xs uppercase tracking-wide text-neutral-400">{label}</p>
    </div>
  )
}
