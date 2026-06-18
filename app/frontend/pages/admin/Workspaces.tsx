import { Head } from '@inertiajs/react'
import AdminShell from '../../components/AdminShell'

interface Row { id: string; name: string; slug: string; members: number; owner: string | null; createdAt: string }

export default function AdminWorkspaces({ workspaces }: { workspaces: Row[] }) {
  return (
    <AdminShell>
      <Head title="Workspaces · Admin" />
      <h1 className="text-2xl font-semibold tracking-tight">Workspaces</h1>
      <table className="mt-6 w-full text-left text-sm">
        <thead className="text-xs uppercase text-neutral-500">
          <tr><th className="py-2">Name</th><th>Owner</th><th>Members</th></tr>
        </thead>
        <tbody className="divide-y divide-neutral-800">
          {workspaces.map((w) => (
            <tr key={w.id}>
              <td className="py-2">{w.name}</td>
              <td className="text-neutral-400">{w.owner ?? '—'}</td>
              <td>{w.members}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminShell>
  )
}
