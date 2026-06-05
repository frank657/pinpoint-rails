import { usePage, router, Link } from '@inertiajs/react'
import { useState, type ReactNode } from 'react'

export interface Workspace {
  id: number
  name: string
  slug: string
}

export interface AppSharedProps {
  currentUser: { id: number; email: string; admin: boolean } | null
  currentWorkspace: Workspace | null
  workspaces: Workspace[]
  flash: { notice: string | null; alert: string | null }
  [key: string]: unknown
}

export default function AppShell({ children }: { children: ReactNode }) {
  const { currentUser, currentWorkspace, workspaces, flash } = usePage<AppSharedProps>().props
  const [menuOpen, setMenuOpen] = useState(false)
  const [creating, setCreating] = useState(false)
  const [name, setName] = useState('')

  const switchTo = (id: number) => {
    setMenuOpen(false)
    router.post(`/workspaces/${id}/switch`)
  }

  const createWorkspace = () => {
    if (!name.trim()) return
    router.post('/workspaces', { name }, {
      onSuccess: () => { setCreating(false); setName(''); setMenuOpen(false) },
    })
  }

  return (
    <div className="min-h-screen bg-neutral-50 text-neutral-900">
      <header className="border-b border-neutral-200 bg-white">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-6 py-3">
          <div className="flex items-center gap-3">
            <span className="font-semibold tracking-tight">Pinpoint</span>

            <div className="relative">
              <button
                onClick={() => setMenuOpen((v) => !v)}
                className="rounded-full bg-neutral-100 px-3 py-1 text-sm text-neutral-700 hover:bg-neutral-200"
              >
                {currentWorkspace?.name ?? 'No workspace'} ▾
              </button>

              {menuOpen && (
                <div className="absolute left-0 z-10 mt-2 w-64 rounded-lg border border-neutral-200 bg-white p-1 shadow-lg">
                  <p className="px-3 py-1.5 text-xs uppercase tracking-wide text-neutral-400">
                    Workspaces
                  </p>
                  {workspaces.map((w) => (
                    <button
                      key={w.id}
                      onClick={() => switchTo(w.id)}
                      className={`flex w-full items-center justify-between rounded px-3 py-2 text-left text-sm hover:bg-neutral-100 ${
                        w.id === currentWorkspace?.id ? 'font-medium text-amber-600' : 'text-neutral-700'
                      }`}
                    >
                      {w.name}
                      {w.id === currentWorkspace?.id && <span className="text-xs">current</span>}
                    </button>
                  ))}

                  <div className="my-1 border-t border-neutral-100" />

                  {creating ? (
                    <div className="p-2">
                      <input
                        autoFocus
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && createWorkspace()}
                        placeholder="Workspace name"
                        className="w-full rounded border border-neutral-300 px-2 py-1.5 text-sm focus:border-amber-400 focus:outline-none"
                      />
                      <div className="mt-2 flex gap-2">
                        <button
                          onClick={createWorkspace}
                          className="flex-1 rounded bg-amber-400 px-2 py-1 text-sm font-medium text-neutral-950 hover:bg-amber-300"
                        >
                          Create
                        </button>
                        <button
                          onClick={() => setCreating(false)}
                          className="rounded px-2 py-1 text-sm text-neutral-500 hover:bg-neutral-100"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    <button
                      onClick={() => setCreating(true)}
                      className="w-full rounded px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-100"
                    >
                      + New workspace
                    </button>
                  )}
                </div>
              )}
            </div>
            <nav className="ml-2 flex items-center gap-1 text-sm">
              <Link href="/videos" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Videos</Link>
              <Link href="/courses" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Courses</Link>
              <Link href="/curriculums" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Curriculums</Link>
              <Link href="/notes" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Notes</Link>
              <Link href="/folders" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Folders</Link>
              <Link href="/review" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Review</Link>
              <Link href="/training_sessions" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Training</Link>
              <Link href="/positions" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Positions</Link>
              <Link href="/search" className="rounded px-2 py-1 text-neutral-600 hover:bg-neutral-100">Search</Link>
            </nav>
          </div>

          <div className="flex items-center gap-3 text-sm text-neutral-500">
            <span>{currentUser?.email}</span>
            <button
              onClick={() => router.delete('/users/sign_out')}
              className="rounded px-2 py-1 hover:bg-neutral-100 hover:text-neutral-900"
            >
              Sign out
            </button>
          </div>
        </div>
      </header>

      {(flash?.notice || flash?.alert) && (
        <div
          className={`px-6 py-2 text-sm ${
            flash.alert ? 'bg-red-50 text-red-700' : 'bg-emerald-50 text-emerald-700'
          }`}
        >
          <div className="mx-auto max-w-5xl">{flash.alert ?? flash.notice}</div>
        </div>
      )}

      <main className="mx-auto max-w-5xl px-6 py-12">{children}</main>
    </div>
  )
}
