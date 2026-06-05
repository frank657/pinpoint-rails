# Phase 11 — Transcripts & AI search/summarization

**Goal:** make videos *searchable and summarizable*. Ingest transcripts (YouTube + uploaded),
provide timestamped full-text transcript search, and add AI summaries and AI-drafted
flashcards/notes.

**Depends on:** Phase 2 (videos), Phase 3 (notes) · **Locked by:** — (provider choice gets
its own ADR when picked)

## Scope

### Transcripts (Axis 1 — content)
- `Transcript` / transcript lines: `video_id`, ordered lines each with `start_seconds`,
  `end_seconds`, `text`. Sources:
  - **YouTube:** fetch available captions/transcript by `youtube_id`.
  - **Uploaded:** ASR (Aliyun has speech services, or a pluggable provider) on the mezzanine
    audio, run as a Sidekiq job after `ready`.
- Store timestamps as numeric seconds (ADR 0004) so search results **seek the player**.

### Transcript search
- pg_search (or a dedicated index) over transcript lines + notes; results deep-link to the
  moment. Workspace-scoped.

### AI features (pluggable provider — pick in a dedicated ADR before building)
- **Summarize** a video / chapter / course (with timestamped key moments).
- **Draft flashcards/notes** from transcript + existing notes → feed Phase 8 review (user
  reviews/edits AI drafts; never auto-published silently).
- Optional **auto-tagging** into the Phase 10 position/technique taxonomy.
- Run as background jobs; cache results; show provenance ("AI-generated draft").

### Guardrails
- AI is **assistive**: drafts are editable suggestions, clearly labeled, never silently
  authoritative.
- Provider abstraction so the model/vendor can change; stub in specs (never hit the network
  in tests).
- Cost controls: summarization/ASR are opt-in per video, queued, and rate-limited.

## Key tasks
1. Transcript model + YouTube caption fetch + uploaded-video ASR job.
2. Timestamped transcript search (pg_search) with seek-on-result.
3. **ADR** for the AI provider + abstraction layer; summarization service (jobs + cache).
4. AI flashcard/note drafting → Phase 8 cards (review-before-keep).
5. Optional AI auto-tag into Phase 10 taxonomy.

## Out of scope
- Realtime/live transcription.
- Anything that auto-creates content without user review.

## Exit criteria
- A YouTube video shows a searchable transcript; clicking a result seeks the player.
- An uploaded video gets an ASR transcript via a background job after it's `ready`.
- "Summarize" produces a timestamped summary; AI flashcard drafts appear as editable
  suggestions that, when accepted, become Phase 8 review cards.
- AI provider is behind an abstraction and fully stubbed in tests.
