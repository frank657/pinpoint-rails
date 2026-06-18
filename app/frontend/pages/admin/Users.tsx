import { Head, router, useForm } from '@inertiajs/react'
import AdminShell from '../../components/AdminShell'

interface AdminUser { id: string; email: string; admin: boolean; workspaceCount: number; createdAt: string }

export default function AdminUsers({ users, q }: { users: AdminUser[]; q: string | null }) {
  const form = useForm({ q: q ?? '' })
  const search = () => router.get('/users', { q: form.data.q }, { preserveState: true })

  return (
    <AdminShell>
      <Head title="Users · Admin" />
      <h1 className="text-2xl font-semibold tracking-tight">Users</h1>
      <div className="mt-4 flex gap-2">
        <input
          value={form.data.q}
          onChange={(e) => form.setData('q', e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && search()}
          placeholder="Search email…"
          className="flex-1 rounded-lg border border-neutral-700 bg-neutral-800 px-3 py-2 text-sm"
        />
        <button onClick={search} className="rounded-lg border border-neutral-700 px-4 py-2 text-sm hover:bg-neutral-800">Search</button>
      </div>
      <table className="mt-6 w-full text-left text-sm">
        <thead className="text-xs uppercase text-neutral-500">
          <tr><th className="py-2">Email</th><th>Workspaces</th><th>Admin</th><th></th></tr>
        </thead>
        <tbody className="divide-y divide-neutral-800">
          {users.map((u) => (
            <tr key={u.id}>
              <td className="py-2">{u.email}</td>
              <td>{u.workspaceCount}</td>
              <td>{u.admin ? '✓' : '—'}</td>
              <td className="text-right">
                <button
                  onClick={() => router.patch(`/users/${u.id}`, { admin: !u.admin })}
                  className="rounded px-2 py-1 text-xs text-amber-400 hover:bg-neutral-800"
                >
                  {u.admin ? 'Revoke admin' : 'Make admin'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminShell>
  )
}
