import { useState } from 'react'
import { router } from '@inertiajs/react'
import RichTextEditor from './RichTextEditor'
import AthleteAvatar from './AthleteAvatar'
import TokenPicker, { type PickItem } from './TokenPicker'
import { fmtTime, type VideoDetail, type TaxonomyRef, type Athlete, type RouterPayload } from '../types/video'

type Field = 'description' | 'categories' | 'positions' | 'techniques' | 'athletes' | 'tags'

const refToItem = (r: TaxonomyRef): PickItem => ({ id: r.id, name: r.name })
const athToItem = (a: Athlete): PickItem => ({ id: a.id, name: a.name, avatarUrl: a.avatarUrl, initials: a.initials, hue: a.hue })
const tagToItem = (t: string): PickItem => ({ id: null, name: t })

// Below-video property block. Reads as chips by default (Notion/Linear style); click a row to
// edit just that one field, Done commits via PATCH /videos/:id. One field editable at a time.
export default function VideoDetails({
  video,
  allCategories,
  allPositions,
  allTechniques,
  allTags,
  allAthletes,
  noteCount,
  segmentCount,
}: {
  video: VideoDetail
  allCategories: TaxonomyRef[]
  allPositions: TaxonomyRef[]
  allTechniques: TaxonomyRef[]
  allTags: string[]
  allAthletes: Athlete[]
  noteCount: number
  segmentCount: number
}) {
  const [field, setField] = useState<Field | null>(null)
  const [desc, setDesc] = useState(video.description ?? '')
  const [cats, setCats] = useState<PickItem[]>(video.categories.map(refToItem))
  const [poss, setPoss] = useState<PickItem[]>(video.positions.map(refToItem))
  const [techs, setTechs] = useState<PickItem[]>(video.techniques.map(refToItem))
  const [aths, setAths] = useState<PickItem[]>(video.athletes.map(athToItem))
  const [tags, setTags] = useState<PickItem[]>(video.tags.map(tagToItem))

  const patch = (payload: RouterPayload) =>
    router.patch(`/videos/${video.id}`, payload, { preserveScroll: true, preserveState: true })

  const commit = (f: Field) => {
    if (f === 'description') patch({ description: desc })
    else if (f === 'categories') patch({ category_ids: cats.map((c) => c.id) })
    else if (f === 'positions') patch({ position_ids: poss.map((p) => p.id) })
    else if (f === 'techniques') patch({ technique_ids: techs.map((t) => t.id) })
    else if (f === 'athletes') patch({ athlete_names: aths.map((a) => a.name) })
    else if (f === 'tags') patch({ tag_names: tags.map((t) => t.name) })
  }

  // Open a field for editing, committing whichever one was already open (mockup behaviour).
  const open = (f: Field) => {
    if (field && field !== f) commit(field)
    setField(f)
  }
  const done = () => {
    if (field) commit(field)
    setField(null)
  }

  const dateAdded = new Date(video.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })

  return (
    <div className="mt-3.5">
      {/* meta bar */}
      <div className="mb-3 flex flex-wrap items-center gap-2 text-[11.5px] text-muted">
        <span className="inline-flex items-center gap-1 rounded-md bg-ink px-2 py-0.5 text-[10.5px] font-semibold text-white">
          {video.source === 'youtube' ? '▶ YouTube' : '⬆ Upload'}
        </span>
        {video.durationSeconds ? <span>{fmtTime(video.durationSeconds)}</span> : null}
        <span className="h-[3px] w-[3px] rounded-full bg-faint" />
        <span>Added {dateAdded}</span>
        <span className="h-[3px] w-[3px] rounded-full bg-faint" />
        <span>{noteCount} {noteCount === 1 ? 'note' : 'notes'} · {segmentCount} {segmentCount === 1 ? 'segment' : 'segments'}</span>
      </div>

      <TaxRow
        label="Categories" field="categories" kind="cat" open={open} done={done} editing={field === 'categories'}
        options={allCategories.map(refToItem)} value={cats} onChange={setCats}
        chips={video.categories.map((c) => <span key={c.id} className="rounded-full bg-raise px-2.5 py-0.5 text-[11.5px] text-ink">{c.name}</span>)}
      />
      <TaxRow
        label="Positions" field="positions" kind="pos" open={open} done={done} editing={field === 'positions'}
        options={allPositions.map(refToItem)} value={poss} onChange={setPoss}
        chips={video.positions.map((p) => <span key={p.id} className="rounded-full bg-teal/15 px-2.5 py-0.5 text-[11.5px] text-[#2c7568]">{p.name}</span>)}
      />
      <TaxRow
        label="Techniques" field="techniques" kind="tech" open={open} done={done} editing={field === 'techniques'}
        options={allTechniques.map(refToItem)} value={techs} onChange={setTechs}
        chips={video.techniques.map((t) => <span key={t.id} className="rounded-full bg-[rgba(58,130,246,.12)] px-2.5 py-0.5 text-[11.5px] text-[#2563eb]">{t.name}</span>)}
      />
      <TaxRow
        label="Athletes" field="athletes" kind="ath" open={open} done={done} editing={field === 'athletes'}
        options={allAthletes.map(athToItem)} value={aths} onChange={setAths}
        chips={video.athletes.map((a) => (
          <span key={a.id} className="inline-flex items-center gap-1.5 rounded-full border border-line bg-surface py-0.5 pl-0.5 pr-2.5 text-[11.5px] text-ink">
            <AthleteAvatar athlete={a} size={20} />{a.name}
          </span>
        ))}
      />
      <TaxRow
        label="Tags" field="tags" kind="tags" open={open} done={done} editing={field === 'tags'}
        options={allTags.map(tagToItem)} value={tags} onChange={setTags}
        chips={video.tags.map((t) => <span key={t} className="text-[11.5px] text-gold">#{t}</span>)}
      />

      {/* description — at the bottom, below tags */}
      {field === 'description' ? (
        <Row label="Description" editing>
          <div>
            <RichTextEditor value={desc} onChange={setDesc} placeholder="Add a description for this video…" />
            <div className="mt-1.5"><DoneButton onClick={done} /></div>
          </div>
        </Row>
      ) : (
        <ReadRow label="Description" onClick={() => open('description')}>
          {video.description ? (
            <div className="prose prose-sm max-w-none pt-0.5 text-[13px] leading-relaxed text-ink [&_p]:my-0" dangerouslySetInnerHTML={{ __html: video.description }} />
          ) : (
            <AddHint>+ Add description</AddHint>
          )}
        </ReadRow>
      )}
    </div>
  )
}

function Row({ label, editing, children }: { label: string; editing?: boolean; children: React.ReactNode }) {
  return (
    <div className={`grid grid-cols-[96px_1fr] items-start gap-2.5 rounded-lg px-2 py-1.5 ${editing ? 'bg-ember/5' : ''}`}>
      <div className="pt-1 text-[10.5px] font-bold uppercase tracking-[0.08em] text-faint">{label}</div>
      {children}
    </div>
  )
}

function ReadRow({ label, onClick, children }: { label: string; onClick: () => void; children: React.ReactNode }) {
  return (
    <div onClick={onClick} className="grid min-h-[34px] cursor-pointer grid-cols-[96px_1fr] items-start gap-2.5 rounded-lg px-2 py-1.5 hover:bg-raise">
      <div className="pt-1 text-[10.5px] font-bold uppercase tracking-[0.08em] text-faint">{label}</div>
      <div className="flex flex-wrap items-center gap-1.5 pt-0.5">{children}</div>
    </div>
  )
}

function AddHint({ children }: { children: React.ReactNode }) {
  return <span className="text-[11.5px] text-faint group-hover:text-ember">{children}</span>
}

function DoneButton({ onClick }: { onClick: () => void }) {
  return <button onClick={onClick} className="rounded-lg bg-ember px-2.5 py-1.5 text-xs font-semibold text-white hover:bg-[#c8480f]">Done</button>
}

function TaxRow({
  label, field, kind, editing, open, done, options, value, onChange, chips,
}: {
  label: string
  field: Field
  kind: 'cat' | 'pos' | 'tech' | 'tags' | 'ath'
  editing: boolean
  open: (f: Field) => void
  done: () => void
  options: PickItem[]
  value: PickItem[]
  onChange: (next: PickItem[]) => void
  chips: React.ReactNode[]
}) {
  if (editing) {
    return (
      <Row label={label} editing>
        <div className="flex items-start gap-2">
          <div className="flex-1"><TokenPicker kind={kind} options={options} value={value} onChange={onChange} /></div>
          <DoneButton onClick={done} />
        </div>
      </Row>
    )
  }
  return (
    <div onClick={() => open(field)} className="group grid min-h-[34px] cursor-pointer grid-cols-[96px_1fr] items-start gap-2.5 rounded-lg px-2 py-1.5 hover:bg-raise">
      <div className="pt-1 text-[10.5px] font-bold uppercase tracking-[0.08em] text-faint">{label}</div>
      <div className="flex flex-wrap items-center gap-1.5 pt-0.5">
        {chips.length ? chips : <span className="text-[11.5px] text-faint group-hover:text-ember">+ Add</span>}
      </div>
    </div>
  )
}
