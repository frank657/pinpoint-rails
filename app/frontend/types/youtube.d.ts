// Minimal YouTube IFrame Player API typings (the bits we use).
export {}

declare global {
  namespace YT {
    interface Player {
      seekTo(seconds: number, allowSeekAhead: boolean): void
      getCurrentTime(): number
      destroy(): void
    }
    interface PlayerOptions {
      videoId?: string
      playerVars?: Record<string, unknown>
      events?: Record<string, (event: unknown) => void>
    }
    const Player: {
      new (el: HTMLElement | string, opts: PlayerOptions): Player
    }
  }

  interface Window {
    YT: typeof YT
    onYouTubeIframeAPIReady?: () => void
  }
}
