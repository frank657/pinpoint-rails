import { Head, Link, router } from '@inertiajs/react'
import { useMemo, useState } from 'react'
import axios from 'axios'
import {
  Plus, X, PencilSimple, ArrowUp, ArrowDown, Check,
} from '@phosphor-icons/react'
import AppShell from '../../components/AppShell'
import ShareButton from '../../components/ShareButton'
import { formatTime } from '../../lib/time'

interface Chapter { id: string; title: string; position: number }
interface Item {
  id: number; videoId: number; videoTitle: string; chapterId: string | null; position: number
  durationSeconds: number | null; noteCount: number; resumeSeconds: number; completed: boolean
}
interface Notebook {
  id: number; slug: string; title: string; description: string | null
  share: { id: number; token: string } | null
  progress: { completed: number; total: number }
  chapters: Chapter[]; items: Item[]
}

const humanDuration = (s: number) => {
  if (!s) return null
  const h = Math.floor(s / 3600)
  const m = Math.round((s % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

function stateOf(it: Item): { label: string; cls: string } {
  if (it.completed) return { label: '✓ Watched', cls: 'text-teal bg-teal/10' }
  if (it.resumeSeconds > 0) return { label: '● Resume', cls: 'text-white bg-ember' }
  return { label: 'Not started', cls: 'text-neutral-500 border border-neutral-200' }
}

export default function NotebookShow({ notebook, availableVideos }: { notebook: Notebook; availableVideos: { id: number; title: string }[] }) {
  const [editing, setEditing] = useState(false)

  const { items, chapters, progress } = notebook
  const totalSeconds = items.reduce((a, i) => a + (i.durationSeconds ?? 0), 0)
  const totalNotes = items.reduce((a, i) => a + i.noteCount, 0)
  const pct = progress.total ? Math.round((progress.completed / progress.total) * 100) : 0

  const resumeIndex = items.findIndex((i) => !i.completed)
  const resume = resumeIndex >= 0 ? { item: items[resumeIndex], n: resumeIndex + 1 } : null

  const groups = useMemo(() => {
    if (chapters.length === 0) return [{ id: null, title: null, items }]
    const ordered = [...chapters].sort((a, b) => a.position - b.position)
    const g = ordered.map((ch) => ({ id: ch.id, title: ch.title, items: items.filter((i) => i.chapterId === ch.id) }))
    const loose = items.filter((i) => !i.chapterId)
    if (loose.length) g.push({ id: '∅', title: 'Unsorted', items: loose })
    return g.filter((x) => x.items.length > 0)
  }, [chapters, items])

  return (
    <AppShell>
      <Head title={`${notebook.title} · Pinpoint`} />

      <div className="mx-auto max-w-3xl">
        <Link href="/notebooks" className="text-sm text-neutral-500 hover:text-neutral-900">← Notebooks</Link>

        <div className="mt-2 flex flex-wrap items-start justify-between gap-3">
          <div className="min-w-0">
            <h1 className="font-display text-3xl font-medium tracking-tight">{notebook.title}</h1>
            <p className="mt-1.5 text-sm text-neutral-500">
              {items.length} {items.length === 1 ? 'lesson' : 'lessons'}
              {humanDuration(totalSeconds) && <> · {humanDuration(totalSeconds)}</>}
              {totalNotes > 0 && <> · {totalNotes} {totalNotes === 1 ? 'note' : 'notes'}</>}
            </p>
            {notebook.description && <p className="mt-2 max-w-prose text-sm text-neutral-600">{notebook.description}</p>}
          </div>
          <div className="flex flex-none items-center gap-2">
            <ShareButton shareableType="Notebook" shareableId={notebook.id} share={notebook.share} />
            <button
              onClick={() => setEditing((v) => !v)}
              className={`rounded-lg border px-3 py-1.5 text-sm font-medium transition ${editing ? 'border-ember bg-ember text-white' : 'border-neutral-300 text-neutral-700 hover:bg-neutral-50'}`}
            >
              {editing ? 'Done' : 'Edit'}
            </button>
          </div>
        </div>

        {/* Progress card — only in view mode */}
        {!editing && progress.total > 0 && (
          <div className="mt-5 rounded-2xl border border-neutral-200 bg-surface p-4">
            <div className="flex items-center justify-between text-sm">
              <span className="font-medium">{progress.completed} of {progress.total} watched</span>
              <span className="text-neutral-400">{pct}%</span>
            </div>
            <div className="mt-2 h-2.5 w-full overflow-hidden rounded-full bg-neutral-200">
              <div className="h-full rounded-full bg-gradient-to-r from-gold to-ember" style={{ width: `${pct}%` }} />
            </div>
            {resume && (
              <Link
                href={`/videos/${resume.item.videoId}`}
                className="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-ember px-4 py-2.5 text-sm font-semibold text-white shadow-[0_10px_22px_-10px_rgba(226,87,31,0.6)] hover:bg-amber-500"
              >
                ▶ {resume.item.resumeSeconds > 0 ? `Resume Lesson ${resume.n}` : `Start Lesson ${resume.n}`} · {resume.item.videoTitle}
              </Link>
            )}
          </div>
        )}

        {/* ── Edit mode ──────────────────────────────────────────────── */}
        {editing && (
          <EditMode notebook={notebook} availableVideos={availableVideos} />
        )}

        {/* ── View mode ──────────────────────────────────────────────── */}
        {!editing && (
          items.length === 0 ? (
            <div className="mt-6 rounded-2xl border border-dashed border-neutral-300 bg-surface px-6 py-16 text-center">
              <p className="font-display text-xl text-neutral-700">No lessons yet</p>
              <p className="mt-1 text-sm text-neutral-500">Hit <strong>Edit</strong> to add your first video to this notebook.</p>
              <button onClick={() => setEditing(true)} className="mt-5 rounded-lg bg-ember px-4 py-2 text-sm font-medium text-white hover:bg-amber-500">Edit notebook</button>
            </div>
          ) : (
            <div className="mt-6 space-y-7">
              {groups.map((g) => (
                <div key={g.id ?? 'all'}>
                  {g.title && (
                    <div className="mb-2.5 flex items-center gap-3">
                      <h2 className="font-display text-lg italic">{g.title}</h2>
                      <span className="h-px flex-1 bg-neutral-200" />
                      <span className="text-xs text-neutral-400">{g.items.length} {g.items.length === 1 ? 'lesson' : 'lessons'}</span>
                    </div>
                  )}
                  <ul className="space-y-2.5">
                    {g.items.map((it) => {
                      const st = stateOf(it)
                      const n = items.indexOf(it) + 1
                      const watchedPct = it.completed ? 100 : it.durationSeconds ? Math.min(100, (it.resumeSeconds / it.durationSeconds) * 100) : 0
                      return (
                        <li key={it.id}>
                          <Link href={`/videos/${it.videoId}`} className="group flex items-center gap-4 rounded-2xl border border-neutral-200 bg-surface p-3 transition hover:-translate-y-0.5 hover:shadow-[0_14px_30px_-22px_rgba(120,80,40,0.55)]">
                            <div className="relative h-16 w-28 flex-none overflow-hidden rounded-lg bg-gradient-to-br from-[#7a5f44] to-[#33271c]">
                              {it.durationSeconds != null && (
                                <span className="absolute bottom-1 right-1 rounded bg-black/60 px-1 font-display text-[10px] text-white">{formatTime(it.durationSeconds)}</span>
                              )}
                              {watchedPct > 0 && (
                                <span className="absolute inset-x-0 bottom-0 h-1 bg-white/30"><span className="block h-full bg-ember" style={{ width: `${watchedPct}%` }} /></span>
                              )}
                            </div>
                            <span className="font-display w-5 flex-none text-center text-sm text-neutral-400">{n}</span>
                            <div className="min-w-0 flex-1">
                              <div className="truncate font-medium group-hover:text-amber-600">{it.videoTitle}</div>
                              <div className="mt-0.5 text-xs text-neutral-400">
                                {humanDuration(it.durationSeconds ?? 0) ?? '—'}{it.noteCount > 0 && <> · <span className="text-gold">{it.noteCount} {it.noteCount === 1 ? 'note' : 'notes'}</span></>}
                              </div>
                            </div>
                            <span className={`flex-none rounded-full px-2.5 py-1 text-[11px] font-semibold ${st.cls}`}>{st.label}</span>
                          </Link>
                        </li>
                      )
                    })}
                  </ul>
                </div>
              ))}
            </div>
          )
        )}
      </div>
    </AppShell>
  )
}

// ─── Edit mode ────────────────────────────────────────────────────────────────

function EditMode({ notebook, availableVideos }: { notebook: Notebook; availableVideos: { id: number; title: string }[] }) {
  const { slug, chapters, items } = notebook
  const sortedChapters = [...chapters].sort((a, b) => a.position - b.position)
  const unsorted = items.filter((i) => !i.chapterId).sort((a, b) => a.position - b.position)
  const usedVideoIds = new Set(items.map((i) => i.videoId))
  const selectableVideos = availableVideos.filter((v) => !usedVideoIds.has(v.id))

  // New chapter inline creation
  const [addingChapter, setAddingChapter] = useState(false)
  const [newChapterTitle, setNewChapterTitle] = useState('')

  // Per-chapter inline rename
  const [renamingId, setRenamingId] = useState<string | null>(null)
  const [renameValue, setRenameValue] = useState('')

  // Per-section video picker: key = chapter id, or '__none' for unsorted
  const [pendingVideo, setPendingVideo] = useState<Record<string, string>>({})
  const setVideo = (key: string, val: string) => setPendingVideo((p) => ({ ...p, [key]: val }))

  const addChapter = () => {
    if (!newChapterTitle.trim()) return
    router.post(`/notebooks/${slug}/chapters`, { title: newChapterTitle }, {
      onSuccess: () => { setNewChapterTitle(''); setAddingChapter(false) },
    })
  }

  const deleteChapter = (id: string) => router.delete(`/notebooks/${slug}/chapters/${id}`)

  const submitRename = (id: string) => {
    if (!renameValue.trim()) return
    router.patch(`/notebooks/${slug}/chapters/${id}`, { title: renameValue }, {
      onSuccess: () => setRenamingId(null),
    })
  }

  const addVideoToChapter = (chapterId: string | null) => {
    const key = chapterId ?? '__none'
    const videoId = pendingVideo[key]
    if (!videoId) return
    router.post(`/notebooks/${slug}/items`, {
      video_id: videoId,
      notebook_chapter_id: chapterId,
    }, {
      onSuccess: () => setVideo(key, ''),
    })
  }

  const removeItem = (id: number) => router.delete(`/notebooks/${slug}/items/${id}`)

  // Move an item within its section (chapter or unsorted), rebuilding the global id order
  const moveItem = (chapterId: string | null, itemId: number, dir: -1 | 1) => {
    const sectionItems = items
      .filter((i) => (chapterId === null ? !i.chapterId : i.chapterId === chapterId))
      .sort((a, b) => a.position - b.position)
    const idx = sectionItems.findIndex((i) => i.id === itemId)
    const toIdx = idx + dir
    if (toIdx < 0 || toIdx >= sectionItems.length) return

    const swapped = [...sectionItems]
    ;[swapped[idx], swapped[toIdx]] = [swapped[toIdx], swapped[idx]]

    // Rebuild full global order: chapters in position order, then unsorted
    const newIds: number[] = []
    for (const ch of sortedChapters) {
      const chItems = ch.id === chapterId
        ? swapped
        : items.filter((i) => i.chapterId === ch.id).sort((a, b) => a.position - b.position)
      newIds.push(...chItems.map((i) => i.id))
    }
    const unsortedItems = chapterId === null
      ? swapped
      : items.filter((i) => !i.chapterId).sort((a, b) => a.position - b.position)
    newIds.push(...unsortedItems.map((i) => i.id))

    axios.post(`/notebooks/${slug}/items/reorder`, { ids: newIds })
      .then(() => router.reload({ only: ['notebook'] }))
  }

  return (
    <div className="mt-5 space-y-3">

      {/* Chapter sections */}
      {sortedChapters.map((ch) => {
        const chItems = items.filter((i) => i.chapterId === ch.id).sort((a, b) => a.position - b.position)
        const key = ch.id
        const isRenaming = renamingId === ch.id

        return (
          <div key={ch.id} className="overflow-hidden rounded-2xl border border-neutral-200 bg-surface">
            {/* Chapter header */}
            <div className="flex items-center gap-2.5 bg-neutral-100/60 px-4 py-3">
              {isRenaming ? (
                <>
                  <input
                    autoFocus
                    value={renameValue}
                    onChange={(e) => setRenameValue(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') submitRename(ch.id); if (e.key === 'Escape') setRenamingId(null) }}
                    className="flex-1 rounded-lg border border-neutral-300 bg-white px-3 py-1.5 text-sm font-medium focus:border-ember focus:outline-none"
                  />
                  <button onClick={() => submitRename(ch.id)} className="flex items-center gap-1 rounded-lg bg-ember px-2.5 py-1.5 text-xs font-medium text-white hover:bg-amber-500">
                    <Check size={13} weight="bold" /> Save
                  </button>
                  <button onClick={() => setRenamingId(null)} className="rounded-lg px-2.5 py-1.5 text-xs text-neutral-500 hover:bg-neutral-200">
                    Cancel
                  </button>
                </>
              ) : (
                <>
                  <span className="flex-1 text-sm font-semibold text-neutral-700">{ch.title}</span>
                  <span className="text-xs text-neutral-400">{chItems.length} {chItems.length === 1 ? 'video' : 'videos'}</span>
                  <button
                    onClick={() => { setRenamingId(ch.id); setRenameValue(ch.title) }}
                    className="rounded-md p-1 text-neutral-400 hover:bg-neutral-200 hover:text-neutral-700"
                    title="Rename chapter"
                  >
                    <PencilSimple size={14} />
                  </button>
                  <button
                    onClick={() => deleteChapter(ch.id)}
                    className="rounded-md p-1 text-neutral-400 hover:bg-red-50 hover:text-red-500"
                    title="Delete chapter"
                  >
                    <X size={14} weight="bold" />
                  </button>
                </>
              )}
            </div>

            {/* Items in this chapter */}
            {chItems.map((it, i) => (
              <div key={it.id} className="flex items-center gap-3 border-t border-neutral-100 px-4 py-2.5">
                <div className="flex flex-none flex-col gap-0.5">
                  <button onClick={() => moveItem(ch.id, it.id, -1)} disabled={i === 0} className="rounded p-0.5 text-neutral-300 hover:text-neutral-600 disabled:opacity-0">
                    <ArrowUp size={12} weight="bold" />
                  </button>
                  <button onClick={() => moveItem(ch.id, it.id, 1)} disabled={i === chItems.length - 1} className="rounded p-0.5 text-neutral-300 hover:text-neutral-600 disabled:opacity-0">
                    <ArrowDown size={12} weight="bold" />
                  </button>
                </div>
                <span className="font-display w-5 flex-none text-center text-xs text-neutral-400">{i + 1}</span>
                <span className="flex-1 truncate text-sm">{it.videoTitle}</span>
                <button onClick={() => removeItem(it.id)} className="flex-none rounded-md px-2 py-1 text-xs text-neutral-400 hover:bg-red-50 hover:text-red-500">
                  Remove
                </button>
              </div>
            ))}

            {/* Add video to this chapter */}
            <div className="flex items-center gap-2 border-t border-dashed border-neutral-200 bg-neutral-50/50 px-4 py-3">
              <select
                value={pendingVideo[key] ?? ''}
                onChange={(e) => setVideo(key, e.target.value)}
                className="flex-1 rounded-lg border border-neutral-200 bg-white px-3 py-1.5 text-sm text-neutral-700 focus:border-ember focus:outline-none"
              >
                <option value="">Add a video…</option>
                {selectableVideos.map((v) => <option key={v.id} value={v.id}>{v.title}</option>)}
              </select>
              <button
                onClick={() => addVideoToChapter(ch.id)}
                disabled={!pendingVideo[key]}
                className="flex items-center gap-1.5 rounded-lg bg-ember px-3 py-1.5 text-xs font-medium text-white hover:bg-amber-500 disabled:opacity-40"
              >
                <Plus size={12} weight="bold" /> Add
              </button>
            </div>
          </div>
        )
      })}

      {/* Unsorted videos (no chapter assigned) */}
      {unsorted.length > 0 && (
        <div className="overflow-hidden rounded-2xl border border-dashed border-neutral-300 bg-surface">
          <div className="bg-neutral-100/40 px-4 py-3">
            <span className="text-xs font-semibold uppercase tracking-wide text-neutral-400">Not in a chapter</span>
          </div>
          {unsorted.map((it, i) => (
            <div key={it.id} className="flex items-center gap-3 border-t border-neutral-100 px-4 py-2.5">
              <div className="flex flex-none flex-col gap-0.5">
                <button onClick={() => moveItem(null, it.id, -1)} disabled={i === 0} className="rounded p-0.5 text-neutral-300 hover:text-neutral-600 disabled:opacity-0">
                  <ArrowUp size={12} weight="bold" />
                </button>
                <button onClick={() => moveItem(null, it.id, 1)} disabled={i === unsorted.length - 1} className="rounded p-0.5 text-neutral-300 hover:text-neutral-600 disabled:opacity-0">
                  <ArrowDown size={12} weight="bold" />
                </button>
              </div>
              <span className="flex-1 truncate text-sm">{it.videoTitle}</span>
              <button onClick={() => removeItem(it.id)} className="flex-none rounded-md px-2 py-1 text-xs text-neutral-400 hover:bg-red-50 hover:text-red-500">
                Remove
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Add chapter */}
      {addingChapter ? (
        <div className="flex items-center gap-2 rounded-2xl border border-neutral-200 bg-surface px-4 py-3">
          <input
            autoFocus
            value={newChapterTitle}
            onChange={(e) => setNewChapterTitle(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') addChapter(); if (e.key === 'Escape') { setAddingChapter(false); setNewChapterTitle('') } }}
            placeholder="Chapter name…"
            className="flex-1 bg-transparent text-sm font-medium text-neutral-900 outline-none placeholder:text-neutral-400"
          />
          <button onClick={addChapter} className="rounded-lg bg-ember px-3 py-1.5 text-xs font-medium text-white hover:bg-amber-500">
            Add
          </button>
          <button onClick={() => { setAddingChapter(false); setNewChapterTitle('') }} className="rounded-lg px-3 py-1.5 text-xs text-neutral-500 hover:bg-neutral-100">
            Cancel
          </button>
        </div>
      ) : (
        <button
          onClick={() => setAddingChapter(true)}
          className="flex w-full items-center justify-center gap-2 rounded-2xl border border-dashed border-neutral-300 py-3 text-sm text-neutral-400 transition hover:border-neutral-400 hover:text-neutral-600"
        >
          <Plus size={15} weight="bold" /> Add chapter
        </button>
      )}

      {/* Add video without a chapter (only shown when no chapters exist yet) */}
      {chapters.length === 0 && (
        <div className="flex items-center gap-2 rounded-2xl border border-neutral-200 bg-surface px-4 py-3">
          <select
            value={pendingVideo['__none'] ?? ''}
            onChange={(e) => setVideo('__none', e.target.value)}
            className="flex-1 rounded-lg border border-neutral-200 bg-white px-3 py-1.5 text-sm focus:border-ember focus:outline-none"
          >
            <option value="">Add a video…</option>
            {availableVideos.map((v) => <option key={v.id} value={v.id}>{v.title}</option>)}
          </select>
          <button
            onClick={() => addVideoToChapter(null)}
            disabled={!pendingVideo['__none']}
            className="flex items-center gap-1.5 rounded-lg bg-ember px-3 py-1.5 text-xs font-medium text-white hover:bg-amber-500 disabled:opacity-40"
          >
            <Plus size={12} weight="bold" /> Add
          </button>
        </div>
      )}
    </div>
  )
}
