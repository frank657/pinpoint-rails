import { useState } from 'react'
import { router } from '@inertiajs/react'
import { fmtTime, type Note, type Segment, type RouterPayload } from '../types/video'
import { NoteIcon, PlayIcon } from './timeline/icons'
import { NoteCreateForm, SegCreateForm, NoteInlineEditor, SegInlineEditor, type TaxOptions } from './timeline/forms'

type Editing = { kind: 'note' | 'seg'; id: string } | null

const noteKind = (n: Note): 'point' | 'range' | 'text' =>
  n.noteType === 'rich_text' ? 'text' : n.endSeconds != null ? 'range' : 'point'

// The unified timeline: one panel holding the +Note / +Segment forms, the Organize toggle, and
// the time-ordered body (unanchored notes, segment cards with their notes, loose notes, gaps).
// Mirrors docs/mockups/video-page-full.html, persisting every change via Inertia.
export default function TimelinePanel({
  videoId,
  notes,
  segments,
  opts,
  getCurrentTime,
  onSeek,
}: {
  videoId: string
  notes: Note[]
  segments: Segment[]
  opts: TaxOptions
  getCurrentTime: () => number
  onSeek: (s: number) => void
}) {
  const [editMode, setEditMode] = useState(false)
  const [noteFormAt, setNoteFormAt] = useState<number | null>(null)
  const [segFormAt, setSegFormAt] = useState<number | null>(null)
  const [editing, setEditing] = useState<Editing>(null)
  const [dragId, setDragId] = useState<string | null>(null)
  const [dropKey, setDropKey] = useState<string | null>(null)

  const reload = { preserveScroll: true, preserveState: true as const }
  const addNote = (payload: RouterPayload) =>
    router.post('/notes', { video_id: videoId, ...payload }, { ...reload, onSuccess: () => setNoteFormAt(null) })
  const addSeg = (payload: RouterPayload) =>
    router.post('/segments', { video_id: videoId, ...payload }, { ...reload, onSuccess: () => setSegFormAt(null) })
  const saveNote = (id: string, payload: RouterPayload) =>
    router.patch(`/notes/${id}`, payload, { ...reload, onSuccess: () => setEditing(null) })
  const saveSeg = (id: string, payload: RouterPayload) =>
    router.patch(`/segments/${id}`, { video_id: videoId, ...payload }, { ...reload, onSuccess: () => setEditing(null) })
  const delNote = (id: string) => { if (confirm('Delete this note? This cannot be undone.')) router.delete(`/notes/${id}`, reload) }
  const delSeg = (id: string) => { if (confirm('Delete this segment? Its notes stay, but become loose. This cannot be undone.')) router.delete(`/segments/${id}`, { ...reload, onSuccess: () => setEditing(null) }) }
  const setSegment = (id: string, segmentId: string | null) =>
    router.patch(`/notes/${id}`, { segment_id: segmentId }, reload)

  const onDrop = (segmentId: string | null) => {
    setDropKey(null)
    if (dragId) setSegment(dragId, segmentId)
    setDragId(null)
  }

  // grouping (pure render of server state)
  const unanchored = notes.filter((n) => n.startSeconds == null && n.segmentId == null)
  const loose = notes.filter((n) => n.startSeconds != null && n.segmentId == null)
  const items = [
    ...segments.map((s) => ({ t: 'seg' as const, start: s.startSeconds, seg: s })),
    ...loose.map((n) => ({ t: 'loose' as const, start: n.startSeconds as number, note: n })),
  ].sort((a, b) => a.start - b.start)

  const empty = !segments.length && !notes.length

  const LooseGap = ({ k }: { k: string }) =>
    editMode ? (
      <div
        onDragOver={(e) => { e.preventDefault(); setDropKey(k) }}
        onDragLeave={() => setDropKey((cur) => (cur === k ? null : cur))}
        onDrop={() => onDrop(null)}
        className={`my-0.5 flex items-center justify-center rounded-md border border-dashed text-[9.5px] transition-all ${dropKey === k ? 'h-[26px] border-ember bg-ember/[0.07] text-ember' : 'h-2.5 border-[rgba(44,32,20,.09)] text-transparent'}`}
      >
        drop here → loose
      </div>
    ) : null

  return (
    <div className="flex max-h-[78vh] flex-col overflow-hidden rounded-2xl border border-line bg-surface">
      {/* head */}
      <div className="border-b border-line p-3">
        <button onClick={() => setNoteFormAt(Math.floor(getCurrentTime()))} className="w-full rounded-[9px] bg-ember px-3 py-2 text-[13px] font-semibold text-white hover:bg-[#c8480f]">
          + Note at current time
        </button>
        {noteFormAt != null && (
          <NoteCreateForm opts={opts} currentTime={noteFormAt} onSubmit={addNote} onCancel={() => setNoteFormAt(null)} />
        )}
        <div className="mt-2 flex items-center gap-2">
          <button onClick={() => setSegFormAt(Math.floor(getCurrentTime()))} className="rounded-[9px] border border-line bg-surface px-2.5 py-1.5 text-xs font-semibold text-muted hover:text-ink">+ Segment</button>
          <button
            onClick={() => setEditMode((v) => !v)}
            className={`ml-auto inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-[11.5px] font-bold ${editMode ? 'border-ember bg-ember text-white' : 'border-line bg-surface text-muted'}`}
          >
            <span className="h-[7px] w-[7px] rounded-full bg-current" /> {editMode ? 'Done' : 'Organize'}
          </button>
        </div>
        {segFormAt != null && (
          <SegCreateForm currentTime={segFormAt} onSubmit={addSeg} onCancel={() => setSegFormAt(null)} />
        )}
      </div>

      {/* body */}
      <div className="overflow-y-auto p-2.5">
        {empty ? (
          <div className="px-3 py-6 text-center text-[12.5px] text-faint">No segments or notes yet — add one above to start your timeline.</div>
        ) : (
          <>
            {unanchored.length > 0 && (
              <div className="my-1.5 rounded-[11px] border border-dashed border-line bg-[rgba(44,32,20,.015)]">
                <div className="flex items-center gap-2 px-2.5 py-2">
                  <NoteIcon className="text-faint" />
                  <span className="text-[13px] font-semibold text-muted">Unanchored</span>
                  <span className="ml-auto text-[11px] text-faint">{unanchored.length}</span>
                </div>
                <div>
                  {unanchored.map((n) =>
                    editing?.kind === 'note' && editing.id === n.id ? (
                      <NoteInlineEditor key={n.id} note={n} opts={opts} onSave={(p) => saveNote(n.id, p)} onCancel={() => setEditing(null)} />
                    ) : (
                      <NoteRow key={n.id} note={n} seg={null} editMode={editMode} onSeek={onSeek}
                        onDragStart={() => setDragId(n.id)} onEdit={() => setEditing({ kind: 'note', id: n.id })}
                        onDelete={() => delNote(n.id)} onDetach={() => setSegment(n.id, null)} />
                    ),
                  )}
                </div>
              </div>
            )}

            <LooseGap k="lg-top" />

            {items.map((it, i) => {
              const prevEnd = items.slice(0, i).reduce<number | null>((acc, x) => (x.t === 'seg' && x.seg.endSeconds != null ? x.seg.endSeconds : acc), null)
              if (it.t === 'seg') {
                const gap = prevEnd != null && it.seg.startSeconds > prevEnd
                  ? <div key={`gap-${it.seg.id}`} className="mx-1 my-1.5 flex items-center gap-2 font-mono text-[10px] text-faint before:h-px before:flex-1 before:border-t before:border-dashed before:border-line after:h-px after:flex-1 after:border-t after:border-dashed after:border-line">⋯ gap {fmtTime(prevEnd)} – {fmtTime(it.seg.startSeconds)} ⋯</div>
                  : null
                return (
                  <div key={it.seg.id}>
                    {gap}
                    <SegCard
                      seg={it.seg}
                      notes={notes.filter((n) => n.segmentId === it.seg.id)}
                      editMode={editMode}
                      editing={editing}
                      opts={opts}
                      dropActive={dropKey === `seg-${it.seg.id}`}
                      onSeek={onSeek}
                      onDragOverSeg={() => setDropKey(`seg-${it.seg.id}`)}
                      onDropSeg={() => onDrop(it.seg.id)}
                      setDragId={setDragId}
                      onEditSeg={() => setEditing({ kind: 'seg', id: it.seg.id })}
                      onDelSeg={() => delSeg(it.seg.id)}
                      onSaveSeg={(p) => saveSeg(it.seg.id, p)}
                      onEditNote={(id) => setEditing({ kind: 'note', id })}
                      onDelNote={delNote}
                      onDetachNote={(id) => setSegment(id, null)}
                      onSaveNote={saveNote}
                      onCancelEdit={() => setEditing(null)}
                    />
                    <LooseGap k={`lg-${it.seg.id}`} />
                  </div>
                )
              }
              const n = it.note
              return (
                <div key={n.id}>
                  {editing?.kind === 'note' && editing.id === n.id ? (
                    <NoteInlineEditor note={n} opts={opts} onSave={(p) => saveNote(n.id, p)} onCancel={() => setEditing(null)} />
                  ) : (
                    <LooseRow note={n} editMode={editMode} onSeek={onSeek}
                      onDragStart={() => setDragId(n.id)} onEdit={() => setEditing({ kind: 'note', id: n.id })} onDelete={() => delNote(n.id)} />
                  )}
                  <LooseGap k={`lg-loose-${n.id}`} />
                </div>
              )
            })}
          </>
        )}
      </div>
    </div>
  )
}

