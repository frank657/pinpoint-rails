# Phase 5 — Sharing & Forking

**Goal:** share a **Video** or **Note** with others (read-only), and let them **"save as my
own"** — a **deep copy** into their workspace that is fully independent afterward (edits never
cross-contaminate).

**Depends on:** Phase 3 · **Locked by:** ADR 0005 (share/fork deep copy), 0004 (three axes)

## Scope

### Share (view grant — no copy)
- `Share` (polymorphic `shareable` — Video or Note): `token`, visibility, optional explicit
  grant to a user/workspace. Shareability is the `Shareable` concern.
- Public/unlisted **share pages** viewable on `app.` — read-only rendering of the shared
  object and its subtree.
- Owner can revoke; recipients can't edit a shared-not-forked object.

### Fork ("save as my own" — deep copy, ADR 0005)
- Deep-copy the **content subtree** into the forker's **current workspace** (`ForkService`):
  - Video → copies the Video and (forker's choice) its Notes and Segments.
  - Note → copies that note.
- **Media shared by reference, not re-uploaded:** new Video rows point at the same `Vod`
  (Aliyun asset) / same `youtube_id`.
- **Taxonomy: not carried over (for now)** — forked notes start unlabelled (category/tags
  dropped). Re-pointing into the forker's workspace is a deferred enhancement (ADR 0005).
- **Axis-3 per-user state copied: none** — forker starts with zero progress.
- Record a `Fork` row (`source` + `source_workspace`, `target` + `target_workspace`) for
  attribution only — no ongoing coupling.

### Independence guarantees (the core requirement)
- After fork, editing either copy never affects the other (separate content rows).
- Deleting the **source** never breaks a fork: reference-counted `Vod` is destroyed only
  when the last referencing Video (across all workspaces) is gone.
- Media is immutable once `ready`; "replace video" makes a new Vod, never mutates a shared
  one.

## Key tasks
1. `Share` model + visibility + grants; share pages (read-only) + token.
2. `ForkService` deep-copy (Video/Note); Vod reference-count handling.
3. `Fork` attribution record; "forked from" UI badge.
4. Reference-counted Vod deletion (destroy Aliyun asset only on last reference) + specs.
5. Authorization: who can view (Share) vs. who can fork.

## Out of scope
- "Pull upstream updates" from source (future — the `Fork` record makes it possible).
- Re-pointing taxonomy (category/tags) on fork — deferred.
- Multi-member workspace collaboration UX (membership exists; rich collab is later).

## Exit criteria
- Share a Video publicly; a second user opens the share page read-only.
- Second user forks it → an independent copy appears in **their** workspace; editing it does
  not change the original (spec asserts row independence).
- Forked videos reference the **same** Vod (no re-upload); deleting the source Video does not
  break the fork's playback (reference-count spec).
- Forked copy starts with **no** progress state (Axis-3 not copied; spec).
- A `Fork` record links source→target for attribution.
