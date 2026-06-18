import { useState, useRef } from 'react'
import { router } from '@inertiajs/react'
import { fmtTime, parseTime, type RouterPayload } from '../types/video'
import { TaxFields, emptyDraft, taxonomyPayload, type NoteDraft, type TaxOptions } from './timeline/forms'

// The quick-capture footer (mockup: docs/mockups/260618-video-page-full.html, Version A).
// Always-visible bar pinned to the bottom of the viewport. Start is blank until the title is
// focused (first focus pins the playhead, then it stays put — no live ticking). Time controls sit
// above the input: start cluster on the left (nudges + "⟲ now"), end on the right ("+ end time"
// → editable end with its own "⟲ now" + ✕). Add appears inside the field once you type.
// ⌘/Ctrl+⏎ adds · ⌘/Ctrl+↑ toggles the Details (taxonomy + body) disclosure.
export default function QuickCapture({
  videoId,
  getCurrentTime,
  opts,
}: {
  videoId: string
  getCurrentTime: () => number
  opts: TaxOptions
}) {
  const [title, setTitle] = useState('')
  const [start, setStart] = useState<number | null>(null)
  const [end, setEnd] = useState<number | null>(null)
  const [endOn, setEndOn] = useState(false)
  const [expanded, setExpanded] = useState(false)
  const [focused, setFocused] = useState(false)
  const [draft, setDraft] = useState<NoteDraft>(emptyDraft())
  const titleRef = useRef<HTMLInputElement>(null)

  const now = () => Math.floor(getCurrentTime())
  const onTitleFocus = () => { setFocused(true); setStart((s) => (s == null ? now() : s)) }
  const nudge = (d: number) => setStart((s) => Math.max(0, (s == null ? now() : s) + d))
  const addEnd = () => { setEndOn(true); setEnd((e) => (e == null ? Math.max(now(), start ?? now()) : e)) }
  const removeEnd = () => { setEndOn(false); setEnd(null) }
  const reset = () => { setTitle(''); setStart(null); setEnd(null); setEndOn(false); setDraft(emptyDraft()) }

  const submit = () => {
    const t = title.trim()
    if (!t) return
    const payload: RouterPayload = {
      video_id: videoId,
      note_type: 'timestamp',
      title: t,
      start_seconds: start == null ? now() : start,
      end_seconds: endOn ? end : null,
      ...taxonomyPayload(draft),
    }
    router.post('/notes', payload, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => { reset(); titleRef.current?.focus() },
    })
  }

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey || e.shiftKey)) { e.preventDefault(); submit() }
    else if (e.key === 'ArrowUp' && (e.metaKey || e.ctrlKey)) { e.preventDefault(); setExpanded((v) => !v) }
  }

  const tinput = 'w-[58px] rounded-md border border-line bg-surface px-2 py-1.5 text-center font-mono text-[11.5px] focus:border-ember focus:outline-none'
  const tbtn = 'inline-flex items-center gap-1.5 rounded-lg border border-line bg-surface px-2.5 py-1.5 text-[11px] text-muted hover:border-ember hover:text-ember'
  const hasInput = title.trim().length > 0

  return (
    <div className={`fixed bottom-0 left-0 right-0 z-50 border-t border-line bg-surface lg:left-[220px] ${focused ? 'shadow-[0_-8px_24px_rgba(226,87,31,0.11)]' : 'shadow-[0_-8px_24px_rgba(44,32,20,0.07)]'}`}>
      <div className="mx-auto max-w-6xl px-6 pb-3 pt-2.5 lg:px-9">
        {expanded && (
          <div className="mb-2.5 border-b border-line pb-2.5">
            <TaxFields opts={opts} draft={draft} setDraft={setDraft} />
          </div>
        )}

        {/* time row — start cluster (left), end cluster (right), details toggle */}
        <div className="mb-2 flex items-center gap-2.5">
          <div className="flex flex-none items-center gap-2">
            <span className="text-[10px] font-bold uppercase tracking-[0.06em] text-faint">start</span>
            <input value={start == null ? '' : fmtTime(start)} onChange={(e) => setStart(parseTime(e.target.value))} onKeyDown={onKey} placeholder="–:––" className={tinput} />
            <div className="inline-flex overflow-hidden rounded-lg border border-line">
              {[-10, -5, 5, 10].map((d) => (
                <button key={d} onMouseDown={(e) => { e.preventDefault(); nudge(d) }} className="border-r border-line px-2.5 py-1.5 font-mono text-[11.5px] text-muted last:border-r-0 hover:bg-raise hover:text-ink">
                  {d > 0 ? `+${d}s` : `${d}s`}
                </button>
              ))}
            </div>
            <button onMouseDown={(e) => { e.preventDefault(); setStart(now()) }} className={tbtn}>⟲ now</button>
          </div>

          <span className="h-5 w-px flex-none bg-line" />

          <div className="flex flex-none items-center gap-2">
            {endOn ? (
              <>
                <span className="text-[10px] font-bold uppercase tracking-[0.06em] text-faint">end</span>
                <input value={end == null ? '' : fmtTime(end)} onChange={(e) => setEnd(parseTime(e.target.value))} onKeyDown={onKey} placeholder="–:––" className={tinput} />
                <button onMouseDown={(e) => { e.preventDefault(); setEnd(now()) }} className={tbtn}>⟲ now</button>
                <button onMouseDown={(e) => { e.preventDefault(); removeEnd() }} title="remove end time" className="px-0.5 text-[13px] text-faint hover:text-ember">✕</button>
              </>
            ) : (
              <button onMouseDown={(e) => { e.preventDefault(); addEnd() }} className="inline-flex items-center gap-1.5 rounded-lg border border-dashed border-line bg-surface px-2.5 py-1.5 text-[11px] text-muted hover:border-ember hover:text-ember">+ end time</button>
            )}
          </div>

          <button onClick={() => setExpanded((v) => !v)} className="ml-auto flex flex-none items-center gap-1.5 text-[11.5px] font-semibold text-muted hover:text-ember">
            <span className={`inline-block transition-transform ${expanded ? 'rotate-90' : ''}`}>▸</span> Details <kbd className="rounded bg-raise px-1.5 py-px font-mono text-[10px] text-faint">⌘↑</kbd>
          </button>
        </div>

        {/* input row — Add note sits inside the field, appearing once you type */}
        <div className="flex items-center gap-2.5">
          <div className="relative flex flex-1 items-center">
            <input
              ref={titleRef}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              onFocus={onTitleFocus}
              onBlur={() => setFocused(false)}
              onKeyDown={onKey}
              placeholder="Take a note at the current time…"
              className={`w-full rounded-xl border border-line bg-surface py-[13px] text-[14px] focus:border-ember focus:outline-none ${hasInput ? 'pl-[14px] pr-[130px]' : 'px-[14px]'}`}
            />
            {hasInput && (
              <button onClick={submit} className="absolute bottom-1.5 right-1.5 top-1.5 inline-flex items-center gap-1.5 rounded-lg bg-ember px-4 text-[13px] font-semibold text-white hover:bg-[#c8480f]">
                Add note <kbd className="rounded bg-white/20 px-1 py-px font-mono text-[10px]">⌘⏎</kbd>
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