// ── Note row (inside a segment or the unanchored section) ────────────────────
function NoteRow({ note, seg, editMode, onSeek, onDragStart, onEdit, onDelete, onDetach }: {
  note: Note
  seg: Segment | null
  editMode: boolean
  onSeek: (s: number) => void
  onDragStart: () => void
  onEdit: () => void
  onDelete: () => void
  onDetach: () => void
}) {
  const kind = noteKind(note)
  const railCls = kind === 'range' ? 'bg-gold' : kind === 'text' ? 'bg-faint' : 'bg-teal'
  const iconCls = kind === 'range' ? 'text-gold' : kind === 'text' ? 'text-faint' : 'text-teal'
  const ts = kind === 'text' ? null : `${fmtTime(note.startSeconds)}${kind === 'range' ? '–' + fmtTime(note.endSeconds) : ''}`

  let moved: string | null = null
  let ext: string | null = null
  if (seg) {
    if (seg.endSeconds == null) moved = '⇄ dragged into open-ended segment'
    else if (note.startSeconds != null && (note.startSeconds < seg.startSeconds || note.startSeconds >= seg.endSeconds))
      moved = `⇄ moved here · ${fmtTime(note.startSeconds)} outside ${fmtTime(seg.startSeconds)}–${fmtTime(seg.endSeconds)}`
    if (kind === 'range' && note.endSeconds != null && seg.endSeconds != null && note.endSeconds > seg.endSeconds)
      ext = `↳ reaches ${fmtTime(note.endSeconds)} (past this segment)`
  }

  return (
    <div
      draggable={editMode}
      onDragStart={onDragStart}
      onClick={() => note.startSeconds != null && onSeek(note.startSeconds)}
      className="relative flex items-start gap-1.5 border-t border-line py-2 pl-3 pr-2.5 first:border-t-0"
    >
      <span className={`absolute bottom-0 left-0 top-0 w-[3px] ${railCls}`} />
      {editMode && <span className="cursor-grab text-[13px] text-faint">⠿</span>}
      <span className={`mt-px flex-none ${iconCls}`}><NoteIcon /></span>
      {ts && <span className="h-fit whitespace-nowrap rounded-md bg-ink px-1.5 py-0.5 font-mono text-[10px] text-white">{ts}</span>}
      <div className="min-w-0 flex-1">
        <div className="text-[12.5px] font-semibold leading-tight">{note.title}</div>
        <NoteBody note={note} />
        <NoteChips note={note} />
        {moved && <div className="mt-1 inline-flex gap-1 rounded-full border border-ember/20 bg-ember/[0.08] px-1.5 py-px text-[9.5px] font-semibold text-ember">{moved}</div>}
        {ext && <div className="mt-1 inline-flex gap-1 text-[10px] font-semibold text-gold">{ext}</div>}
      </div>
      {editMode && (
        <span className="ml-1 flex gap-0.5">
          {seg && <IconBtn title="remove from segment" onClick={(e) => { e.stopPropagation(); onDetach() }}>−</IconBtn>}
          <IconBtn title="edit" onClick={(e) => { e.stopPropagation(); onEdit() }}>✎</IconBtn>
          <IconBtn title="delete" onClick={(e) => { e.stopPropagation(); onDelete() }}>🗑</IconBtn>
        </span>
      )}
    </div>
  )
}

