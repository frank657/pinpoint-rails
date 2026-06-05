import { Head, Link, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface CourseRow { id: number; slug: string; title: string; videoCount: number }

export default function CoursesIndex({ courses }: { courses: CourseRow[] }) {
  const form = useForm({ title: '' })
  const submit = (e: FormEvent) => { e.preventDefault(); form.post('/courses', { onSuccess: () => form.reset() }) }

  return (
    <AppShell>
      <Head title="Courses · Pinpoint" />
      <h1 className="text-2xl font-semibold tracking-tight">Courses</h1>
      <form onSubmit={submit} className="mt-4 flex gap-2">
        <input
          placeholder="New course title"
          value={form.data.title}
          onChange={(e) => form.setData('title', e.target.value)}
          className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
        />
        <button className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">Create</button>
      </form>
      <ul className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
        {courses.map((c) => (
          <li key={c.id} className="rounded-xl border border-neutral-200 bg-white p-4">
            <Link href={`/courses/${c.slug}`} className="font-medium hover:text-amber-600">{c.title}</Link>
            <p className="mt-1 text-xs text-neutral-400">{c.videoCount} video{c.videoCount === 1 ? '' : 's'}</p>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}
