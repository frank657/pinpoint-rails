import { Head, Link, router } from '@inertiajs/react'
import { useState } from 'react'
import axios from 'axios'
import AppShell from '../../components/AppShell'

interface Item { id: number; courseId: number; courseTitle: string; courseSlug: string; position: number }
interface Curriculum { id: number; slug: string; title: string; description: string | null; items: Item[] }

export default function CurriculumShow({ curriculum, availableCourses }: { curriculum: Curriculum; availableCourses: { id: number; title: string }[] }) {
  const [courseId, setCourseId] = useState('')

  const addCourse = () => { if (courseId) router.post(`/curriculums/${curriculum.slug}/items`, { course_id: courseId }, { onSuccess: () => setCourseId('') }) }
  const removeItem = (id: number) => router.delete(`/curriculums/${curriculum.slug}/items/${id}`)
  const move = (index: number, dir: -1 | 1) => {
    const ids = curriculum.items.map((i) => i.id)
    const j = index + dir
    if (j < 0 || j >= ids.length) return
    ;[ids[index], ids[j]] = [ids[j], ids[index]]
    axios.post(`/curriculums/${curriculum.slug}/items/reorder`, { ids }).then(() => router.reload({ only: ['curriculum'] }))
  }

  return (
    <AppShell>
      <Head title={`${curriculum.title} · Pinpoint`} />
      <Link href="/curriculums" className="text-sm text-neutral-500 hover:text-neutral-900">← Curriculums</Link>
      <h1 className="mt-2 text-2xl font-semibold tracking-tight">{curriculum.title}</h1>

      <div className="mt-6 flex gap-2">
        <select value={courseId} onChange={(e) => setCourseId(e.target.value)} className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm">
          <option value="">Add a course…</option>
          {availableCourses.map((c) => <option key={c.id} value={c.id}>{c.title}</option>)}
        </select>
        <button onClick={addCourse} className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">Add</button>
      </div>

      <ol className="mt-6 divide-y divide-neutral-100 rounded-xl border border-neutral-200 bg-white">
        {curriculum.items.length === 0 && <li className="p-6 text-center text-sm text-neutral-400">No courses yet.</li>}
        {curriculum.items.map((item, i) => (
          <li key={item.id} className="flex items-center gap-3 p-3">
            <div className="flex flex-col">
              <button onClick={() => move(i, -1)} className="text-xs text-neutral-400 hover:text-neutral-900">▲</button>
              <button onClick={() => move(i, 1)} className="text-xs text-neutral-400 hover:text-neutral-900">▼</button>
            </div>
            <Link href={`/courses/${item.courseSlug}`} className="flex-1 text-sm hover:text-amber-600">{item.courseTitle}</Link>
            <button onClick={() => removeItem(item.id)} className="text-xs text-neutral-300 hover:text-red-500">Remove</button>
          </li>
        ))}
      </ol>
    </AppShell>
  )
}
