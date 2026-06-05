import { Head, Link, router } from '@inertiajs/react'
import { useState } from 'react'
import axios from 'axios'
import AppShell from '../../components/AppShell'

interface Card { id: number; noteTitle: string | null; front: string; back: string; state: string; template: string }
interface Theme { value: string; label: string }

const GRADES: [number, string, string][] = [
  [1, 'Again', 'bg-red-500'],
  [2, 'Hard', 'bg-orange-500'],
  [3, 'Good', 'bg-emerald-500'],
  [4, 'Easy', 'bg-sky-500'],
]

export default function Review({ cards, theme, themes }: { cards: Card[]; theme: string | null; themes: Theme[] }) {
  const [index, setIndex] = useState(0)
  const [revealed, setRevealed] = useState(false)
  const card = cards[index]

  const grade = (rating: number) => {
    axios.post(`/review/${card.id}/grade`, { rating })
    setRevealed(false)
    setIndex((i) => i + 1)
  }

  const pickTheme = (value: string) =>
    router.get('/review', value ? { theme: value } : {}, { preserveState: false })

  return (
    <AppShell>
      <Head title="Review · Pinpoint" />

      {themes.length > 0 && (
        <div className="mx-auto mb-6 flex max-w-2xl flex-wrap items-center gap-2">
          <span className="text-xs uppercase tracking-wide text-neutral-400">Queue</span>
          <button
            onClick={() => pickTheme('')}
            className={`rounded-full px-3 py-1 text-xs ${!theme ? 'bg-neutral-900 text-white' : 'border border-neutral-300 text-neutral-600 hover:bg-neutral-100'}`}
          >
            All due
          </button>
          {themes.map((t) => (
            <button
              key={t.value}
              onClick={() => pickTheme(t.value)}
              className={`rounded-full px-3 py-1 text-xs ${theme === t.value ? 'bg-neutral-900 text-white' : 'border border-neutral-300 text-neutral-600 hover:bg-neutral-100'}`}
            >
              {t.label}
            </button>
          ))}
        </div>
      )}

      {!card ? (
        <div className="mx-auto mt-16 max-w-md text-center">
          <p className="text-5xl">✅</p>
          <h1 className="mt-4 text-2xl font-semibold tracking-tight">All caught up</h1>
          <p className="mt-2 text-neutral-500">No cards due{theme ? ' for this topic' : ''} right now.</p>
          <Link href="/notes" className="mt-6 inline-block text-sm text-amber-600 hover:underline">Back to notes</Link>
        </div>
      ) : (
        <div className="mx-auto mt-8 max-w-2xl">
          <p className="text-center text-xs uppercase tracking-wide text-neutral-400">
            {cards.length - index} card{cards.length - index === 1 ? '' : 's'} left
            {card.template.startsWith('cloze:') && <span className="ml-2 rounded bg-amber-100 px-1.5 py-0.5 text-amber-700">cloze</span>}
          </p>
          <div className="mt-4 rounded-2xl border border-neutral-200 bg-white p-10 text-center">
            <h2 className="text-xl font-semibold">{card.noteTitle ?? 'Note'}</h2>
            {card.front && (
              <div className="prose prose-sm mx-auto mt-6 max-w-none text-left text-neutral-700" dangerouslySetInnerHTML={{ __html: card.front }} />
            )}
            {revealed ? (
              <div className="prose prose-sm mx-auto mt-6 max-w-none border-t border-neutral-100 pt-6 text-left text-neutral-700" dangerouslySetInnerHTML={{ __html: card.back || '<em>(no detail)</em>' }} />
            ) : (
              <button onClick={() => setRevealed(true)} className="mt-8 rounded-lg bg-neutral-900 px-6 py-2.5 text-sm font-medium text-white hover:bg-neutral-700">
                Show answer
              </button>
            )}
          </div>
          {revealed && (
            <div className="mt-4 grid grid-cols-4 gap-2">
              {GRADES.map(([rating, label, color]) => (
                <button key={rating} onClick={() => grade(rating)} className={`rounded-lg ${color} px-3 py-2.5 text-sm font-medium text-white hover:opacity-90`}>
                  {label}
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </AppShell>
  )
}
