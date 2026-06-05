# ADR 0009 — AI provider abstraction (Anthropic Claude, behind a port)

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Phase 11 adds AI features: summarize a video/transcript and draft flashcards from notes. These
must (a) not hard-couple to one vendor, (b) be fully stubbable in tests (never hit the
network), and (c) degrade gracefully when no API key is configured.

## Decision

Introduce an **`Ai` port** with a swappable provider:

- `Ai.summarize(text, ...)` and `Ai.draft_flashcards(text, ...)` are the public seam.
- The default provider is **Anthropic Claude** (`Ai::Anthropic`), selected when
  `credentials.ai.anthropic_api_key` is present. The model default is the latest Claude
  (e.g. `claude-sonnet-4-6`).
- When no key is set, a **`Ai::Null` provider** returns a clearly-labelled deterministic
  stub so the feature works offline and in CI without secrets.
- Provider is chosen at call time from configuration; swapping vendors is adding one class.

AI output is **assistive**: summaries and flashcard drafts are editable suggestions, clearly
marked "AI-generated", never silently authoritative. Generation runs in background jobs and
is rate-limited/opt-in per video.

## Consequences

- ✅ Vendor-swappable; specs stub `Ai` (no network); offline/no-key path works.
- ✅ Keeps the door open for other models without touching call sites.
- ⚠️ The real Anthropic call (and prompt-caching, batching) is implemented incrementally; the
  Null provider is the baseline.
- ⚠️ Cost/safety controls (opt-in, rate limits, provenance labels) are part of the feature,
  not an afterthought.

## Sources

- Anthropic API / Claude models (see the claude-api skill for current model IDs).
