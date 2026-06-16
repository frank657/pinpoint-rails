import { useId, useState, type KeyboardEvent } from 'react'

// A reusable chip/token input: type a value and press Enter or comma to add it, click a chip's
// ✕ (or Backspace on an empty field) to remove it. Optional datalist autocomplete. Shared by
// note tags, video tags, athletes, and the note position/technique pickers (iteration 0006).
interface Props {
  value: string[]
  onChange: (next: string[]) => void
  suggestions?: string[]
  placeholder?: string
  chipClassName?: string
}

export default function TokenInput({ value, onChange, suggestions = [], placeholder, chipClassName }: Props) {
  const [draft, setDraft] = useState('')
  const listId = useId()
  const chip = chipClassName ?? 'bg-amber-100 text-amber-700'

  const add = (raw: string) => {
    const next = raw.trim()
    if (!next) return
    if (!value.some((v) => v.toLowerCase() === next.toLowerCase())) onChange([...value, next])
    setDraft('')
  }

  const removeAt = (i: number) => onChange(value.filter((_, idx) => idx !== i))

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault()
      add(draft)
    } else if (e.key === 'Backspace' && !draft && value.length > 0) {
      removeAt(value.length - 1)
    }
  }

  return (
    <div className="flex flex-wrap items-center gap-1.5 rounded-lg border border-neutral-300 px-2 py-1.5 focus-within:border-ember">
      {value.map((token, i) => (
        <span key={token} className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${chip}`}>
          {token}
          <button type="button" onClick={() => removeAt(i)} className="opacity-60 hover:opacity-100" aria-label={`Remove ${token}`}>
            ✕
          </button>
        </span>
      ))}
      <input
        list={listId}
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKeyDown}
        onBlur={() => add(draft)}
        placeholder={value.length === 0 ? placeholder : ''}
        className="min-w-[8ch] flex-1 bg-transparent text-sm outline-none"
      />
      {suggestions.length > 0 && (
        <datalist id={listId}>
          {suggestions.map((s) => <option key={s} value={s} />)}
        </datalist>
      )}
    </div>
  )
}
