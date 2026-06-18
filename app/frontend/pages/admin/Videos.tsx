import { Head } from '@inertiajs/react'
import AdminShell from '../../components/AdminShell'

interface Row { id: string; title: string; source: string; workspace: string; vodStatus: string | null; vodKey: string | null; createdAt: string }

export default function AdminVideos({ videos }: { videos: Row[] }) {
  return (
    <AdminShell>
      <Head title="Videos · Admin" />
      <h1 className="text-2xl font-semibold tracking-tight">Videos</h1>
      <table className="mt-6 w-full text-left text-sm">
        <thead className="text-xs uppercase text-neutral-500">
          <tr><th className="py-2">Title</th><th>Source</th><th>Workspace</th><th>VOD status</th></tr>
        </thead>
        <tbody className="divide-y divide-neutral-800">
          {videos.map((v) => (
            <tr key={v.id}>
              <td className="py-2">{v.title}</td>
              <td className="text-neutral-400">{v.source}</td>
              <td className="text-neutral-400">{v.workspace}</td>
              <td>{v.vodStatus ? <span className="font-mono text-xs">{v.vodStatus}</span> : '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminShell>
  )
}
