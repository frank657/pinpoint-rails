import { Head, Link, router, useForm } from '@inertiajs/react'
import { useState } from 'react'
import axios from 'axios'
import AppShell from '../../components/AppShell'
import ShareButton from '../../components/ShareButton'

interface Chapter { id: string; title: string; position: number }
interface Item { id: number; videoId: number; videoTitle: string; chapterId: string | null; position: number }
interface Course { id: number; slug: string; title: string; description: string | null; share: { id: number; token: string } | null; progress: { completed: number; total: number }; chapters: Chapter[]; items: Item[] }

export default function CourseShow({ course, availableVideos }: { course: Course; availableVideos: { id: number; title: string }[] }) {
  const [videoId, setVideoId] = useState('')
  const chapterForm = useForm({ title: '' })

  const addVideo = () => { if (videoId) router.post(`/courses/${course.slug}/items`, { video_id: videoId }, { onSuccess: () => setVideoId('') }) }
  const removeItem = (id: number) => router.delete(`/courses/${course.slug}/items/${id}`)
  const setChapter = (id: number, chapterId: string) =>
    router.patch(`/courses/${course.slug}/items/${id}`, { course_chapter_id: chapterId || null })
  const move = (index: number, dir: -1 | 1) => {
    const ids = course.items.map((i) => i.id)
    const j = index + dir
    if (j < 0 || j >= ids.length) return
    ;[ids[index], ids[j]] = [ids[j], ids[index]]
    axios.post(`/courses/${course.slug}/items/reorder`, { ids }).then(() => router.reload({ only: ['course'] }))
  }

  return (
    <AppShell>
      <Head title={`${course.title} · Pinpoint`} />
      <Link href="/courses" className="text-sm text-neutral-500 hover:text-neutral-900">← Courses</Link>
      <div className="mt-2 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold tracking-tight">{course.title}</h1>
        <ShareButton shareableType="Course" shareableId={course.id} share={course.share} />
      </div>
      {course.progress.total > 0 && (
        <div className="mt-3">
          <div className="h-2 w-full overflow-hidden rounded-full bg-neutral-200">
            <div className="h-full bg-amber-400" style={{ width: `${(course.progress.completed / course.progress.total) * 100}%` }} />
          </div>
          <p className="mt-1 text-xs text-neutral-500">{course.progress.completed} / {course.progress.total} completed</p>
        </div>
      )}

      <div className="mt-6 flex gap-2">
        <select value={videoId} onChange={(e) => setVideoId(e.target.value)} className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm">
          <option value="">Add a video…</option>
          {availableVideos.map((v) => <option key={v.id} value={v.id}>{v.title}</option>)}
        </select>
        <button onClick={addVideo} className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">Add</button>
      </div>

      <div className="mt-4 flex items-center gap-2">
        <input
          placeholder="New chapter…"
          value={chapterForm.data.title}
          onChange={(e) => chapterForm.setData('title', e.target.value)}
          className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
        />
        <button onClick={() => chapterForm.post(`/courses/${course.slug}/chapters`, { onSuccess: () => chapterForm.reset() })} className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm hover:bg-neutral-50">+ Chapter</button>
      </div>

      <ul className="mt-6 divide-y divide-neutral-100 rounded-xl border border-neutral-200 bg-white">
        {course.items.length === 0 && <li className="p-6 text-center text-sm text-neutral-400">No videos in this course yet.</li>}
        {course.items.map((item, i) => (
          <li key={item.id} className="flex items-center gap-3 p-3">
            <div className="flex flex-col">
              <button onClick={() => move(i, -1)} className="text-xs text-neutral-400 hover:text-neutral-900">▲</button>
              <button onClick={() => move(i, 1)} className="text-xs text-neutral-400 hover:text-neutral-900">▼</button>
            </div>
            <Link href={`/videos/${item.videoId}`} className="flex-1 text-sm hover:text-amber-600">{item.videoTitle}</Link>
            <select value={item.chapterId ?? ''} onChange={(e) => setChapter(item.id, e.target.value)} className="rounded border border-neutral-200 px-2 py-1 text-xs">
              <option value="">No chapter</option>
              {course.chapters.map((ch) => <option key={ch.id} value={ch.id}>{ch.title}</option>)}
            </select>
            <button onClick={() => removeItem(item.id)} className="text-xs text-neutral-300 hover:text-red-500">Remove</button>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}
