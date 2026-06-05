import { Head } from '@inertiajs/react'

export default function Landing() {
  return (
    <>
      <Head title="Pinpoint — note-taking for video learning" />
      <main className="min-h-screen bg-neutral-950 text-neutral-100 flex items-center justify-center px-6">
        <div className="max-w-2xl text-center">
          <p className="text-sm font-mono uppercase tracking-[0.3em] text-amber-400">
            Pinpoint
          </p>
          <h1 className="mt-6 text-5xl font-semibold tracking-tight sm:text-6xl">
            Pin every moment worth learning.
          </h1>
          <p className="mt-6 text-lg text-neutral-400">
            Upload videos or paste a YouTube link, take timestamped notes, organize them into
            courses and curriculums, and study what matters — built for serious video learning.
          </p>
          <div className="mt-10 flex items-center justify-center gap-4">
            <a
              href="#"
              className="rounded-lg bg-amber-400 px-6 py-3 font-medium text-neutral-950 hover:bg-amber-300 transition"
            >
              Get started
            </a>
            <span className="text-sm text-neutral-500 font-mono">app.&lt;domain&gt; to enter</span>
          </div>
          <p className="mt-16 text-xs text-neutral-600 font-mono">landing · apex host</p>
        </div>
      </main>
    </>
  )
}
