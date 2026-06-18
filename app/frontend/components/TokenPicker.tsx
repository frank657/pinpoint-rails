import { useRef, useState } from 'react'
import AthleteAvatar from './AthleteAvatar'

// A selectable token (taxonomy ref, tag, or athlete). `id` is null for a not-yet-persisted
// value the user just created by typing (tags / athletes).
export interface PickItem {
  id: string | null
  name: string
  avatarUrl?: string | null
  initials?: string
  hue?: number
}

export type PickerKind = 'cat' | 'pos' | 'tech' | 'tags' | 'ath'

export function computeInitials(name: string): string {
  return name.trim().split(/\s+/).map((w) => w[0]).filter(Boolean).slice(0, 2).join('').toUpperCase()
}
export function computeHue(name: string): number {
  return [...name].reduce((a, c) => a + c.charCodeAt(0), 0) % 360
}

const sameItem = (a: PickItem, b: PickItem) => (a.id != null && b.id != null ? a.id === b.id : a.name.toLowerCase() === b.name.toLowerCase())

// The mockup's searchable combobox: type → filtered dropdown → pill (with ×). Tags & athletes
// are creatable on Enter; curated kinds pick from existing options only.
export default function TokenPicker({
  kind,
  options,
  value,
  onChange,
  placeholder = 'search…',
}: {
  kind: PickerKind
  options: PickItem[]
  value: PickItem[]
  onChange: (next: PickItem[]) => void
  placeholder?: string
}) {
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const creatable = kind === 'tags' || kind === 'ath'
  const isAthlete = kind === 'ath'
  const isTag = kind === 'tags'

  const q = query.trim().toLowerCase()
  const available = options
    .filter((o) => !value.some((v) => sameItem(v, o)))
    .filter((o) => o.name.toLowerCase().includes(q))
    .slice(0, 8)
  const exactExists =
    options.some((o) => o.name.toLowerCase() === q) || value.some((v) => v.name.toLowerCase() === q)
  const showCreate = creatable && q.length > 0 && !exactExists

  const add = (item: PickItem) => {
    onChange([...value, item])
    setQuery('')
    inputRef.current?.focus()
  }
  const create = (name: string) => {
    const trimmed = name.trim()
    if (!trimmed) return
    add(isAthlete ? { id: null, name: trimmed, initials: computeInitials(trimmed), hue: computeHue(trimmed) } : { id: null, name: trimmed })
  }
  const remove = (item: PickItem) => onChange(value.filter((v) => !sameItem(v, item)))

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      if (available.length) add(available[0])
      else if (showCreate) create(query)
    } else if (e.key === 'Backspace' && query === '' && value.length) {
      remove(value[value.length - 1])
    }
  }

  return (
    <div className="relative">
      <div className="flex flex-wrap items-center gap-1 rounded-lg border border-line bg-surface p-1">
        {value.map((item) => (
          <span key={(item.id ?? 'n') + item.name} className="inline-flex items-center gap-1.5 rounded-full bg-raise py-0.5 pl-2 pr-1 text-[11px] text-ink">
            {isAthlete && <AthleteAvatar athlete={{ name: item.name, avatarUrl: item.avatarUrl ?? null, initials: item.initials ?? computeInitials(item.name), hue: item.hue ?? computeHue(item.name) }} size={16} />}
            {isTag ? `#${item.name}` : item.name}
            <button type="button" onClick={() => remove(item)} className="text-faint hover:text-ember" aria-label={`Remove ${item.name}`}>×</button>
          </span>
        ))}
        <input
          ref={inputRef}
          value={query}
          placeholder={placeholder}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 160)}
          onKeyDown={onKeyDown}
          className="min-w-[90px] flex-1 border-none bg-transparent p-0.5 text-xs outline-none"
        />
      </div>
      {open && (available.length > 0 || showCreate) && (
        <div className="absolute left-0 right-0 top-full z-20 mt-1 max-h-[184px] overflow-auto rounded-lg border border-line bg-surface shadow-[0_8px_22px_rgba(44,32,20,.14)]">
          {showCreate && (
            <div onMouseDown={(e) => { e.preventDefault(); create(query) }} className="cursor-pointer px-3 py-1.5 text-xs font-semibold text-ember hover:bg-raise">
              + create “{query.trim()}”
            </div>
          )}
          {available.map((o) => (
            <div key={(o.id ?? 'n') + o.name} onMouseDown={(e) => { e.preventDefault(); add(o) }} className="flex cursor-pointer items-center gap-1.5 px-3 py-1.5 text-xs hover:bg-raise">
              {isAthlete && <AthleteAvatar athlete={{ name: o.name, avatarUrl: o.avatarUrl ?? null, initials: o.initials ?? computeInitials(o.name), hue: o.hue ?? computeHue(o.name) }} size={16} />}
              {isTag ? `#${o.name}` : o.name}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
