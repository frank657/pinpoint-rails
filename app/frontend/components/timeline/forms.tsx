import { useState } from 'react'
import TokenPicker, { type PickItem } from '../TokenPicker'
import { fmtTime, parseTime, type Note, type Segment, type TaxonomyRef, type RouterPayload } from '../../types/video'

export interface TaxOptions {
  categories: TaxonomyRef[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
  tags: string[]
}

export interface NoteDraft {
  cats: PickItem[]
  poss: PickItem[]
  techs: PickItem[]
  tags: PickItem[]
  body: string
}

const refToItem = (r: TaxonomyRef): PickItem => ({ id: r.id, name: r.name })

export function emptyDraft(): NoteDraft {
  return { cats: [], poss: [], techs: [], tags: [], body: '' }
}
export function draftFromNote(n: Note): NoteDraft {
  return {
    cats: n.categories.map(refToItem),
    poss: n.positions.map(refToItem),
    techs: n.techniques.map(refToItem),
    tags: n.tags.map((t) => ({ id: null, name: t })),
    body: n.body ? stripHtml(n.body) : '',
  }
}
export function taxonomyPayload(d: NoteDraft) {
  return {
    category_ids: d.cats.map((c) => c.id),
    position_ids: d.poss.map((p) => p.id),
    technique_ids: d.techs.map((t) => t.id),
    tag_names: d.tags.map((t) => t.name),
    body: d.body,
  }
}

function stripHtml(html: string): string {
  const el = document.createElement('div')
  el.innerHTML = html
  return el.textContent ?? ''
}

const labelCls = 'mt-2 mb-0.5 block text-[11px] font-semibold text-muted'

// Shared taxonomy + body fields (used by both the create form and inline editor).
function TaxFields({ opts, draft, setDraft }: { opts: TaxOptions; draft: NoteDraft; setDraft: (d: NoteDraft) => void }) {
  return (
    <>
      <label className={labelCls}>Categories</label>
      <TokenPicker kind="cat" options={opts.categories.map(refToItem)} value={draft.cats} onChange={(v) => setDraft({ ...draft, cats: v })} />
      <label className={labelCls}>Positions</label>
      <TokenPicker kind="pos" options={opts.positions.map(refToItem)} value={draft.poss} onChange={(v) => setDraft({ ...draft, poss: v })} />
      <label className={labelCls}>Techniques</label>
      <TokenPicker kind="tech" options={opts.techniques.map(refToItem)} value={draft.techs} onChange={(v) => setDraft({ ...draft, techs: v })} />
      <label className={labelCls}>Tags</label>
      <TokenPicker kind="tags" options={opts.tags.map((t) => ({ id: null, name: t }))} value={draft.tags} onChange={(v) => setDraft({ ...draft, tags: v })} />
      <label className={labelCls}>Body</label>
      <textarea rows={2} value={draft.body} onChange={(e) => setDraft({ ...draft, body: e.target.value })} placeholder="Notes…" className="w-full rounded-lg border border-line bg-surface px-2 py-1.5 text-[13px]" />
    </>
  )
}

const textInput = 'w-full rounded-lg border border-line bg-surface px-2 py-1.5 text-[13px]'
const monoInput = 'w-full rounded-lg border border-line bg-surface px-2 py-1.5 text-[13px] font-mono'
const primaryBtn = 'rounded-lg bg-ember px-3 py-1.5 text-[13px] font-semibold text-white hover:bg-[#c8480f]'
const ghostBtn = 'rounded-lg border border-line bg-surface px-2.5 py-1.5 text-xs font-semibold text-muted hover:text-ink'

// ── Create: note ───────────────────────────────────────────────────────────
export function NoteCreateForm({ opts, currentTime, onSubmit, onCancel }: {
  opts: TaxOptions
  currentTime: number
  onSubmit: (payload: RouterPayload) => void
  onCancel: () => void
}) {
  const [title, setTitle] = useState('')
  const [start, setStart] = useState(fmtTime(currentTime))
  const [end, setEnd] = useState<string | null>(null)
  const [untimed, setUntimed] = useState(false)
  const [draft, setDraft] = useState<NoteDraft>(emptyDraft())

  const submit = () => {
    if (untimed) {
      onSubmit({ note_type: 'rich_text', title: title.trim() || 'Untitled note', start_seconds: null, end_seconds: null, ...taxonomyPayload(draft) })
      return
    }
    const s = parseTime(start)
    if (s == null) { alert('Need a start (or mark untimed)'); return }
    const e = end != null ? parseTime(end) : null
    onSubmit({ note_type: 'timestamp', title: title.trim() || 'Untitled note', start_seconds: s, end_seconds: e, ...taxonomyPayload(draft) })
  }

  return (
    <div className="mt-2 rounded-[10px] border border-line bg-ember/[0.04] p-2.5">
      <label className={labelCls}>Title</label>
      <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Arm drag" className={textInput} />
      {!untimed && (
        <>
          <label className={labelCls}>Start</label>
          <input value={start} onChange={(e) => setStart(e.target.value)} className={monoInput} />
          {end != null ? (
            <>
              <label className={labelCls}>End</label>
              <div className="flex items-center gap-1.5">
                <input value={end} onChange={(e) => setEnd(e.target.value)} className={monoInput} />
                <button onClick={() => setEnd(null)} className="whitespace-nowrap rounded-md border border-line bg-raise px-2 py-1.5 text-[11px] text-muted">remove</button>
              </div>
            </>
          ) : (
            <button onClick={() => setEnd(fmtTime(currentTime))} className={`${ghostBtn} mt-2`}>+ end time (make range)</button>
          )}
        </>
      )}
      <label className="mt-2 flex items-center gap-1.5 text-xs font-semibold text-muted">
        <input type="checkbox" checked={untimed} onChange={(e) => setUntimed(e.target.checked)} /> Untimed (no time)
      </label>
      <TaxFields opts={opts} draft={draft} setDraft={setDraft} />
      <div className="mt-2.5 flex items-center gap-2">
        <button onClick={submit} className={primaryBtn}>Add note</button>
        <button onClick={onCancel} className={ghostBtn}>Cancel</button>
      </div>
    </div>
  )
}

// ── Create: segment ──────────────────────────────────────────────────────────
export function SegCreateForm({ currentTime, onSubmit, onCancel }: {
  currentTime: number
  onSubmit: (payload: RouterPayload) => void
  onCancel: () => void
}) {
  const [title, setTitle] = useState('')
  const [start, setStart] = useState(fmtTime(currentTime))
  const [end, setEnd] = useState<string | null>(null)

  const submit = () => {
    const s = parseTime(start)
    if (s == null) { alert('Need a start'); return }
    onSubmit({ title: title.trim() || 'Untitled segment', start_seconds: s, end_seconds: end != null ? parseTime(end) : null })
  }

  return (
    <div className="mt-2 rounded-[10px] border border-line bg-ember/[0.04] p-2.5">
      <label className={labelCls}>Title</label>
      <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Foot sweep entry" className={textInput} />
      <label className={labelCls}>Start</label>
      <input value={start} onChange={(e) => setStart(e.target.value)} className={monoInput} />
      {end != null ? (
        <>
          <label className={labelCls}>End</label>
          <div className="flex items-center gap-1.5">
            <input value={end} onChange={(e) => setEnd(e.target.value)} className={monoInput} />
            <button onClick={() => setEnd(null)} className="whitespace-nowrap rounded-md border border-line bg-raise px-2 py-1.5 text-[11px] text-muted">remove</button>
          </div>
        </>
      ) : (
        <button onClick={() => setEnd(fmtTime(currentTime))} className={`${ghostBtn} mt-2`}>+ end time (playhead)</button>
      )}
      <div className="mt-1 text-[10.5px] text-faint">No end = open-ended (auto-maps nothing).</div>
      <div className="mt-2.5 flex items-center gap-2">
        <button onClick={submit} className={primaryBtn}>Add segment</button>
        <button onClick={onCancel} className={ghostBtn}>Cancel</button>
      </div>
    </div>
  )
}

// ── Inline edit: note ──────────────────────────────────────────────────────────
export function NoteInlineEditor({ note, opts, onSave, onCancel }: {
  note: Note
  opts: TaxOptions
  onSave: (payload: RouterPayload) => void
  onCancel: () => void
}) {
  const isText = note.noteType === 'rich_text'
  const [title, setTitle] = useState(note.title ?? '')
  const [start, setStart] = useState(note.startSeconds == null ? '' : fmtTime(note.startSeconds))
  const [end, setEnd] = useState(note.endSeconds == null ? '' : fmtTime(note.endSeconds))
  const [draft, setDraft] = useState<NoteDraft>(draftFromNote(note))

  const save = () => {
    const payload: RouterPayload = { title: title.trim() || 'Untitled note', ...taxonomyPayload(draft) }
    if (!isText) {
      const s = parseTime(start)
      const e = parseTime(end)
      payload.start_seconds = s
      payload.end_seconds = e
      payload.note_type = 'timestamp'
    }
    onSave(payload)
  }

  return (
    <div className="border-t border-line bg-ember/[0.04] px-2.5 py-2">
      <label className={labelCls}>Title</label>
      <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)} className={textInput} />
      {!isText && (
        <div className="mt-1.5 flex gap-1.5">
          <input value={start} onChange={(e) => setStart(e.target.value)} placeholder="start" className={monoInput} />
          <input value={end} onChange={(e) => setEnd(e.target.value)} placeholder="end (blank = point)" className={monoInput} />
        </div>
      )}
      <TaxFields opts={opts} draft={draft} setDraft={setDraft} />
      <div className="mt-2 flex items-center gap-2">
        <button onClick={save} className={primaryBtn}>Save</button>
        <button onClick={onCancel} className={ghostBtn}>Cancel</button>
      </div>
    </div>
  )
}

