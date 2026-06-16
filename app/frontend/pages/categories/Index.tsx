import { Head, router, useForm } from '@inertiajs/react'
import { useState, type FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Category {
  id: number
  name: string
  count: number
}

export default function CategoriesIndex({ categories }: { categories: Category[] }) {
  const form = useForm({ name: '' })

  const create = (e: FormEvent) => {
    e.preventDefault()
    if (!form.data.name.trim()) return
    form.post('/categories', { onSuccess: () => form.reset('name') })
  }

  return (
    <AppShell>
      <Head title="Categories · Pinpoint" />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Categories</h1>
          <p className="mt-1 text-sm text-neutral-500">Group notes by category. Rename, merge, or remove them here.</p>
        </div>
        <form onSubmit={create} className="flex gap-2">
          <input
            placeholder="New category"
            value={form.data.name}
            onChange={(e) => form.setData('name', e.target.value)}
            className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm focus:border-ember focus:outline-none"
          />
          <button className="rounded-lg bg-ember px-4 py-1.5 text-sm font-medium text-white hover:bg-amber-500">Add</button>
        </form>
      </div>

      {categories.length === 0 ? (
        <p className="mt-10 text-center text-sm text-neutral-400">No categories yet. Add one above.</p>
      ) : (
        <ul className="mt-6 divide-y divide-neutral-200 overflow-hidden rounded-2xl border border-neutral-200 bg-surface">
          {categories.map((category) => (
            <CategoryRow key={category.id} category={category} all={categories} />
          ))}
        </ul>
      )}
    </AppShell>
  )
}

function CategoryRow({ category, all }: { category: Category; all: Category[] }) {
  const [editing, setEditing] = useState(false)
  const [name, setName] = useState(category.name)
  const [merging, setMerging] = useState(false)

  const rename = () => {
    const next = name.trim()
    if (!next || next === category.name) return setEditing(false)
    router.patch(`/categories/${category.id}`, { name: next }, { onSuccess: () => setEditing(false) })
  }

  const remove = () => {
    if (confirm(`Delete the category “${category.name}”? Its notes will become uncategorised.`)) {
      router.delete(`/categories/${category.id}`)
    }
  }

  const mergeTargets = all.filter((c) => c.id !== category.id)

  return (
    <li className="flex items-center gap-3 px-4 py-3">
      {editing ? (
        <input
          autoFocus
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') rename()
            if (e.key === 'Escape') setEditing(false)
          }}
          onBlur={rename}
          className="rounded border border-neutral-300 px-2 py-1 text-sm focus:border-ember focus:outline-none"
        />
      ) : (
        <button onClick={() => setEditing(true)} className="rounded bg-neutral-100 px-3 py-1 text-sm font-medium text-neutral-700 hover:bg-neutral-200">
          {category.name}
        </button>
      )}

      <span className="text-xs text-neutral-400">{category.count} {category.count === 1 ? 'note' : 'notes'}</span>

      <div className="ml-auto flex items-center gap-2">
        {merging && mergeTargets.length > 0 ? (
          <select
            autoFocus
            defaultValue=""
            onChange={(e) => e.target.value && router.post(`/categories/${category.id}/merge`, { target_id: Number(e.target.value) }, { onSuccess: () => setMerging(false) })}
            onBlur={() => setMerging(false)}
            className="rounded border border-neutral-300 px-2 py-1 text-sm"
          >
            <option value="" disabled>Merge into…</option>
            {mergeTargets.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        ) : (
          <button onClick={() => setMerging(true)} disabled={mergeTargets.length === 0} className="text-xs text-neutral-500 hover:text-neutral-900 disabled:opacity-40">
            Merge
          </button>
        )}
        <button onClick={remove} className="text-xs text-red-500 hover:text-red-700">Delete</button>
      </div>
    </li>
  )
}
