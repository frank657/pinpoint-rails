import { Head, Link, router, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Position { id: string; name: string; category: string; dominance: string; noteCount: number }
interface Technique { id: string; name: string; kind: string; from: string | null; to: string | null }

const DOM_COLOR: Record<string, string> = { dominant: 'text-emerald-600', neutral: 'text-neutral-500', inferior: 'text-red-500' }
const NODE_FILL: Record<string, string> = { dominant: '#10b981', neutral: '#a3a3a3', inferior: '#ef4444' }

export default function PositionsIndex({ positions, techniques }: { positions: Position[]; techniques: Technique[] }) {
  const form = useForm({ name: '', category: 'guard', dominance: 'neutral' })
  const submit = (e: FormEvent) => { e.preventDefault(); form.post('/positions', { onSuccess: () => form.reset('name') }) }

  return (
    <AppShell>
      <Head title="Positions & techniques · Pinpoint" />
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Positions & techniques</h1>
        {positions.length === 0 && (
          <button onClick={() => router.post('/positions/seed')} className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">
            Load BJJ taxonomy
          </button>
        )}
      </div>

      {positions.length > 0 && <TaxonomyGraph positions={positions} techniques={techniques} />}

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <section>
          <h2 className="text-sm font-medium uppercase tracking-wide text-neutral-400">Positions</h2>
          <ul className="mt-3 space-y-1">
            {positions.map((p) => (
              <li key={p.id}>
                <Link href={`/positions/${p.id}`} className="flex items-center justify-between rounded px-2 py-1.5 hover:bg-neutral-100">
                  <span>{p.name} <span className="text-xs text-neutral-400">· {p.category}</span></span>
                  <span className={`text-xs ${DOM_COLOR[p.dominance]}`}>{p.dominance} · {p.noteCount} notes</span>
                </Link>
              </li>
            ))}
          </ul>
          <form onSubmit={submit} className="mt-4 flex gap-2">
            <input placeholder="New position" value={form.data.name} onChange={(e) => form.setData('name', e.target.value)} className="flex-1 rounded-lg border border-neutral-300 px-3 py-1.5 text-sm" />
            <button className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm hover:bg-neutral-50">Add</button>
          </form>
        </section>

        <section>
          <h2 className="text-sm font-medium uppercase tracking-wide text-neutral-400">Techniques (edges)</h2>
          <ul className="mt-3 space-y-1 text-sm">
            {techniques.map((t) => (
              <li key={t.id} className="rounded px-2 py-1.5 hover:bg-neutral-100">
                <span className="font-medium">{t.name}</span>{' '}
                <span className="text-xs text-neutral-400">{t.kind}</span>
                <div className="text-xs text-neutral-500">{t.from ?? '?'} → {t.to ?? 'finish'}</div>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </AppShell>
  )
}

// A navigable node-edge graph: positions are nodes laid out on a circle, techniques are
// directed edges between them (from → to). Clicking a node opens that position (Phase 10).
function TaxonomyGraph({ positions, techniques }: { positions: Position[]; techniques: Technique[] }) {
  const W = 720
  const H = 460
  const cx = W / 2
  const cy = H / 2
  const radius = Math.min(W, H) / 2 - 70

  // Place each position on a circle; index map by name so edges can resolve endpoints.
  const nodes = positions.map((p, i) => {
    const angle = (2 * Math.PI * i) / positions.length - Math.PI / 2
    return { ...p, x: cx + radius * Math.cos(angle), y: cy + radius * Math.sin(angle) }
  })
  const byName = new Map(nodes.map((n) => [n.name, n]))

  const edges = techniques
    .map((t) => ({ t, a: t.from ? byName.get(t.from) : undefined, b: t.to ? byName.get(t.to) : undefined }))
    .filter((e) => e.a && e.b && e.a !== e.b)

  return (
    <div className="mt-6 overflow-x-auto rounded-2xl border border-neutral-200 bg-white p-2">
      <svg viewBox={`0 0 ${W} ${H}`} className="mx-auto h-auto w-full max-w-3xl" role="img" aria-label="Position and technique graph">
        <defs>
          <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
            <path d="M0,0 L10,5 L0,10 z" fill="#d4d4d4" />
          </marker>
        </defs>

        {edges.map(({ t, a, b }) => {
          // Shorten the line so the arrowhead lands at the node edge, not its center.
          const dx = b!.x - a!.x
          const dy = b!.y - a!.y
          const len = Math.hypot(dx, dy) || 1
          const ux = dx / len
          const uy = dy / len
          const x1 = a!.x + ux * 24
          const y1 = a!.y + uy * 24
          const x2 = b!.x - ux * 26
          const y2 = b!.y - uy * 26
          return (
            <line key={t.id} x1={x1} y1={y1} x2={x2} y2={y2} stroke="#d4d4d4" strokeWidth={1.5} markerEnd="url(#arrow)">
              <title>{t.name}: {t.from} → {t.to}</title>
            </line>
          )
        })}

        {nodes.map((n) => (
          <g key={n.id} className="cursor-pointer" onClick={() => router.visit(`/positions/${n.id}`)}>
            <circle cx={n.x} cy={n.y} r={20} fill={NODE_FILL[n.dominance] ?? '#a3a3a3'} opacity={0.9} />
            <text x={n.x} y={n.y + 34} textAnchor="middle" className="fill-neutral-700 text-[11px]">{n.name}</text>
            <title>{n.name} · {n.category} · {n.noteCount} notes</title>
          </g>
        ))}
      </svg>
    </div>
  )
}
