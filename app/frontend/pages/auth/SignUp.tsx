import { useForm, Link } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthCard, { fieldClass, buttonClass, labelClass } from '../../components/AuthCard'

export default function SignUp() {
  const form = useForm({ email: '', password: '', password_confirmation: '' })
  const { data, setData, processing, errors } = form

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((d) => ({ user: d }))
    form.post('/users')
  }

  return (
    <AuthCard title="Create your account" subtitle="Start pinning what you learn.">
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
            id="password" type="password" autoComplete="new-password" required
            className={`${fieldClass} mt-1`}
            value={data.password}
            onChange={(e) => setData('password', e.target.value)}
          />
          {errors.password && <p className="mt-1 text-xs text-red-400">{errors.password}</p>}
        </div>
        <div>
          <label className={labelClass} htmlFor="password_confirmation">Confirm password</label>
          <input
            id="password_confirmation" type="password" autoComplete="new-password" required
            className={`${fieldClass} mt-1`}
            value={data.password_confirmation}
            onChange={(e) => setData('password_confirmation', e.target.value)}
          />
          {errors.password_confirmation && (
            <p className="mt-1 text-xs text-red-400">{errors.password_confirmation}</p>
          )}
        </div>
        <button type="submit" className={buttonClass} disabled={processing}>Create account</button>
      </form>
      <div className="mt-6 text-center text-sm text-neutral-400">
        Already have an account?{' '}
        <Link href="/users/sign_in" className="hover:text-amber-400">Sign in</Link>
      </div>
    </AuthCard>
  )
}
