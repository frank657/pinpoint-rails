import { Head, router } from '@inertiajs/react'
import { useState } from 'react'
import AppShell, { type Workspace } from '../../components/AppShell'

export default function WorkspacesIndex({ workspaces }: { workspaces: Workspace[] }) {
  const [editing, setEditing] = useState<number | null>(null)
  const [name, setName] = useState('')

  const rename = (id: number) => {
    router.patch(`/workspaces/${id}`, { name }, { onSuccess: () => setEditing(null) })
  }

  const destroy = (id: number) => {
    if (confirm('Delete this workspace? Its content will be removed.')) {
      router.delete(`/workspaces/${id}`)
    }
  }

  return (
    <AppShell>
      <Head title="Workspaces · Pinpoint" />
      <h1 className="text-2xl font-semibold tracking-tight">Workspaces</h1>
      <ul className="mt-6 divide-y divide-neutral-200 rounded-xl border border-neutral-200 bg-white">
        {workspaces.map((w) => (
          <li key={w.id} className="flex items-center justify-between px-4 py-3">
            {editing === w.id ? (
              <input
                autoFocus
                defaultValue={w.name}
                onChange={(e) => setName(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && rename(w.id)}
                className="rounded border border-neutral-300 px-2 py-1 text-sm focus:border-amber-400 focus:outline-none"
              />
            ) : (
              <span className="text-sm">{w.name}</span>
            )}
            <div className="flex gap-3 text-sm text-neutral-500">
              {editing === w.id ? (
                <button onClick={() => rename(w.id)} className="hover:text-amber-600">Save</button>
              ) : (
                <button onClick={() => { setEditing(w.id); setName(w.name) }} className="hover:text-neutral-900">
                  Rename
                </button>
              )}
              <button onClick={() => destroy(w.id)} className="hover:text-red-600">Delete</button>
            </div>
          </li>
        ))}
      </ul>
    </AppShell>
  )
}
