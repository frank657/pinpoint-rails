import { usePage, router, Link } from '@inertiajs/react'
import { useState, useEffect, type ReactNode, type ComponentType } from 'react'
import {
  House,
  FilmStrip,
  MagnifyingGlass,
  Note,
  TreeStructure,
  Tag,
  UsersThree,
  CaretDown,
} from '@phosphor-icons/react'
import SearchSpotlight from './SearchSpotlight'

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

type PhosphorIcon = ComponentType<{ size?: number; weight?: 'thin' | 'light' | 'regular' | 'bold' | 'fill' | 'duotone'; className?: string }>

const NAV: { group: string; items: { label: string; href: string; icon: PhosphorIcon }[] }[] = [
  {
    group: 'Workspace',
    items: [
      { label: 'Home',      href: '/',          icon: House },
      { label: 'Library',   href: '/videos',    icon: FilmStrip },
    ],
  },
  {
    group: 'Learning',
    items: [
      { label: 'Notes',     href: '/notes',     icon: Note },
      { label: 'Tags',      href: '/tags',      icon: Tag },
      { label: 'Athletes',  href: '/athletes',  icon: UsersThree },
      { label: 'Positions', href: '/positions', icon: TreeStructure },
    ],
  },
]

export default function AppShell({ children }: { children: ReactNode }) {
  const page = usePage<AppSharedProps>()
  const { currentUser, currentWorkspace, workspaces, flash } = page.props
  const url = page.url

  const [wsOpen, setWsOpen] = useState(false)
  const [creating, setCreating] = useState(false)
  const [name, setName] = useState('')
  const [searchOpen, setSearchOpen] = useState(false)

  // ⌘K / Ctrl+K opens the spotlight from anywhere
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setSearchOpen((v) => !v)
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  const switchTo = (id: number) => {
    setWsOpen(false)
    router.post(`/workspaces/${id}/switch`)
  }
  const createWorkspace = () => {
    if (!name.trim()) return
    router.post('/workspaces', { name }, {
      onSuccess: () => { setCreating(false); setName(''); setWsOpen(false) },
    })
  }

  const isActive = (href: string) =>
    href === '/' ? url === '/' : url.startsWith(href)

  return (
    <div className="min-h-screen bg-neutral-100 font-sans text-neutral-900">
      {/* top bar */}
      <header className="sticky top-0 z-40 flex h-14 items-center gap-4 border-b border-neutral-200 bg-neutral-100/90 px-5 backdrop-blur">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="h-3 w-3 rounded-full bg-ember shadow-[0_0_14px_rgba(226,87,31,0.45)]" />
          <span className="font-display text-xl font-semibold tracking-tight">Pinpoint</span>
        </Link>
        <button
          onClick={() => setSearchOpen(true)}
          className="mx-auto hidden w-full max-w-lg items-center gap-2 rounded-full border border-neutral-200 bg-surface px-4 py-2 text-sm text-neutral-400 transition hover:border-neutral-300 hover:text-neutral-600 sm:flex"
        >
          <MagnifyingGlass size={15} className="flex-none" />
          <span className="flex-1 text-left">Search notes…</span>
          <kbd className="ml-auto flex-none rounded border border-neutral-200 px-1.5 py-0.5 text-[11px]">⌘K</kbd>
        </button>
        <div className="ml-auto flex items-center gap-3">
          <span className="grid h-8 w-8 place-items-center rounded-full bg-gradient-to-br from-ember to-gold text-xs font-bold text-white">
            {currentUser?.email?.[0]?.toUpperCase() ?? 'P'}
          </span>
        </div>
      </header>

      <div className="grid grid-cols-[220px_1fr] items-start max-lg:grid-cols-1">
        {/* sidebar */}
        <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] flex-col gap-1 border-r border-neutral-200 p-3 lg:flex">
          {/* workspace switcher */}
          <div className="relative mb-2">
            <button
              onClick={() => setWsOpen((v) => !v)}
              className="flex w-full items-center gap-2.5 rounded-xl border border-neutral-200 bg-surface px-3 py-2.5 text-left text-sm"
            >
              <span className="h-5 w-5 flex-none rounded-md bg-gradient-to-br from-ember via-gold to-teal" />
              <span className="truncate">{currentWorkspace?.name ?? 'No workspace'}</span>
              <CaretDown size={13} weight="bold" className="ml-auto flex-none text-neutral-400" />
            </button>
            {wsOpen && (
              <div className="absolute left-0 right-0 z-20 mt-1.5 rounded-xl border border-neutral-200 bg-surface p-1 shadow-lg">
                {workspaces.map((w) => (
                  <button
                    key={w.id}
                    onClick={() => switchTo(w.id)}
                    className={`flex w-full items-center justify-between rounded-lg px-3 py-2 text-left text-sm hover:bg-neutral-100 ${
                      w.id === currentWorkspace?.id ? 'font-medium text-amber-600' : 'text-neutral-700'
                    }`}
                  >
                    {w.name}
                    {w.id === currentWorkspace?.id && <span className="text-xs">current</span>}
                  </button>
                ))}
                <div className="my-1 border-t border-neutral-100" />
                {creating ? (
                  <div className="p-1.5">
                    <input
                      autoFocus
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && createWorkspace()}
                      placeholder="Workspace name"
                      className="w-full rounded-lg border border-neutral-300 px-2 py-1.5 text-sm focus:border-ember focus:outline-none"
                    />
                    <div className="mt-2 flex gap-2">
                      <button onClick={createWorkspace} className="flex-1 rounded-lg bg-ember px-2 py-1 text-sm font-medium text-white hover:bg-amber-500">Create</button>
                      <button onClick={() => setCreating(false)} className="rounded-lg px-2 py-1 text-sm text-neutral-500 hover:bg-neutral-100">Cancel</button>
                    </div>
                  </div>
                ) : (
                  <button onClick={() => setCreating(true)} className="w-full rounded-lg px-3 py-2 text-left text-sm text-neutral-700 hover:bg-neutral-100">+ New workspace</button>
                )}
              </div>
            )}
          </div>

          {/* nav groups */}
          <nav className="flex flex-1 flex-col gap-0.5 overflow-y-auto">
            {NAV.map((sec) => (
              <div key={sec.group}>
                <p className="mb-1 mt-3 px-3 text-[10.5px] font-semibold uppercase tracking-[0.16em] text-neutral-400">{sec.group}</p>
                {sec.items.map((it) => (
                  <Link
                    key={it.label}
                    href={it.href}
                    className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition ${
                      isActive(it.href) ? 'bg-neutral-200/70 text-neutral-900' : 'text-neutral-500 hover:bg-neutral-200/50 hover:text-neutral-900'
                    }`}
                  >
                    <it.icon
                      size={17}
                      weight={isActive(it.href) ? 'bold' : 'regular'}
                      className="flex-none"
                    />
                    {it.label}
                  </Link>
                ))}
              </div>
            ))}
          </nav>

          <div className="mt-2 flex items-center justify-between border-t border-neutral-200 px-2 pt-3 text-xs text-neutral-400">
            <span className="truncate">{currentUser?.email}</span>
            <button onClick={() => router.delete('/users/sign_out')} className="hover:text-neutral-900">Sign out</button>
          </div>
        </aside>

        {/* main */}
        <div className="min-w-0">
          {(flash?.notice || flash?.alert) && (
            <div className={`px-6 py-2 text-sm ${flash.alert ? 'bg-red-50 text-red-700' : 'bg-teal/10 text-teal'}`}>
              <div className="mx-auto max-w-5xl">{flash.alert ?? flash.notice}</div>
            </div>
          )}
          <main className="mx-auto max-w-6xl px-6 py-9 lg:px-9">{children}</main>
        </div>
      </div>

      <SearchSpotlight open={searchOpen} onClose={() => setSearchOpen(false)} />
    </div>
  )
}
