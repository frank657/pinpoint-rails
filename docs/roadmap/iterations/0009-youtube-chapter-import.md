# Iteration 0009 — Import YouTube chapters as Segments

> **Status:** ✅ shipped · **Owner:** Frank · **Started:** 2026-06-18 · **Shipped:** 2026-06-18
> Links: ADR 0011 (note↔segment adoption) · builds on iteration 0007

## Goal & context

YouTube videos often ship with chapters (the timestamp lines an uploader puts in the
description). Let a user turn those into `Video::Segment`s in one click instead of hand-adding
each one. The bar: paste-and-import an instructional with a dozen chapters and get a dozen
correctly-timed, labelled segments — and re-importing never duplicates them.

There is **no** structured chapters field in any YouTube API — YouTube derives the pills from
the description text. So we fetch the description (Data API v3 `part=snippet`) and parse the
same timestamp lines ourselves. Closed `[start, next_start)` ranges mean imported segments
immediately adopt the video's orphan notes (ADR 0011) for free.

## Locked decisions

1. **Parse the description; don't scrape.** Description via Data API v3 (`youtube.api_key`,
   already used for duration). No yt-dlp / HTML scraping.
2. **One segment per timestamped line.** Untimed lines are skipped; junk lines (e.g. `AD`) are
   imported as-is and left for the user to delete — no heuristic filtering.
3. **Closed ranges.** `end_seconds` = next chapter's start; last chapter = video duration if
   known, else open-ended.
4. **Idempotent import.** Skip any chapter whose `start_seconds` already has a segment; new
   positions continue after existing ones.
5. **Pure parser, isolated fetch.** `Youtube::ChapterParser` is offline/pure; the network seam
   lives in `Youtube::Chapters` (stubbed in specs, never hits the network).

## Test plan (written first)

- **Service** (`spec/services/youtube/chapter_parser_spec.rb`): MM:SS & H:MM:SS → seconds;
  drop untimed lines; strip bullets/separators; chain `end_seconds`; last → duration / nil;
  de-dupe + sort; `[]` on no-timestamps / nil.
- **Request** (`spec/requests/video_chapters_spec.rb`): creates a segment per chapter with
  positions; idempotent re-import; graceful "no chapters" notice; refuses non-YouTube videos;
  tenant isolation → 404.

## Build steps

1. `Youtube::ChapterParser` — pure text → `[{title, start_seconds, end_seconds}]`.
2. `Youtube::Chapters` — fetch description (Data API), delegate to the parser; `[]` w/o key.
3. `App::VideosController#import_chapters` (+ member route) — bulk-create, idempotent, authz.
4. `SegmentsEditor` — "Import from YouTube" button (YouTube source only); pass `video.source`.
5. Update `docs/SETUP_CREDENTIALS.md` — the key now powers duration **and** chapter import.

## Exit criteria

- [x] YouTube video → one click imports description chapters as timed, labelled segments
- [x] Re-import adds only new chapters (matched by start time)
- [x] No key / no chapters → friendly "No chapters found" notice, no crash
- [x] Non-YouTube videos can't import; cross-workspace videos 404
- [x] `bundle exec rspec` green (parser 11, request 5; touched suites 38/0)
- [x] `npm run check` (tsc) clean
- [x] `bin/vite build` succeeds
- [x] `bundle exec rubocop` clean

## What shipped

- `app/services/youtube/chapter_parser.rb`, `app/services/youtube/chapters.rb`
- `app/controllers/app/videos_controller.rb` (`#import_chapters` + `import_youtube_chapters`)
- `config/routes/app.rb` (member `post :import_chapters`)
- `app/frontend/components/SegmentsEditor.tsx` (+ `source` prop in `pages/videos/Show.tsx`)
- specs: `spec/services/youtube/chapter_parser_spec.rb`, `spec/requests/video_chapters_spec.rb`
- docs: `docs/SETUP_CREDENTIALS.md`
- Result: rspec (touched) 38/0, tsc clean, vite ok, rubocop clean.

## Out of scope

- Re-pointing imported segments to taxonomy (positions/techniques) — deferred (ADR 0005).
- A preview/confirm step before creating (current flow imports directly; delete to undo).
- Auto-import on paste — kept manual so the user opts in per video.
