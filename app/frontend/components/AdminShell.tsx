import { Link, router, usePage } from '@inertiajs/react'
import type { ReactNode } from 'react'

export default function AdminShell({ children }: { children: ReactNode }) {
  const { currentUser } = usePage<{ currentUser: { email: string } | null; [k: string]: unknown }>().props
  const nav = [
    ['Dashboard', '/'],
    ['Users', '/users'],
    ['Workspaces', '/workspaces'],
    ['Videos', '/videos'],
  ]
  return (
    <div className="min-h-screen bg-neutral-900 text-neutral-100">
      <header className="border-b border-neutral-800">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-3">
          <div className="flex items-center gap-4">
            <span className="font-semibold tracking-tight">Pinpoint Admin</span>
            <nav className="flex gap-1 text-sm">
              {nav.map(([label, href]) => (
                <Link key={href} href={href} className="rounded px-2 py-1 text-neutral-400 hover:bg-neutral-800 hover:text-neutral-100">
                  {label}
                </Link>
              ))}
            </nav>
          </div>
          <div className="flex items-center gap-3 text-sm text-neutral-400">
            <span>{currentUser?.email}</span>
            <button onClick={() => router.delete('/users/sign_out')} className="rounded px-2 py-1 hover:bg-neutral-800">Sign out</button>
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-6 py-10">{children}</main>
    </div>
  )
}
