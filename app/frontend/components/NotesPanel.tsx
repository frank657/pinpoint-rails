import { useForm, router } from '@inertiajs/react'
import { useMemo, useState, type FormEvent } from 'react'
import { formatTime } from '../lib/time'

export interface TaxonomyRef {
  id: number
  name: string
}

export interface Note {
  id: string
  noteType: 'timestamp' | 'rich_text'
  segmentId: string | null
  startSeconds: number | null
  endSeconds: number | null
  title: string | null
  body: string
  categories: TaxonomyRef[]
  tags: string[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
}

interface Category {
  id: number
  name: string
}

export interface Segment {
  id: string
  title: string | null
  startSeconds: number
  endSeconds: number | null
}

export default function NotesPanel({
  videoId,
  notes,
  segments,
  categories,
  tags,
  positions,
  techniques,
  onSeek,
  getCurrentTime,
}: {
  videoId: number
  notes: Note[]
  segments: Segment[]
  categories: Category[]
  tags: string[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
  onSeek: (seconds: number) => void
  getCurrentTime: () => number
}) {
  const [filterTag, setFilterTag] = useState<string | null>(null)
  const [editMode, setEditMode] = useState(false)
  const [dragId, setDragId] = useState<string | null>(null)

  const visible = useMemo(
    () =>
      notes
        .filter((n) => (filterTag ? n.tags.includes(filterTag) : true))
        .sort((a, b) => (a.startSeconds ?? 0) - (b.startSeconds ?? 0)),
    [notes, filterTag],
  )

  // ADR 0011 grouping: notes by stored segmentId; loose = timed with no segment; unanchored = untimed.
  const byId = useMemo(() => {
    const m = new Map<string, Note[]>()
    visible.forEach((n) => { if (n.segmentId) m.set(n.segmentId, [...(m.get(n.segmentId) ?? []), n]) })
    return m
  }, [visible])
  const loose = visible.filter((n) => !n.segmentId && n.startSeconds != null)
  const unanchored = visible.filter((n) => !n.segmentId && n.startSeconds == null)
  const sortedSegments = [...segments].sort((a, b) => a.startSeconds - b.startSeconds)

  // Interleave segment cards with loose notes by time (mockup: segments-notes-vertical-b.html).
  const items: Array<{ t: 'seg'; seg: Segment } | { t: 'loose'; note: Note }> = [
    ...sortedSegments.map((seg) => ({ t: 'seg' as const, seg })),
    ...loose.map((note) => ({ t: 'loose' as const, note })),
  ].sort((a, b) => (a.t === 'seg' ? a.seg.startSeconds : a.note.startSeconds!) - (b.t === 'seg' ? b.seg.startSeconds : b.note.startSeconds!))

  const setSegment = (noteId: string, segmentId: string | null) =>
    router.patch(`/notes/${noteId}`, { segment_id: segmentId ?? '' }, { preserveScroll: true, preserveState: true })

  const renderNote = (note: Note, inSegment?: Segment) => {
    const outside = inSegment && note.startSeconds != null &&
      (inSegment.endSeconds == null || note.startSeconds < inSegment.startSeconds || note.startSeconds >= inSegment.endSeconds)
    return (
      <li
        key={note.id}
        draggable={editMode}
        onDragStart={() => setDragId(note.id)}
        className="group p-3 hover:bg-neutral-50"
      >
        <div className="flex items-start gap-2">
          {editMode && <span className="mt-1 cursor-grab text-neutral-300 select-none">⠿</span>}
          <button
            onClick={() => note.startSeconds != null && onSeek(note.startSeconds)}
            className="mt-0.5 shrink-0 rounded bg-neutral-900 px-1.5 py-0.5 font-mono text-xs text-white hover:bg-amber-500"
          >
            {note.startSeconds == null ? '—' : formatTime(note.startSeconds)}
            {note.endSeconds != null && `–${formatTime(note.endSeconds)}`}
          </button>
          <div className="min-w-0 flex-1">
            {note.title && <p className="text-sm font-medium">{note.title}</p>}
            {note.body && (
              <div className="prose prose-sm mt-0.5 max-w-none text-neutral-600" dangerouslySetInnerHTML={{ __html: note.body }} />
            )}
            {outside && (
              <span className="mt-1 inline-block rounded-full border border-amber-300 bg-amber-50 px-2 py-0.5 text-[10px] font-medium text-amber-700">
                ⇄ moved here · {formatTime(note.startSeconds)} {inSegment!.endSeconds == null ? '(open-ended segment)' : `outside ${formatTime(inSegment!.startSeconds)}–${formatTime(inSegment!.endSeconds)}`}
              </span>
            )}
            <div className="mt-1 flex flex-wrap items-center gap-1.5 text-xs">
              {note.categories.map((c) => (
                <span key={`c-${c.id}`} className="rounded bg-neutral-100 px-1.5 py-0.5 text-neutral-500">{c.name}</span>
              ))}
              {note.tags.map((t) => (
                <button key={t} onClick={() => setFilterTag(t)} className="text-amber-600 hover:underline">#{t}</button>
              ))}
              {note.positions.map((p) => (
                <span key={`p-${p.id}`} className="rounded bg-emerald-50 px-1.5 py-0.5 text-emerald-700">{p.name}</span>
              ))}
              {note.techniques.map((t) => (
                <span key={`t-${t.id}`} className="rounded bg-sky-50 px-1.5 py-0.5 text-sky-700">{t.name}</span>
              ))}
            </div>
            <NoteTaxonomyEditor note={note} categories={categories} positions={positions} techniques={techniques} />
          </div>
          {editMode && inSegment && (
            <button onClick={() => setSegment(note.id, null)} title="Remove from segment" className="shrink-0 rounded border border-neutral-200 px-1.5 text-neutral-400 hover:border-ember hover:text-ember">−</button>
          )}
          <button
            onClick={() => router.delete(`/notes/${note.id}`)}
            className="shrink-0 text-xs text-neutral-300 opacity-0 group-hover:opacity-100 hover:text-red-500"
          >
            Delete
          </button>
        </div>
      </li>
    )
  }

  const looseGap = (key: string) =>
    editMode ? (
      <div
        key={key}
        onDragOver={(e) => e.preventDefault()}
        onDrop={() => dragId && setSegment(dragId, null)}
        className="mx-2 my-1 rounded border border-dashed border-neutral-200 py-1 text-center text-[10px] text-neutral-300 hover:border-ember hover:text-ember"
      >
        drop here → loose
      </div>
    ) : null

  return (
    <aside className="flex h-full flex-col rounded-xl border border-neutral-200 bg-white">
      <div className="border-b border-neutral-100 p-4">
        <NewNoteForm videoId={videoId} categories={categories} tags={tags} positions={positions} techniques={techniques} getCurrentTime={getCurrentTime} />
      </div>

      <div className="flex items-center gap-2 border-b border-neutral-100 p-2 text-xs">
        {filterTag && (
          <button onClick={() => setFilterTag(null)} className="rounded bg-amber-100 px-2 py-1 text-amber-700">#{filterTag} ✕</button>
        )}
        <button
          onClick={() => setEditMode((v) => !v)}
          className={`ml-auto rounded-full px-3 py-1 font-medium ${editMode ? 'bg-ember text-white' : 'border border-neutral-300 text-neutral-500'}`}
        >
          {editMode ? 'Editing' : 'Organize'}
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-2">
        {visible.length === 0 && <p className="p-6 text-center text-sm text-neutral-400">No notes yet.</p>}

        {unanchored.length > 0 && (
          <div className="mb-2 rounded-lg border border-dashed border-neutral-200">
            <p className="px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-neutral-400">Unanchored</p>
            <ul className="divide-y divide-neutral-100">{unanchored.map((n) => renderNote(n))}</ul>
          </div>
        )}

        {looseGap('gap-top')}
        {items.map((it, i) =>
          it.t === 'seg' ? (
            <div
              key={`seg-${it.seg.id}`}
              onDragOver={(e) => editMode && e.preventDefault()}
              onDrop={() => editMode && dragId && setSegment(dragId, it.seg.id)}
              className={`mb-2 overflow-hidden rounded-xl border ${it.seg.endSeconds == null ? 'border-dashed' : ''} border-ember/30`}
            >
              <button onClick={() => onSeek(it.seg.startSeconds)} className="flex w-full items-center gap-2 bg-ember/8 px-3 py-2 text-left">
                <span className="font-mono text-[10px] text-amber-700">
                  {formatTime(it.seg.startSeconds)}{it.seg.endSeconds == null ? ' →' : `–${formatTime(it.seg.endSeconds)}`}
                </span>
                <span className="text-sm font-semibold">{it.seg.title ?? 'Segment'}</span>
                <span className="ml-auto text-[11px] text-neutral-400">{byId.get(it.seg.id)?.length ?? 0}</span>
              </button>
              <ul className="divide-y divide-neutral-100">
                {(byId.get(it.seg.id) ?? []).map((n) => renderNote(n, it.seg))}
                {(byId.get(it.seg.id)?.length ?? 0) === 0 && (
                  <li className="px-3 py-2 text-center text-[11px] italic text-neutral-400">
                    {it.seg.endSeconds == null ? 'Open-ended — drag notes in, or set an end' : 'No notes in this segment'}
                  </li>
                )}
              </ul>
            </div>
          ) : (
            <div key={`loose-${it.note.id}`}>
              <ul className="rounded-lg border border-dashed border-neutral-200">{renderNote(it.note)}</ul>
              {looseGap(`gap-${i}`)}
            </div>
          ),
        )}
        {looseGap('gap-bottom')}
      </div>
    </aside>
  )
}

function NewNoteForm({
  videoId,
  categories,
  tags,
  positions,
  techniques,
  getCurrentTime,
}: {
  videoId: number
  categories: Category[]
  tags: string[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
  getCurrentTime: () => number
}) {
  const [open, setOpen] = useState(false)
  const [useRange, setUseRange] = useState(false)
  const form = useForm({
    note_type: 'timestamp',
    video_id: videoId,
    start_seconds: 0,
    end_seconds: null as number | null,
    title: '',
    body: '',
    category_ids: [] as number[],
    tag_names: '',
    position_ids: [] as number[],
    technique_ids: [] as number[],
  })

  const startCapture = () => {
    form.setData((d) => ({ ...d, start_seconds: Math.floor(getCurrentTime()) }))
    setOpen(true)
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.post('/notes', { onSuccess: () => { form.reset(); setOpen(false); setUseRange(false) } })
  }

  if (!open) {
    return (
      <button
        onClick={startCapture}
        className="w-full rounded-lg bg-amber-400 px-3 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300"
      >
        + Note at current time
      </button>
    )
  }

  return (
    <form onSubmit={submit} className="space-y-2">
      <div className="flex items-center gap-2 text-sm">
        <span className="rounded bg-neutral-900 px-2 py-1 font-mono text-xs text-white">
          {formatTime(form.data.start_seconds)}
        </span>
        <label className="flex items-center gap-1 text-xs text-neutral-500">
          <input type="checkbox" checked={useRange} onChange={(e) => {
            setUseRange(e.target.checked)
            form.setData('end_seconds', e.target.checked ? Math.floor(getCurrentTime()) : null)
          }} />
          range
        </label>
        {useRange && (
          <span className="rounded bg-neutral-700 px-2 py-1 font-mono text-xs text-white">
            →{formatTime(form.data.end_seconds)}
          </span>
        )}
      </div>
      <input
        autoFocus
        placeholder="Title"
        value={form.data.title}
        onChange={(e) => form.setData('title', e.target.value)}
        className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
      />
      <textarea
        placeholder="Notes…"
        value={form.data.body}
        onChange={(e) => form.setData('body', e.target.value)}
        rows={2}
        className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
      />
      <div>
        <input
          placeholder="tags, comma…"
          list="tag-options"
          value={form.data.tag_names}
          onChange={(e) => form.setData('tag_names', e.target.value)}
          className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
        />
        <datalist id="tag-options">
          {tags.map((t) => <option key={t} value={t} />)}
        </datalist>
      </div>
      {(categories.length > 0 || positions.length > 0 || techniques.length > 0) && (
        <div className="space-y-1.5">
          {categories.length > 0 && (
            <TaxonomyPicker
              label="category"
              options={categories}
              selected={form.data.category_ids}
              onChange={(ids) => form.setData('category_ids', ids)}
              chipClassName="bg-neutral-100 text-neutral-600"
            />
          )}
          {positions.length > 0 && (
            <TaxonomyPicker
              label="position"
              options={positions}
              selected={form.data.position_ids}
              onChange={(ids) => form.setData('position_ids', ids)}
              chipClassName="bg-emerald-50 text-emerald-700"
            />
          )}
          {techniques.length > 0 && (
            <TaxonomyPicker
              label="technique"
              options={techniques}
              selected={form.data.technique_ids}
              onChange={(ids) => form.setData('technique_ids', ids)}
              chipClassName="bg-sky-50 text-sky-700"
            />
          )}
        </div>
      )}
      <div className="flex gap-2">
        <button type="submit" disabled={form.processing} className="flex-1 rounded bg-amber-400 px-3 py-1.5 text-sm font-medium text-neutral-950 hover:bg-amber-300 disabled:opacity-50">
          Save note
        </button>
        <button type="button" onClick={() => setOpen(false)} className="rounded px-3 py-1.5 text-sm text-neutral-500 hover:bg-neutral-100">
          Cancel
        </button>
      </div>
    </form>
  )
}

// Curated-taxonomy chip picker: pick from a fixed list (Positions / Techniques) by id. Selected
// items render as removable chips; a dropdown adds the rest (ADR 0004 — Axis 2, not free tags).
function TaxonomyPicker({
  label,
  options,
  selected,
  onChange,
  chipClassName,
}: {
  label: string
  options: TaxonomyRef[]
  selected: number[]
  onChange: (ids: number[]) => void
  chipClassName: string
}) {
  const chosen = options.filter((o) => selected.includes(o.id))
  const available = options.filter((o) => !selected.includes(o.id))
  return (
    <div className="flex flex-wrap items-center gap-1.5">
      {chosen.map((o) => (
        <span key={o.id} className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${chipClassName}`}>
          {o.name}
          <button type="button" onClick={() => onChange(selected.filter((id) => id !== o.id))} className="opacity-60 hover:opacity-100" aria-label={`Remove ${o.name}`}>
            ✕
          </button>
        </span>
      ))}
      {available.length > 0 && (
        <select
          value=""
          onChange={(e) => e.target.value && onChange([...selected, Number(e.target.value)])}
          className="rounded border border-neutral-300 px-2 py-1 text-xs text-neutral-500"
        >
          <option value="">+ {label}</option>
          {available.map((o) => (
            <option key={o.id} value={o.id}>{o.name}</option>
          ))}
        </select>
      )}
    </div>
  )
}

// Inline editor that re-tags an EXISTING note's positions/techniques and PATCHes /notes/:id.
// Hidden behind a toggle so each note row stays compact.
function NoteTaxonomyEditor({ note, categories, positions, techniques }: { note: Note; categories: Category[]; positions: TaxonomyRef[]; techniques: TaxonomyRef[] }) {
  const [open, setOpen] = useState(false)
  const [categoryIds, setCategoryIds] = useState(note.categories.map((c) => c.id))
  const [positionIds, setPositionIds] = useState(note.positions.map((p) => p.id))
  const [techniqueIds, setTechniqueIds] = useState(note.techniques.map((t) => t.id))

  if (categories.length === 0 && positions.length === 0 && techniques.length === 0) return null

  const save = () => {
    router.patch(`/notes/${note.id}`, { category_ids: categoryIds, position_ids: positionIds, technique_ids: techniqueIds }, {
      preserveScroll: true,
      onSuccess: () => setOpen(false),
    })
  }

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="mt-1 text-[11px] text-neutral-300 opacity-0 transition group-hover:opacity-100 hover:text-neutral-600"
      >
        ＋ categories / positions / techniques
      </button>
    )
  }

  return (
    <div className="mt-2 space-y-1.5 rounded-lg border border-neutral-200 bg-neutral-50 p-2">
      {categories.length > 0 && (
        <TaxonomyPicker label="category" options={categories} selected={categoryIds} onChange={setCategoryIds} chipClassName="bg-neutral-100 text-neutral-600" />
      )}
      {positions.length > 0 && (
        <TaxonomyPicker label="position" options={positions} selected={positionIds} onChange={setPositionIds} chipClassName="bg-emerald-50 text-emerald-700" />
      )}
      {techniques.length > 0 && (
        <TaxonomyPicker label="technique" options={techniques} selected={techniqueIds} onChange={setTechniqueIds} chipClassName="bg-sky-50 text-sky-700" />
      )}
      <div className="flex gap-2">
        <button onClick={save} className="rounded bg-neutral-900 px-2 py-1 text-[11px] font-medium text-white hover:bg-amber-500">Save</button>
        <button onClick={() => setOpen(false)} className="rounded px-2 py-1 text-[11px] text-neutral-500 hover:bg-neutral-200">Cancel</button>
      </div>
    </div>
  )
}
