import { Head, Link, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface NotebookRow { id: number; slug: string; title: string; videoCount: number }

export default function NotebooksIndex({ notebooks }: { notebooks: NotebookRow[] }) {
  const form = useForm({ title: '' })
  const submit = (e: FormEvent) => { e.preventDefault(); form.post('/notebooks', { onSuccess: () => form.reset() }) }

  return (
    <AppShell>
      <Head title="Notebooks · Pinpoint" />
      <h1 className="font-display text-3xl font-medium tracking-tight">Notebooks</h1>
      <p className="mt-1.5 text-[15px] text-neutral-500">Each notebook is a set of videos — in chapters — and the notes you take on them.</p>

      <form onSubmit={submit} className="mt-5 flex gap-2">
        <input
          placeholder="New notebook title…"
          value={form.data.title}
          onChange={(e) => form.setData('title', e.target.value)}
          className="flex-1 rounded-xl border border-neutral-200 bg-surface px-4 py-2.5 text-sm focus:border-ember focus:outline-none"
        />
        <button className="rounded-xl bg-ember px-4 py-2.5 text-sm font-semibold text-white hover:bg-amber-500">Create</button>
      </form>

      {notebooks.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-dashed border-neutral-300 bg-surface px-6 py-16 text-center">
          <p className="font-display text-xl text-neutral-700">No notebooks yet</p>
          <p className="mt-1 text-sm text-neutral-500">Create one above, then add videos and take timestamped notes.</p>
        </div>
      ) : (
        <ul className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {notebooks.map((n) => (
            <li key={n.id}>
              <Link href={`/notebooks/${n.slug}`} className="group block rounded-2xl border border-neutral-200 bg-surface p-4 transition hover:-translate-y-0.5 hover:shadow-[0_14px_30px_-22px_rgba(120,80,40,0.55)]">
                <div className="font-display text-lg font-medium group-hover:text-amber-600">{n.title}</div>
                <p className="mt-1 text-xs text-neutral-400">{n.videoCount} video{n.videoCount === 1 ? '' : 's'}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </AppShell>
  )
}
