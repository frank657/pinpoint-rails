import { useEffect, useRef, useState, useCallback } from 'react'
import { createPortal } from 'react-dom'
import { router } from '@inertiajs/react'
import axios from 'axios'
import {
  MagnifyingGlass,
  ClockCounterClockwise,
  Waveform,
  Note,
  X,
  ArrowElbowDownLeft,
} from '@phosphor-icons/react'
import { formatTime } from '../lib/time'

interface TranscriptHit {
  videoId: number
  videoTitle: string
  startSeconds: number
  text: string
}

interface NoteHit {
  id: string
  title: string | null
  videoId: number | null
  startSeconds: number | null
}

interface Results {
  transcript: TranscriptHit[]
  notes: NoteHit[]
}

interface FlatItem {
  key: string
  href: string
  historyLabel: string
  render: () => React.ReactNode
}

const HISTORY_KEY = 'pinpoint_search_history'
const MAX_HISTORY = 8

function loadHistory(): string[] {
  try {
    return JSON.parse(localStorage.getItem(HISTORY_KEY) ?? '[]')
  } catch {
    return []
  }
}

function saveToHistory(q: string) {
  const next = [q, ...loadHistory().filter((h) => h !== q)].slice(0, MAX_HISTORY)
  localStorage.setItem(HISTORY_KEY, JSON.stringify(next))
}

interface Props {
  open: boolean
  onClose: () => void
}

