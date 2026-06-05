import { useForm, Link } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthCard, { fieldClass, buttonClass, labelClass } from '../../components/AuthCard'

export default function SignIn() {
  const form = useForm({ email: '', password: '', remember_me: false })
  const { data, setData, processing, errors } = form

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((d) => ({ user: d }))
    form.post('/users/sign_in')
  }

  return (
    <AuthCard title="Sign in" subtitle="Welcome back to your video learning.">
      <form onSubmit={submit} className="space-y-4">
        <div>
          <label className={labelClass} htmlFor="email">Email</label>
          <input
            id="email" type="email" autoComplete="email" required
            className={`${fieldClass} mt-1`}
            value={data.email}
            onChange={(e) => setData('email', e.target.value)}
          />
          {errors.email && <p className="mt-1 text-xs text-red-400">{errors.email}</p>}
        </div>
        <div>
          <label className={labelClass} htmlFor="password">Password</label>
          <input
            id="password" type="password" autoComplete="current-password" required
            className={`${fieldClass} mt-1`}
            value={data.password}
            onChange={(e) => setData('password', e.target.value)}
          />
          {errors.password && <p className="mt-1 text-xs text-red-400">{errors.password}</p>}
        </div>
        <label className="flex items-center gap-2 text-sm text-neutral-400">
          <input
            type="checkbox"
            checked={data.remember_me}
            onChange={(e) => setData('remember_me', e.target.checked)}
          />
          Remember me
        </label>
        <button type="submit" className={buttonClass} disabled={processing}>Sign in</button>
      </form>
      <div className="mt-6 flex justify-between text-sm text-neutral-400">
        <Link href="/users/password/new" className="hover:text-amber-400">Forgot password?</Link>
        <Link href="/users/sign_up" className="hover:text-amber-400">Create account</Link>
      </div>
    </AuthCard>
  )
}
