import { Head, router } from '@inertiajs/react'
import AppShell from '../../components/AppShell'

interface Content { type: string; title: string; summary: string }

export default function ShareShow({ token, content }: { token: string; content: Content }) {
  const save = () => router.post(`/s/${token}/fork`)

  return (
    <AppShell>
      <Head title={`${content.title} · Shared on Pinpoint`} />
      <div className="mx-auto mt-12 max-w-lg rounded-xl border border-neutral-200 bg-white p-8 text-center">
        <p className="text-xs font-mono uppercase tracking-[0.2em] text-amber-500">Shared with you</p>
        <h1 className="mt-4 text-2xl font-semibold tracking-tight">{content.title}</h1>
        <p className="mt-2 text-sm text-neutral-500">{content.summary}</p>
        <button
          onClick={save}
          className="mt-8 rounded-lg bg-amber-400 px-6 py-3 font-medium text-neutral-950 hover:bg-amber-300"
        >
          Save to my workspace
        </button>
        <p className="mt-3 text-xs text-neutral-400">A private, independent copy will be added to your current workspace.</p>
      </div>
    </AppShell>
  )
}