export default function SearchSpotlight({ open, onClose }: Props) {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<Results | null>(null)
  const [loading, setLoading] = useState(false)
  const [history, setHistory] = useState<string[]>([])
  const [selected, setSelected] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  // Reload history each time the spotlight opens
  useEffect(() => {
    if (!open) return
    setQuery('')
    setResults(null)
    setSelected(0)
    setHistory(loadHistory())
    // Small delay so the portal mounts before focus
    const t = setTimeout(() => inputRef.current?.focus(), 30)
    return () => clearTimeout(t)
  }, [open])

  // Debounced query → JSON endpoint
  useEffect(() => {
    if (!query.trim()) {
      setResults(null)
      setSelected(0)
      return
    }
    setLoading(true)
    const t = setTimeout(async () => {
      try {
        const { data } = await axios.get<Results>('/search/query', { params: { q: query } })
        setResults(data)
        setSelected(0)
      } finally {
        setLoading(false)
      }
    }, 220)
    return () => clearTimeout(t)
  }, [query])

  // Build flat navigation list from current results
  const items: FlatItem[] = query.trim()
    ? [
        ...(results?.transcript.slice(0, 6).map((h, i) => ({
          key: `t-${i}`,
          href: `/videos/${h.videoId}`,
          historyLabel: query,
          render: () => (
            <span className="flex min-w-0 items-start gap-3">
              <Waveform size={15} weight="regular" className="mt-0.5 flex-none text-neutral-400" />
              <span className="min-w-0">
                <span className="block truncate text-sm text-neutral-700 line-clamp-1">{h.text}</span>
                <span className="text-xs text-neutral-400">
                  <span className="font-mono text-amber-600">{formatTime(h.startSeconds)}</span>
                  {' · '}{h.videoTitle}
                </span>
              </span>
            </span>
          ),
        })) ?? []),
        ...(results?.notes.slice(0, 6).map((n, i) => ({
          key: `n-${i}`,
          href: n.videoId ? `/videos/${n.videoId}` : '/notes',
          historyLabel: query,
          render: () => (
            <span className="flex items-center gap-3">
              <Note size={15} weight="regular" className="flex-none text-neutral-400" />
              <span className="min-w-0 truncate text-sm text-neutral-700">
                {n.title || <em className="text-neutral-400">Untitled note</em>}
              </span>
              {n.startSeconds != null && (
                <span className="ml-auto flex-none font-mono text-xs text-amber-600">
                  {formatTime(n.startSeconds)}
                </span>
              )}
            </span>
          ),
        })) ?? []),
      ]
    : []

  const navigate = useCallback(
    (href: string, label: string) => {
      saveToHistory(label)
      onClose()
      router.visit(href)
    },
    [onClose],
  )

  const runHistory = useCallback(
    (q: string) => {
      setQuery(q)
      inputRef.current?.focus()
    },
    [],
  )

  const removeHistory = useCallback((entry: string, e: React.MouseEvent) => {
    e.stopPropagation()
    const next = loadHistory().filter((h) => h !== entry)
    localStorage.setItem(HISTORY_KEY, JSON.stringify(next))
    setHistory(next)
  }, [])

  // Keyboard navigation
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose()
        return
      }
      if (items.length === 0) return
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setSelected((s) => Math.min(s + 1, items.length - 1))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setSelected((s) => Math.max(s - 1, 0))
      } else if (e.key === 'Enter') {
        e.preventDefault()
        const item = items[selected]
        if (item) navigate(item.href, item.historyLabel)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, items, selected, navigate, onClose])

  // Scroll selected item into view
  useEffect(() => {
    const el = listRef.current?.querySelector(`[data-idx="${selected}"]`) as HTMLElement | null
    el?.scrollIntoView({ block: 'nearest' })
  }, [selected])

  if (!open) return null

  const showHistory = !query.trim() && history.length > 0
  const showEmpty = query.trim() && !loading && results && items.length === 0

  const sectionLabel = (label: string) => (
    <p className="px-3 pb-1 pt-3 text-[10.5px] font-semibold uppercase tracking-[0.14em] text-neutral-400">
      {label}
    </p>
  )

  return createPortal(
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-[14vh]"
      style={{ background: 'rgba(20,16,12,0.45)', backdropFilter: 'blur(4px)' }}
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="flex w-full max-w-[560px] flex-col overflow-hidden rounded-2xl border border-neutral-200 bg-surface shadow-2xl"
        style={{ maxHeight: '70vh' }}
      >
        {/* Input row */}
        <div className="flex items-center gap-3 border-b border-neutral-200 px-4 py-3.5">
          <MagnifyingGlass size={18} weight="regular" className="flex-none text-neutral-400" />
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search videos, notes, transcripts…"
            className="flex-1 bg-transparent text-[15px] text-neutral-900 outline-none placeholder:text-neutral-400"
          />
          {query ? (
            <button
              onClick={() => { setQuery(''); inputRef.current?.focus() }}
              className="flex-none rounded p-0.5 text-neutral-400 hover:text-neutral-700"
            >
              <X size={15} weight="bold" />
            </button>
          ) : (
            <kbd className="flex-none rounded border border-neutral-200 px-1.5 py-0.5 text-[11px] text-neutral-400">
              esc
            </kbd>
          )}
        </div>

        {/* Results / history pane */}
        <div ref={listRef} className="overflow-y-auto p-2">
          {/* History */}
          {showHistory && (
            <>
              {sectionLabel('Recent')}
              {history.map((h) => (
                <button
                  key={h}
                  onClick={() => runHistory(h)}
                  className="group flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm text-neutral-600 hover:bg-neutral-100"
                >
                  <ClockCounterClockwise size={15} className="flex-none text-neutral-400" />
                  <span className="flex-1 truncate">{h}</span>
                  <span
                    role="button"
                    onClick={(e) => removeHistory(h, e)}
                    className="hidden text-neutral-400 hover:text-neutral-700 group-hover:block"
                  >
                    <X size={13} weight="bold" />
                  </span>
                </button>
              ))}
            </>
          )}

          {/* Idle, no history */}
          {!query.trim() && history.length === 0 && (
            <p className="px-3 py-6 text-center text-sm text-neutral-400">
              Start typing to search across your library…
            </p>
          )}

          {/* Loading */}
          {loading && (
            <p className="px-3 py-6 text-center text-sm text-neutral-400">Searching…</p>
          )}

          {/* Empty results */}
          {showEmpty && (
            <p className="px-3 py-6 text-center text-sm text-neutral-400">
              No results for <span className="font-medium text-neutral-600">"{query}"</span>
            </p>
          )}

          {/* Transcript hits */}
          {!loading && (results?.transcript.length ?? 0) > 0 && (
            <>
              {sectionLabel('Transcript')}
              {results!.transcript.slice(0, 6).map((h, i) => {
                const idx = i
                return (
                  <button
                    key={`t-${i}`}
                    data-idx={idx}
                    onClick={() => navigate(`/videos/${h.videoId}`, query)}
                    onMouseEnter={() => setSelected(idx)}
                    className={`flex w-full items-start gap-3 rounded-lg px-3 py-2 text-left transition-colors ${
                      selected === idx ? 'bg-neutral-100' : 'hover:bg-neutral-100'
                    }`}
                  >
                    <Waveform size={15} weight="regular" className="mt-0.5 flex-none text-neutral-400" />
                    <span className="min-w-0">
                      <span className="block truncate text-sm text-neutral-700 line-clamp-1">{h.text}</span>
                      <span className="text-xs text-neutral-400">
                        <span className="font-mono text-amber-600">{formatTime(h.startSeconds)}</span>
                        {' · '}{h.videoTitle}
                      </span>
                    </span>
                    {selected === idx && (
                      <ArrowElbowDownLeft size={13} className="ml-auto mt-1 flex-none text-neutral-400" />
                    )}
                  </button>
                )
              })}
            </>
          )}

          {/* Note hits */}
          {!loading && (results?.notes.length ?? 0) > 0 && (
            <>
              {sectionLabel('Notes')}
              {results!.notes.slice(0, 6).map((n, i) => {
                const idx = (results?.transcript.slice(0, 6).length ?? 0) + i
                return (
                  <button
                    key={`n-${i}`}
                    data-idx={idx}
                    onClick={() => navigate(n.videoId ? `/videos/${n.videoId}` : '/notes', query)}
                    onMouseEnter={() => setSelected(idx)}
                    className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left transition-colors ${
                      selected === idx ? 'bg-neutral-100' : 'hover:bg-neutral-100'
                    }`}
                  >
                    <Note size={15} weight="regular" className="flex-none text-neutral-400" />
                    <span className="min-w-0 flex-1 truncate text-sm text-neutral-700">
                      {n.title || <em className="text-neutral-400">Untitled</em>}
                    </span>
                    {n.startSeconds != null && (
                      <span className="flex-none font-mono text-xs text-amber-600">
                        {formatTime(n.startSeconds)}
                      </span>
                    )}
                    {selected === idx && (
                      <ArrowElbowDownLeft size={13} className="flex-none text-neutral-400" />
                    )}
                  </button>
                )
              })}
            </>
          )}
        </div>

        {/* Footer hint */}
        {items.length > 0 && (
          <div className="flex items-center gap-4 border-t border-neutral-100 px-4 py-2 text-[11px] text-neutral-400">
            <span className="flex items-center gap-1">
              <kbd className="rounded border border-neutral-200 px-1 py-px">↑↓</kbd> navigate
            </span>
            <span className="flex items-center gap-1">
              <kbd className="rounded border border-neutral-200 px-1 py-px">↵</kbd> open
            </span>
            <span className="flex items-center gap-1">
              <kbd className="rounded border border-neutral-200 px-1 py-px">esc</kbd> close
            </span>
          </div>
        )}
      </div>
    </div>,
    document.body,
  )
}
