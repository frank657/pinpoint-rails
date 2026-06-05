import { Head, router, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Folder { id: number; name: string; parentId: number | null; position: number }

export default function FoldersIndex({ folders }: { folders: Folder[] }) {
  const form = useForm({ name: '', parent_id: '' as string | number })
  const submit = (e: FormEvent) => { e.preventDefault(); form.post('/folders', { onSuccess: () => form.reset() }) }

  const roots = folders.filter((f) => !f.parentId)
  const childrenOf = (id: number) => folders.filter((f) => f.parentId === id)

  const renderNode = (folder: Folder, depth: number) => (
    <div key={folder.id}>
      <div className="flex items-center justify-between rounded px-2 py-1.5 hover:bg-neutral-50" style={{ paddingLeft: `${depth * 16 + 8}px` }}>
        <span className="text-sm">📁 {folder.name}</span>
        <button onClick={() => router.delete(`/folders/${folder.id}`)} className="text-xs text-neutral-300 hover:text-red-500">Delete</button>
      </div>
      {childrenOf(folder.id).map((c) => renderNode(c, depth + 1))}
    </div>
  )

  return (
    <AppShell>
      <Head title="Folders · Pinpoint" />
      <h1 className="text-2xl font-semibold tracking-tight">Folders</h1>
      <p className="mt-1 text-sm text-neutral-500">Organize your notes.</p>
      <form onSubmit={submit} className="mt-4 flex gap-2">
        <input
          placeholder="New folder name"
          value={form.data.name}
          onChange={(e) => form.setData('name', e.target.value)}
          className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
        />
        <select value={form.data.parent_id} onChange={(e) => form.setData('parent_id', e.target.value)} className="rounded-lg border border-neutral-300 px-3 py-2 text-sm">
          <option value="">Top level</option>
          {folders.map((f) => <option key={f.id} value={f.id}>{f.name}</option>)}
        </select>
        <button className="rounded-lg bg-amber-400 px-4 py-2 text-sm font-medium text-neutral-950 hover:bg-amber-300">Create</button>
      </form>
      <div className="mt-6 rounded-xl border border-neutral-200 bg-white p-2">
        {roots.length === 0 ? (
          <p className="p-6 text-center text-sm text-neutral-400">No folders yet.</p>
        ) : (
          roots.map((f) => renderNode(f, 0))
        )}
      </div>
    </AppShell>
  )
}
