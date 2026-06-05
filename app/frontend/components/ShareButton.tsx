import { router } from '@inertiajs/react'
import { useState } from 'react'

interface ShareInfo { id: number; token: string }

// Creates / shows / revokes a share link for a content object.
export default function ShareButton({
  shareableType,
  shareableId,
  share,
}: {
  shareableType: string
  shareableId: number | string
  share: ShareInfo | null
}) {
  const [copied, setCopied] = useState(false)

  const createShare = () =>
    router.post('/shares', { shareable_type: shareableType, shareable_id: shareableId, visibility: 'unlisted' })
  const revoke = () => share && router.delete(`/shares/${share.id}`)

  if (!share) {
    return (
      <button onClick={createShare} className="rounded-lg border border-neutral-300 px-3 py-1.5 text-sm hover:bg-neutral-50">
        Share
      </button>
    )
  }

  const url = `${window.location.origin}/s/${share.token}`
  return (
    <div className="flex items-center gap-2 text-sm">
      <input readOnly value={url} className="w-64 rounded-lg border border-neutral-300 px-2 py-1.5 text-xs text-neutral-600" />
      <button
        onClick={() => { navigator.clipboard.writeText(url); setCopied(true); setTimeout(() => setCopied(false), 1500) }}
        className="rounded-lg bg-amber-400 px-3 py-1.5 text-xs font-medium text-neutral-950 hover:bg-amber-300"
      >
        {copied ? 'Copied!' : 'Copy link'}
      </button>
      <button onClick={revoke} className="text-xs text-neutral-400 hover:text-red-500">Unshare</button>
    </div>
  )
}
