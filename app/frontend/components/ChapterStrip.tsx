import type { Segment } from '../types/video'

// Horizontal chapter bar under the player: one block per segment positioned by time, a live
// playhead, click-to-seek. Mirrors the vertical timeline panel (mockup parity).
export default function ChapterStrip({
  segments,
  durationSeconds,
  currentTime,
  onSeek,
}: {
  segments: Segment[]
  durationSeconds: number | null
  currentTime: number
  onSeek: (seconds: number) => void
}) {
  const dur = durationSeconds && durationSeconds > 0 ? durationSeconds : null
  const sorted = [...segments].sort((a, b) => a.startSeconds - b.startSeconds)

  return (
    <div className="mt-1.5">
      <div className="pb-1.5 text-[11px] font-bold uppercase tracking-[0.08em] text-faint">Chapters</div>
      <div className="relative h-[30px] overflow-hidden rounded-md bg-raise">
        {!sorted.length || !dur ? (
          <div className="absolute inset-0 flex items-center justify-center text-[10.5px] text-faint">
            {sorted.length ? 'No duration yet' : 'No chapters yet — add a segment'}
          </div>
        ) : (
          <>
            {sorted.map((s, i) => {
              const end = s.endSeconds != null ? s.endSeconds : sorted[i + 1]?.startSeconds ?? dur
              const left = (Math.max(0, s.startSeconds) / dur) * 100
              const width = Math.max(0.5, ((end - s.startSeconds) / dur) * 100)
              const open = s.endSeconds == null
              return (
                <button
                  key={s.id}
                  onClick={() => onSeek(s.startSeconds)}
                  title={s.title ?? ''}
                  style={{ left: `${left}%`, width: `${width}%` }}
                  className={`absolute bottom-0 top-0 flex items-center overflow-hidden whitespace-nowrap border-r border-surface px-1.5 text-[10px] font-semibold text-[#b2410f] ${open ? 'bg-[repeating-linear-gradient(45deg,rgba(226,87,31,.12),rgba(226,87,31,.12)_6px,rgba(226,87,31,.04)_6px,rgba(226,87,31,.04)_12px)]' : 'bg-ember/15 hover:bg-ember/25'}`}
                >
                  {s.title}
                </button>
              )
            })}
            <div className="absolute -bottom-0.5 -top-0.5 w-0.5 bg-ember" style={{ left: `${(Math.min(currentTime, dur) / dur) * 100}%` }} />
          </>
        )}
      </div>
      <p className="mt-1.5 text-[10.5px] text-faint">Segments shown on the video timeline — click to jump. (Mirrors the panel on the right.)</p>
    </div>
  )
}
