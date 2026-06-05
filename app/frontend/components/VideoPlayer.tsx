import { useEffect, useRef, forwardRef, useImperativeHandle } from 'react'

export interface Playback {
  source: 'youtube' | 'upload'
  youtubeId?: string
  hlsUrl?: string | null
  status?: string
}

// Imperative handle so the notes timeline can seek the player and read its current time —
// works for BOTH uploaded video (HTML <video>) and YouTube (IFrame Player API).
export interface PlayerHandle {
  seek: (seconds: number) => void
  currentTime: () => number
}

function loadYouTubeApi(): Promise<typeof window.YT> {
  if (window.YT?.Player) return Promise.resolve(window.YT)
  return new Promise((resolve) => {
    const existing = window.onYouTubeIframeAPIReady
    window.onYouTubeIframeAPIReady = () => {
      existing?.()
      resolve(window.YT)
    }
    if (!document.getElementById('youtube-iframe-api')) {
      const tag = document.createElement('script')
      tag.id = 'youtube-iframe-api'
      tag.src = 'https://www.youtube.com/iframe_api'
      document.head.appendChild(tag)
    }
  })
}

const VideoPlayer = forwardRef<PlayerHandle, { playback: Playback }>(({ playback }, ref) => {
  const videoRef = useRef<HTMLVideoElement>(null)
  const ytHostRef = useRef<HTMLDivElement>(null)
  const ytPlayer = useRef<YT.Player | null>(null)

  useImperativeHandle(ref, () => ({
    seek: (seconds: number) => {
      if (playback.source === 'youtube') ytPlayer.current?.seekTo(seconds, true)
      else if (videoRef.current) videoRef.current.currentTime = seconds
    },
    currentTime: () => {
      if (playback.source === 'youtube') return ytPlayer.current?.getCurrentTime() ?? 0
      return videoRef.current?.currentTime ?? 0
    },
  }))

  // YouTube IFrame Player.
  useEffect(() => {
    if (playback.source !== 'youtube' || !playback.youtubeId) return
    let cancelled = false
    loadYouTubeApi().then((YT) => {
      if (cancelled || !ytHostRef.current) return
      ytPlayer.current = new YT.Player(ytHostRef.current, {
        videoId: playback.youtubeId,
        playerVars: { rel: 0 },
      })
    })
    return () => {
      cancelled = true
      ytPlayer.current?.destroy()
      ytPlayer.current = null
    }
  }, [playback.source, playback.youtubeId])

  // HLS for uploaded video.
  useEffect(() => {
    const video = videoRef.current
    if (playback.source !== 'upload' || !playback.hlsUrl || !video) return

    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = playback.hlsUrl
      return
    }
    let destroyed = false
    let hls: { destroy: () => void } | null = null
    import('hls.js').then(({ default: Hls }) => {
      if (destroyed || !Hls.isSupported()) return
      const instance = new Hls()
      instance.loadSource(playback.hlsUrl as string)
      instance.attachMedia(video)
      hls = instance
    })
    return () => {
      destroyed = true
      hls?.destroy()
    }
  }, [playback.source, playback.hlsUrl])

  if (playback.source === 'youtube') {
    return (
      <div className="aspect-video w-full overflow-hidden rounded-xl bg-black">
        <div ref={ytHostRef} className="h-full w-full" />
      </div>
    )
  }

  if (!playback.hlsUrl) {
    return (
      <div className="flex aspect-video w-full items-center justify-center rounded-xl border border-dashed border-neutral-300 text-neutral-400">
        {playback.status === 'uploading' ? 'Uploading…' : 'Processing video…'}
      </div>
    )
  }

  return <video ref={videoRef} controls className="aspect-video w-full rounded-xl bg-black" />
})

VideoPlayer.displayName = 'VideoPlayer'
export default VideoPlayer
