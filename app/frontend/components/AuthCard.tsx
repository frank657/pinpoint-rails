import { Head, usePage } from '@inertiajs/react'
import type { ReactNode } from 'react'

interface SharedProps {
  flash: { notice: string | null; alert: string | null }
  [key: string]: unknown
}

export default function AuthCard({
  title,
  subtitle,
  children,
}: {
  title: string
  subtitle?: string
  children: ReactNode
}) {
  const { flash } = usePage<SharedProps>().props

  return (
    <>
      <Head title={`${title} · Pinpoint`} />
      <main className="flex min-h-screen items-center justify-center bg-neutral-950 px-4 text-neutral-100">
        <div className="w-full max-w-sm">
          <p className="text-center font-mono text-sm uppercase tracking-[0.3em] text-amber-400">
            Pinpoint
          </p>
          <h1 className="mt-6 text-center text-2xl font-semibold">{title}</h1>
          {subtitle && <p className="mt-2 text-center text-sm text-neutral-400">{subtitle}</p>}

          {flash?.alert && (
            <div className="mt-6 rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300">
              {flash.alert}
            </div>
          )}
          {flash?.notice && (
            <div className="mt-6 rounded-lg border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-300">
              {flash.notice}
            </div>
          )}

          <div className="mt-8">{children}</div>
        </div>
      </main>
    </>
  )
}

export const fieldClass =
  'w-full rounded-lg border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-100 placeholder-neutral-500 focus:border-amber-400 focus:outline-none'

export const buttonClass =
  'w-full rounded-lg bg-amber-400 px-4 py-2.5 font-medium text-neutral-950 transition hover:bg-amber-300 disabled:opacity-50'

export const labelClass = 'block text-sm text-neutral-300'