function LooseRow({ note, editMode, onSeek, onDragStart, onEdit, onDelete }: {
  note: Note
  editMode: boolean
  onSeek: (s: number) => void
  onDragStart: () => void
  onEdit: () => void
  onDelete: () => void
}) {
  return (
    <div
      draggable={editMode}
      onDragStart={onDragStart}
      onClick={() => note.startSeconds != null && onSeek(note.startSeconds)}
      className="mx-0.5 my-1 flex items-start gap-1.5 rounded-[9px] border border-dashed border-line bg-[rgba(44,32,20,.018)] px-2.5 py-1.5"
    >
      {editMode && <span className="cursor-grab text-[13px] text-faint">⠿</span>}
      <span className="mt-px flex-none text-faint"><NoteIcon /></span>
      <span className="h-fit whitespace-nowrap rounded-md bg-raise px-1.5 py-0.5 font-mono text-[10px] text-muted">{fmtTime(note.startSeconds)}</span>
      <div className="min-w-0 flex-1">
        <div className="text-[12px] font-semibold leading-tight">{note.title}</div>
        {note.body ? <NoteBody note={note} /> : <div className="text-[10.5px] text-faint">loose — no segment here</div>}
        <NoteChips note={note} />
      </div>
      {editMode && (
        <span className="ml-1 flex gap-0.5">
          <IconBtn title="edit" onClick={(e) => { e.stopPropagation(); onEdit() }}>✎</IconBtn>
          <IconBtn title="delete" onClick={(e) => { e.stopPropagation(); onDelete() }}>🗑</IconBtn>
        </span>
      )}
    </div>
  )
}

