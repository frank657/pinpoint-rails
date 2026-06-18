import { Head, Link, useForm } from '@inertiajs/react'
import { useState, type FormEvent } from 'react'
import AppShell from '../../components/AppShell'
import RichTextEditor from '../../components/RichTextEditor'

interface Category {
  id: string
  name: string
}

export default function NewNote({ categories, tags }: { categories: Category[]; tags: string[] }) {
  const [body, setBody] = useState('')
  const form = useForm({
    note_type: 'rich_text',
    title: '',
    body: '',
    category_ids: [] as string[],
    tag_names: '',
  })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((d) => ({ ...d, body }))
    form.post('/notes')
  }

  return (
    <AppShell>
      <Head title="New note · Pinpoint" />
      <Link href="/notes" className="text-sm text-neutral-500 hover:text-neutral-900">← Notes</Link>
      <h1 className="mt-2 text-2xl font-semibold tracking-tight">New rich-text note</h1>

      <form onSubmit={submit} className="mt-6 max-w-2xl space-y-4">
        <input
          placeholder="Title"
          value={form.data.title}
          onChange={(e) => form.setData('title', e.target.value)}
          className="w-full rounded-lg border border-neutral-300 px-3 py-2 focus:border-amber-400 focus:outline-none"
        />
        <RichTextEditor value={body} onChange={setBody} placeholder="Write anything — paste images, format text…" />
        <div className="flex gap-2">
          <select
            multiple
            value={form.data.category_ids.map(String)}
            onChange={(e) => form.setData('category_ids', Array.from(e.target.selectedOptions, (o) => o.value))}
            className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm"
            aria-label="Categories"
          >
            {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
          <input
            placeholder="tags, comma…"
            list="tag-options"
            value={form.data.tag_names}
            onChange={(e) => form.setData('tag_names', e.target.value)}
            className="flex-1 rounded-lg border border-neutral-300 px-3 py-2 text-sm focus:border-amber-400 focus:outline-none"
          />
          <datalist id="tag-options">{tags.map((t) => <option key={t} value={t} />)}</datalist>
        </div>
        <button type="submit" disabled={form.processing} className="rounded-lg bg-amber-400 px-5 py-2.5 font-medium text-neutral-950 hover:bg-amber-300 disabled:opacity-50">
          Save note
        </button>
      </form>
    </AppShell>
  )
}
