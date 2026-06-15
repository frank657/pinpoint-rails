import { Head, router, useForm } from '@inertiajs/react'
import { useState, type FormEvent } from 'react'
import AppShell from '../../components/AppShell'

interface Tag {
  id: number
  name: string
  count: number
}

export default function TagsIndex({ tags }: { tags: Tag[] }) {
  const form = useForm({ name: '' })

  const create = (e: FormEvent) => {
    e.preventDefault()
    if (!form.data.name.trim()) return
    form.post('/tags', { onSuccess: () => form.reset('name') })
  }

  return (
    <AppShell>
      <Head title="Tags · Pinpoint" />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Tags</h1>
          <p className="mt-1 text-sm text-neutral-500">
            Free-form labels applied to notes and videos. Rename, merge, or remove them here.
          </p>
        </div>
        <form onSubmit={create} className="flex gap-2">
          <input
            placeholder="New tag"
            value={form.data.name}
            onChange={(e) => form.setData('name', e.target.value)}
            className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm focus:border-ember focus:outline-none"
          />
          <button className="rounded-lg bg-ember px-4 py-1.5 text-sm font-medium text-white hover:bg-amber-500">
            Add
          </button>
        </form>
      </div>

      {tags.length === 0 ? (
        <p className="mt-10 text-center text-sm text-neutral-400">
          No tags yet. Tag a note or a video, or add one above.
        </p>
      ) : (
        <ul className="mt-6 divide-y divide-neutral-200 overflow-hidden rounded-2xl border border-neutral-200 bg-surface">
          {tags.map((tag) => (
            <TagRow key={tag.id} tag={tag} allTags={tags} />
          ))}
        </ul>
      )}
    </AppShell>
  )
}

function TagRow({ tag, allTags }: { tag: Tag; allTags: Tag[] }) {
  const [editing, setEditing] = useState(false)
  const [name, setName] = useState(tag.name)
  const [merging, setMerging] = useState(false)

  const rename = () => {
    const next = name.trim()
    if (!next || next === tag.name) return setEditing(false)
    router.patch(`/tags/${tag.id}`, { name: next }, { onSuccess: () => setEditing(false) })
  }

  const remove = () => {
    if (confirm(`Delete the tag “${tag.name}”? This removes it from all notes and videos.`)) {
      router.delete(`/tags/${tag.id}`)
    }
  }

  const mergeInto = (targetId: number) => {
    router.post(`/tags/${tag.id}/merge`, { target_id: targetId }, { onSuccess: () => setMerging(false) })
  }

  const mergeTargets = allTags.filter((t) => t.id !== tag.id)

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
        <button
          onClick={() => setEditing(true)}
          className="rounded-full bg-amber-100 px-3 py-1 text-sm font-medium text-amber-700 hover:bg-amber-200"
        >
          #{tag.name}
        </button>
      )}

      <span className="text-xs text-neutral-400">
        {tag.count} {tag.count === 1 ? 'use' : 'uses'}
      </span>

      <div className="ml-auto flex items-center gap-2">
        {merging && mergeTargets.length > 0 ? (
          <select
            autoFocus
            defaultValue=""
            onChange={(e) => e.target.value && mergeInto(Number(e.target.value))}
            onBlur={() => setMerging(false)}
            className="rounded border border-neutral-300 px-2 py-1 text-sm"
          >
            <option value="" disabled>
              Merge into…
            </option>
            {mergeTargets.map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
              </option>
            ))}
          </select>
        ) : (
          <button
            onClick={() => setMerging(true)}
            disabled={mergeTargets.length === 0}
            className="text-xs text-neutral-500 hover:text-neutral-900 disabled:opacity-40"
          >
            Merge
          </button>
        )}
        <button onClick={remove} className="text-xs text-red-500 hover:text-red-700">
          Delete
        </button>
      </div>
    </li>
  )
}
