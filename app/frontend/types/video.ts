// Shared types for the video show page (timeline panel + below-video details).

// A payload shape accepted by Inertia's router (subset of RequestPayload sufficient for our
// note/segment/video mutations).
export type RouterPayload = Record<string, string | number | boolean | null | Array<string | number | null>>

export interface TaxonomyRef {
  id: string
  name: string
}

export interface Athlete {
  id: string
  name: string
  avatarUrl: string | null
  initials: string
  hue: number
}

export type NoteType = 'timestamp' | 'rich_text'

export interface Note {
  id: string
  noteType: NoteType
  videoId: number | null
  segmentId: string | null
  title: string | null
  startSeconds: number | null
  endSeconds: number | null
  body: string
  categories: TaxonomyRef[]
  tags: string[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
  createdAt: string
}

export interface Segment {
  id: string
  title: string | null
  startSeconds: number
  endSeconds: number | null
  position: number
}

export interface VideoDetail {
  id: string
  title: string
  source: 'upload' | 'youtube'
  youtubeId: string | null
  durationSeconds: number | null
  status: string
  playable: boolean
  poster: string | null
  description: string | null
  createdAt: string
  noteCount: number
  segmentCount: number
  categories: TaxonomyRef[]
  positions: TaxonomyRef[]
  techniques: TaxonomyRef[]
  athletes: Athlete[]
  tags: string[]
}

// mm:ss for display.
export function fmtTime(seconds: number | null | undefined): string {
  if (seconds == null) return '—'
  const s = Math.max(0, Math.round(seconds))
  const m = Math.floor(s / 60)
  return `${m}:${String(s % 60).padStart(2, '0')}`
}

// Parse "m:ss" or a bare seconds number; null when blank/invalid.
export function parseTime(value: string): number | null {
  const v = value.trim()
  if (v === '') return null
  if (v.includes(':')) {
    const [m, s] = v.split(':')
    return Number(m) * 60 + (Number(s) || 0)
  }
  const n = Number(v)
  return Number.isNaN(n) ? null : n
}
