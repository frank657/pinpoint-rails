import { Head, Link, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Row { id: number; slug: string; title: string; courseCount: number }

export default function CurriculumsIndex({ curriculums }: { curriculums: Row[] }) {
  const form = useForm({ title: '' })
  const submit = (e: FormEvent) => { e.preventDefault(); form.post('/curriculums', { onSuccess: () => form.reset() }) }

  return (
    <AppShell>
      <Head title="Curriculums · Pinpoint" />
      <h1 className="text-2xl font-semibold tracking-tight">Curriculums</h1>
      <p className="mt-1 text-sm text-neutral-500">Group multiple courses into a learning program.</p>
      <form onSubmit={submit} className="mt-4 flex gap-2">
        <input
          placeholder="New curriculum title"
          value={form.data.title}
          onChange={(e) => form.setData('title', e.target.value)}
          className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
        />
        <button className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">Create</button>
      </form>
      <ul className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
        {curriculums.map((c) => (
          <li key={c.id} className="rounded-xl border border-neutral-200 bg-white p-4">
            <Link href={`/curriculums/${c.slug}`} className="font-medium hover:text-amber-600">{c.title}</Link>
            <p className="mt-1 text-xs text-neutral-400">{c.courseCount} course{c.courseCount === 1 ? '' : 's'}</p>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}
