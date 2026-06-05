import { useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthCard, { fieldClass, buttonClass, labelClass } from '../../components/AuthCard'

export default function ResetPassword({ resetPasswordToken }: { resetPasswordToken: string }) {
  const form = useForm({
    reset_password_token: resetPasswordToken,
    password: '',
    password_confirmation: '',
  })
  const { data, setData, processing, errors } = form

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((d) => ({ user: d }))
    form.put('/users/password')
  }

  return (
    <AuthCard title="Choose a new password">
      <form onSubmit={submit} className="space-y-4">
        <div>
          <label className={labelClass} htmlFor="password">New password</label>
          <input
            id="password" type="password" autoComplete="new-password" required
            className={`${fieldClass} mt-1`}
            value={data.password}
            onChange={(e) => setData('password', e.target.value)}
          />
          {errors.password && <p className="mt-1 text-xs text-red-400">{errors.password}</p>}
        </div>
        <div>
          <label className={labelClass} htmlFor="password_confirmation">Confirm new password</label>
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
        <button type="submit" className={buttonClass} disabled={processing}>Update password</button>
      </form>
    </AuthCard>
  )
}