// ── Inline edit: segment ─────────────────────────────────────────────────────
export function SegInlineEditor({ segment, onSave, onDelete, onCancel }: {
  segment: Segment
  onSave: (payload: RouterPayload) => void
  onDelete: () => void
  onCancel: () => void
}) {
  const [title, setTitle] = useState(segment.title ?? '')
  const [start, setStart] = useState(fmtTime(segment.startSeconds))
  const [end, setEnd] = useState(segment.endSeconds == null ? '' : fmtTime(segment.endSeconds))

  const save = () => {
    const s = parseTime(start)
    onSave({ title: title.trim() || 'Untitled segment', start_seconds: s ?? segment.startSeconds, end_seconds: parseTime(end) })
  }

  return (
    <div className="border-t border-line bg-ember/[0.04] px-2.5 py-2">
      <label className={labelCls}>Title</label>
      <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)} className={textInput} />
      <div className="mt-1.5 flex gap-1.5">
        <input value={start} onChange={(e) => setStart(e.target.value)} placeholder="start" className={monoInput} />
        <input value={end} onChange={(e) => setEnd(e.target.value)} placeholder="end (blank=open)" className={monoInput} />
      </div>
      <div className="mt-2 flex items-center gap-2">
        <button onClick={save} className={primaryBtn}>Save</button>
        <button onClick={onCancel} className={ghostBtn}>Cancel</button>
        <button onClick={onDelete} className="ml-auto rounded-lg border border-red-300 bg-white px-2.5 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50">Delete</button>
      </div>
    </div>
  )
}
