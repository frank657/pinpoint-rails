import { Head } from '@inertiajs/react'
import AdminShell from '../../components/AdminShell'

export default function AdminDashboard({ stats }: { stats: Record<string, number> }) {
  return (
    <AdminShell>
      <Head title="Pinpoint Admin" />
      <h1 className="text-2xl font-semibold tracking-tight">Overview</h1>
      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {Object.entries(stats).map(([key, value]) => (
          <div key={key} className="rounded-xl border border-neutral-800 bg-neutral-800/40 p-4">
            <p className="text-2xl font-semibold">{value}</p>
            <p className="mt-1 text-xs uppercase tracking-wide text-neutral-400">{key}</p>
          </div>
        ))}
      </div>
    </AdminShell>
  )
}
