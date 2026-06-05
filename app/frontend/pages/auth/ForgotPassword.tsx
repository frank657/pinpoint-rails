import { useForm, Link } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthCard, { fieldClass, buttonClass, labelClass } from '../../components/AuthCard'

export default function ForgotPassword() {
  const form = useForm({ email: '' })
  const { data, setData, processing, errors } = form

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((d) => ({ user: d }))
    form.post('/users/password')
  }

  return (
    <AuthCard title="Reset password" subtitle="We'll email you a reset link.">
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
        <button type="submit" className={buttonClass} disabled={processing}>Send reset link</button>
      </form>
      <div className="mt-6 text-center text-sm text-neutral-400">
        <Link href="/users/sign_in" className="hover:text-amber-400">Back to sign in</Link>
      </div>
    </AuthCard>
  )
}
