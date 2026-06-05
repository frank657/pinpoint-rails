import { useEffect, useRef } from 'react'
import 'trix'
import 'trix/dist/trix.css'
// Wires Trix attachment uploads to Active Storage direct upload (posts to
// /rails/active_storage/direct_uploads, CSRF via the layout's csrf-token meta).
import '@rails/actiontext'

// A controlled React wrapper around <trix-editor>. The editor's HTML is mirrored into a
// hidden field and surfaced via onChange so callers can submit it as the note body.
export default function RichTextEditor({
  value,
  onChange,
  placeholder,
}: {
  value: string
  onChange: (html: string) => void
  placeholder?: string
}) {
  const inputRef = useRef<HTMLInputElement>(null)
  const editorRef = useRef<HTMLElement>(null)

  // Initialize the editor's content once it's connected.
  useEffect(() => {
    const editor = editorRef.current as (HTMLElement & { editor?: unknown }) | null
    if (editor && inputRef.current && inputRef.current.value !== value) {
      inputRef.current.value = value
    }
  }, [value])

  useEffect(() => {
    const el = editorRef.current
    if (!el) return
    const handler = () => onChange(inputRef.current?.value ?? '')
    el.addEventListener('trix-change', handler)
    return () => el.removeEventListener('trix-change', handler)
  }, [onChange])

  return (
    <div className="rounded-lg border border-neutral-300 focus-within:border-amber-400">
      <input type="hidden" ref={inputRef} id="rich-text-input" defaultValue={value} />
      {/* @ts-expect-error trix-editor is a custom element */}
      <trix-editor ref={editorRef} input="rich-text-input" placeholder={placeholder} class="trix-content block p-3" />
    </div>
  )
}
