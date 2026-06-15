# Pinpoint — Development Plan

We build **phase by phase**. Each phase is a self-contained file in
`docs/roadmap/phases/` with: goal, scope, data model/migrations, key tasks, dependencies,
and **exit criteria**. Don't start a phase until its dependencies are met; don't mark it
done until the exit criteria pass.

> Status legend: ⬜ not started · 🟦 in progress · ✅ done

> The initial product was built **phase by phase** (the table below). Ongoing work now happens
> as **iterations** (`iterations/`, see `../guides/iteration-guide.md`). Several phases were
> later **torn out** — see the removed-features note under the table.

## Phase order

| # | Phase | Status | Depends on | Locked by ADR |
|---|-------|--------|-----------|---------------|
| 0 | [Foundation & scaffold](phases/phase-0-foundation.md) | ✅ | — | 0001, 0006, 0007 |
| 1 | [Auth & Workspaces](phases/phase-1-auth-workspaces.md) | ✅ | 0 | 0002, 0006, 0008 |
| 2 | [Video ingestion (Aliyun VOD + YouTube)](phases/phase-2-video-ingestion.md) | ✅ | 1 | 0007 |
| 3 | [Notes (timestamp, range, rich text), categories, tags, segments](phases/phase-3-notes.md) | ✅ | 2 | 0004 |
| 5 | [Sharing & Forking](phases/phase-5-sharing-forking.md) | ✅ | 3 | 0005 |
| 6 | [Admin panel](phases/phase-6-admin-panel.md) | ✅ | 1 | 0006 |
| 7 | [Progress tracking & resume](phases/phase-7-progress.md) | ✅ | 3 | 0004 |
| 10 | [Technique taxonomy graph](phases/phase-10-taxonomy-graph.md) | ✅ | 3 | 0004 |

> **Removed features.** Phases **4** (Courses/Curriculums/Folders → later Notebook), **8**
> (Spaced repetition / FSRS), **9** (Training log — never built), and **11** (Transcripts & AI
> search/summarization) were torn out, along with their ADRs (0003, 0009, 0010) and code
> (ReviewCard, FSRS, Notebook, TranscriptLine, the AI provider). The content model is now flat
> — `Video → {Note, Video::Segment}` — see ADR 0004 + `../ARCHITECTURE.md`. The phase numbers
> are left as gaps rather than renumbered.

## Shape of the build

- **Phases 0–5** are the core product: get from "empty app" to "upload/paste a video, take
  notes (with categories/tags/segments), share & fork." This is the MVP spine.
- **Phase 6** (admin) can be developed in parallel after Phase 1 (it only needs auth +
  whatever data exists), but is listed after the core spine for focus.
- **Phases 7 & 10** are the surviving **learning layer** — per-user progress and the BJJ
  Position/Technique taxonomy graph.

## Working agreement per phase

1. Read the phase file + the ADRs it cites.
2. If the phase needs a hard-to-reverse choice not already in an ADR, **write an ADR
   first**, then build.
3. Build with tests (RSpec). Stub Aliyun/AI.
4. Update the phase status here and write/refresh the relevant `docs/guides/*`.
5. Demo against the phase's exit criteria before moving on.

## Out of scope for v1 (deferred — see ADR 0007)

Payments / monetization (Stripe), chat/DMs, third-party login (WeChat/Apple), native mobile,
public JSON API. Each, if revived, gets its own ADR.