function NoteBody({ note }: { note: Note }) {
  if (!note.body) return null
  return <div className="mt-0.5 text-[11px] leading-snug text-muted [&_*]:inline" dangerouslySetInnerHTML={{ __html: note.body }} />
}

function NoteChips({ note }: { note: Note }) {
  const chips = [
    ...note.categories.map((c) => <span key={`c${c.id}`} className="rounded-full bg-raise px-1.5 py-px text-[10px] text-muted">{c.name}</span>),
    ...note.positions.map((p) => <span key={`p${p.id}`} className="rounded-full bg-teal/15 px-1.5 py-px text-[10px] text-[#2c7568]">{p.name}</span>),
    ...note.techniques.map((t) => <span key={`t${t.id}`} className="rounded-full bg-[rgba(58,130,246,.12)] px-1.5 py-px text-[10px] text-[#2563eb]">{t.name}</span>),
    ...note.tags.map((t) => <span key={`g${t}`} className="text-[10px] text-gold">#{t}</span>),
  ]
  if (!chips.length) return null
  return <div className="mt-1 flex flex-wrap items-center gap-1">{chips}</div>
}

function IconBtn({ title, onClick, children }: { title: string; onClick: (e: React.MouseEvent) => void; children: React.ReactNode }) {
  return (
    <button title={title} onClick={onClick} className="inline-flex h-[23px] w-[23px] items-center justify-center rounded-md border border-line bg-surface text-[12px] text-muted hover:border-ember hover:text-ember">
      {children}
    </button>
  )
}

// ── Segment card ─────────────────────────────────────────────────────────────
function SegCard({
  seg, notes, editMode, editing, opts, dropActive, onSeek,
  onDragOverSeg, onDropSeg, setDragId,
  onEditSeg, onDelSeg, onSaveSeg,
  onEditNote, onDelNote, onDetachNote, onSaveNote, onCancelEdit,
}: {
  seg: Segment
  notes: Note[]
  editMode: boolean
  editing: Editing
  opts: TaxOptions
  dropActive: boolean
  onSeek: (s: number) => void
  onDragOverSeg: () => void
  onDropSeg: () => void
  setDragId: (id: string) => void
  onEditSeg: () => void
  onDelSeg: () => void
  onSaveSeg: (p: RouterPayload) => void
  onEditNote: (id: string) => void
  onDelNote: (id: string) => void
  onDetachNote: (id: string) => void
  onSaveNote: (id: string, p: RouterPayload) => void
  onCancelEdit: () => void
}) {
  const open = seg.endSeconds == null
  const mine = [...notes].sort((a, b) => (a.startSeconds ?? 1e9) - (b.startSeconds ?? 1e9))
  const chip = open ? `${fmtTime(seg.startSeconds)} →` : `${fmtTime(seg.startSeconds)}–${fmtTime(seg.endSeconds)}`

  return (
    <div
      onDragOver={editMode ? (e) => { e.preventDefault(); onDragOverSeg() } : undefined}
      onDrop={editMode ? (e) => { e.preventDefault(); onDropSeg() } : undefined}
      className={`group my-2 overflow-hidden rounded-xl border bg-surface ${open ? 'border-dashed border-ember/45' : 'border-ember/30'} ${dropActive ? 'outline outline-2 -outline-offset-[3px] outline-dashed outline-ember' : ''}`}
    >
      <div
        onClick={() => onSeek(seg.startSeconds)}
        title="Play from here"
        className={`flex cursor-pointer items-center gap-1.5 px-2.5 py-2 ${open ? 'bg-ember/[0.05] hover:bg-ember/[0.09]' : 'bg-ember/[0.08] hover:bg-ember/[0.13]'}`}
      >
        <span className="flex-none text-ember"><PlayIcon /></span>
        <span className="whitespace-nowrap rounded border border-ember/30 bg-ember/15 px-1.5 py-0.5 font-mono text-[10px] text-[#b2410f]">{chip}</span>
        <span className="text-[13px] font-semibold">{seg.title}</span>
        <span className={`ml-auto flex gap-0.5 transition-opacity ${editing?.kind === 'seg' && editing.id === seg.id ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}`}>
          <IconBtn title="edit" onClick={(e) => { e.stopPropagation(); onEditSeg() }}>✎</IconBtn>
        </span>
      </div>
      {editing?.kind === 'seg' && editing.id === seg.id && (
        <SegInlineEditor segment={seg} onSave={onSaveSeg} onDelete={onDelSeg} onCancel={onCancelEdit} />
      )}
      {mine.length > 0 && (
        <div>
          {mine.map((n) =>
            editing?.kind === 'note' && editing.id === n.id ? (
              <NoteInlineEditor key={n.id} note={n} opts={opts} onSave={(p) => onSaveNote(n.id, p)} onCancel={onCancelEdit} />
            ) : (
              <NoteRow key={n.id} note={n} seg={seg} editMode={editMode} onSeek={onSeek}
                onDragStart={() => setDragId(n.id)} onEdit={() => onEditNote(n.id)} onDelete={() => onDelNote(n.id)} onDetach={() => onDetachNote(n.id)} />
            ),
          )}
        </div>
      )}
    </div>
  )
}
