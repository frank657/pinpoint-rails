import type { Athlete } from '../types/video'

// An athlete's avatar: the attached image when present, otherwise a coloured initials badge
// (deterministic hue from the name). Always paired with the athlete's name by callers.
export default function AthleteAvatar({ athlete, size = 20 }: { athlete: Pick<Athlete, 'name' | 'avatarUrl' | 'initials' | 'hue'>; size?: number }) {
  const dim = { width: size, height: size }
  if (athlete.avatarUrl) {
    return <img src={athlete.avatarUrl} alt={athlete.name} className="flex-none rounded-full object-cover" style={dim} />
  }
  return (
    <span
      className="inline-grid flex-none place-items-center rounded-full font-bold text-white"
      style={{ ...dim, background: `hsl(${athlete.hue} 46% 52%)`, fontSize: Math.round(size * 0.42) }}
    >
      {athlete.initials || '?'}
    </span>
  )
}
