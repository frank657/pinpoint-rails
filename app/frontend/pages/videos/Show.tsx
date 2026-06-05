import { Head, Link, useForm } from '@inertiajs/react'
import { useRef, useEffect, useState } from 'react'
import axios from 'axios'
import AppShell from '../../components/AppShell'
import VideoPlayer, { type Playback, type PlayerHandle } from '../../components/VideoPlayer'
import NotesPanel, { type Note } from '../../components/NotesPanel'
import { formatTime } from '../../lib/time'

interface VideoDetail {
  id: number
  title: string
  source: 'upload' | 'youtube'
  durationSeconds: number | null
}

interface Segment {
  id: string
  title: string | null
  startSeconds: number
  endSeconds: number | null
}

interface Category {
  id: number
  name: string
}

interface TranscriptLine { startSeconds: number; text: string }

export default function VideoShow({
  video,
  playback,
  resumeSeconds,
  notes,
  segments,
  categories,
  tags,
  transcript,
}: {
  video: VideoDetail
  playback: Playback
  resumeSeconds: number
  notes: Note[]
  segments: Segment[]
  categories: Category[]
  tags: string[]
  transcript: TranscriptLine[]
}) {
  const player = useRef<PlayerHandle>(null)
  const seek = (s: number) => player.current?.seek(s)
  const getCurrentTime = () => player.current?.currentTime() ?? 0

  // Resume where the user left off, then persist progress periodically (Axis 3, Phase 7).
  useEffect(() => {
    const save = () => {
      const cur = Math.floor(getCurrentTime())
      if (cur > 0) axios.post('/progress', { trackable_type: 'Video', trackable_id: video.id, resume_seconds: cur })
    }
    const resume = setTimeout(() => { if (resumeSeconds > 1) seek(resumeSeconds) }, 1500)
    const interval = setInterval(save, 10000)
    return () => { clearTimeout(resume); clearInterval(interval); save() }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [video.id])

  return (
    <AppShell>
      <Head title={`${video.title} · Pinpoint`} />
      <Link href="/videos" className="text-sm text-neutral-500 hover:text-neutral-900">← All videos</Link>
      <h1 className="mt-2 text-2xl font-semibold tracking-tight">{video.title}</h1>

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-[1fr_380px]">
        <div>
          <VideoPlayer ref={player} playback={playback} />
          {segments.length > 0 && (
            <div className="mt-4 flex flex-wrap gap-2">
              {segments.map((s) => (
                <button
                  key={s.id}
                  onClick={() => seek(s.startSeconds)}
                  className="rounded-full border border-neutral-200 px-3 py-1 text-xs hover:border-amber-400"
                >
                  <span className="font-mono text-neutral-400">{formatTime(s.startSeconds)}</span>{' '}
                  {s.title ?? 'Segment'}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="lg:h-[70vh]">
          <NotesPanel
            videoId={video.id}
            notes={notes}
            categories={categories}
            tags={tags}
            onSeek={seek}
            getCurrentTime={getCurrentTime}
          />
        </div>
      </div>

      <TranscriptSection videoId={video.id} transcript={transcript} onSeek={seek} />
    </AppShell>
  )
}

interface Flashcard { front: string; back: string; accepted?: boolean }

function TranscriptSection({ videoId, transcript, onSeek }: { videoId: number; transcript: TranscriptLine[]; onSeek: (s: number) => void }) {
  const form = useForm({ text: '' })
  const [ai, setAi] = useState<{ summary: string; flashcards: Flashcard[] } | null>(null)
  const [busy, setBusy] = useState(false)

  const summarize = async () => {
    setBusy(true)
    const { data } = await axios.get(`/videos/${videoId}/summary`)
    setAi(data)
    setBusy(false)
  }

  const editCard = (i: number, field: 'front' | 'back', value: string) =>
    setAi((prev) => prev && { ...prev, flashcards: prev.flashcards.map((c, j) => (j === i ? { ...c, [field]: value } : c)) })

  const acceptCard = async (i: number) => {
    const card = ai!.flashcards[i]
    await axios.post(`/videos/${videoId}/flashcard`, { front: card.front, back: card.back })
    setAi((prev) => prev && { ...prev, flashcards: prev.flashcards.map((c, j) => (j === i ? { ...c, accepted: true } : c)) })
  }

  return (
    <section className="mt-10">
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-medium uppercase tracking-wide text-neutral-400">Transcript</h2>
        {transcript.length > 0 && (
          <button onClick={summarize} disabled={busy} className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm hover:bg-neutral-50 disabled:opacity-50">
            {busy ? 'Summarizing…' : '✨ AI summary'}
          </button>
        )}
      </div>

      {ai && (
        <div className="mt-3 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm">
          <p className="text-xs font-medium uppercase tracking-wide text-amber-600">AI draft — review &amp; edit before keeping</p>
          <p className="mt-2 text-neutral-700">{ai.summary}</p>
          {ai.flashcards.length > 0 && (
            <ul className="mt-3 space-y-2">
              {ai.flashcards.map((c, i) => (
                <li key={i} className="rounded-lg border border-amber-200 bg-white p-2">
                  {c.accepted ? (
                    <p className="text-emerald-700">✓ Saved to review — <strong>{c.front}</strong></p>
                  ) : (
                    <div className="flex flex-col gap-1.5 sm:flex-row sm:items-center">
                      <input
                        value={c.front}
                        onChange={(e) => editCard(i, 'front', e.target.value)}
                        className="flex-1 rounded border border-neutral-300 px-2 py-1 text-sm focus:border-amber-400 focus:outline-none"
                        aria-label="Flashcard front"
                      />
                      <span className="text-neutral-400">→</span>
                      <input
                        value={c.back}
                        onChange={(e) => editCard(i, 'back', e.target.value)}
                        className="flex-1 rounded border border-neutral-300 px-2 py-1 text-sm focus:border-amber-400 focus:outline-none"
                        aria-label="Flashcard back"
                      />
                      <button
                        onClick={() => acceptCard(i)}
                        className="rounded bg-neutral-900 px-3 py-1 text-xs font-medium text-white hover:bg-neutral-700"
                      >
                        Accept
                      </button>
                    </div>
                  )}
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      {transcript.length > 0 ? (
        <ul className="mt-3 max-h-72 overflow-y-auto rounded-xl border border-neutral-200 bg-white p-2 text-sm">
          {transcript.map((l, i) => (
            <li key={i}>
              <button onClick={() => onSeek(l.startSeconds)} className="flex w-full gap-2 rounded px-2 py-1 text-left hover:bg-neutral-100">
                <span className="font-mono text-xs text-amber-600">{formatTime(l.startSeconds)}</span>
                <span className="text-neutral-700">{l.text}</span>
              </button>
            </li>
          ))}
        </ul>
      ) : (
        <form onSubmit={(e) => { e.preventDefault(); form.post(`/videos/${videoId}/transcript`, { onSuccess: () => form.reset() }) }} className="mt-3">
          <textarea
            placeholder="Paste a transcript (SRT/VTT or “0:05 text” lines)…"
            value={form.data.text}
            onChange={(e) => form.setData('text', e.target.value)}
            rows={4}
            className="w-full rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
          />
          <button className="mt-2 rounded-lg bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-700">Import transcript</button>
        </form>
      )}
    </section>
  )
}
