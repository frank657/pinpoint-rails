// Small inline glyphs used across the timeline panel (mockup parity).

export function SegmentIcon({ className = '' }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" className={className}>
      <path d="M3 3v10M13 3v10M3 8h10" />
    </svg>
  )
}

export function PlayIcon({ className = '', size = 13 }: { className?: string; size?: number }) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} fill="currentColor" className={className}>
      <path d="M4.5 3.2v9.6a.6.6 0 0 0 .92.5l7.3-4.8a.6.6 0 0 0 0-1l-7.3-4.8a.6.6 0 0 0-.92.5z" />
    </svg>
  )
}

export function NoteIcon({ className = '', size = 12 }: { className?: string; size?: number }) {
  return (
    <svg viewBox="0 0 16 16" width={size} height={size} fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
      <path d="M4 2.5h5l3 3v8H4z" />
      <path d="M9 2.5v3h3M6 9h4M6 11.5h3" />
    </svg>
  )
}
