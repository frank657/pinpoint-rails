# Phase 5 — Sharing & Forking

**Goal:** share a Note / Video / Course / Curriculum / Folder with others (read-only), and
let them **"save as my own"** — a **deep copy** into their workspace that is fully
independent afterward (edits never cross-contaminate).

**Depends on:** Phase 4 · **Locked by:** ADR 0005 (share/fork deep copy), 0004 (three axes)

## Scope

### Share (view grant — no copy)
- `Share` (polymorphic `shareable`): `visibility:enum { private, unlisted, public }`,
  optional explicit grant to a user/workspace.
- Public/unlisted **share pages** (FriendlyId slugs) viewable on `app.` (or apex for public)
  — read-only rendering of the shared object and its subtree.
- Owner can revoke; recipients can't edit a shared-not-forked object.

### Fork ("save as my own" — deep copy, ADR 0005)
- Deep-copy the **content subtree** into the forker's **current workspace**:
  - Course → copies Course, Chapters, CourseItems, and (forker's choice) the Notes/Segments
    on included videos.
  - Curriculum → copies Curriculum, CurriculumItems, and the Courses beneath.
  - Note/Folder/Video → copy that subtree.
- **Media shared by reference, not re-uploaded:** new Video rows point at the same `Vod`
  (Aliyun asset) / same `youtube_id`. Increment the Vod reference count (Phase 2 groundwork).
- **Taxonomy re-pointed** into the forker's workspace: Categories/Tags recreated or matched
  by name so the copy is self-contained.
- **Axis-3 per-user state copied: none** — forker starts with zero progress/reviews/log.
- Record `Fork` (`source` + `source_workspace`, `target` + `target_workspace`) for
  attribution only — no ongoing coupling.
- Large subtrees deep-copy in a **background job** with progress feedback.

### Independence guarantees (the core requirement)
- After fork, editing either copy never affects the other (separate content rows).
- Deleting the **source** never breaks a fork: reference-counted `Vod` is destroyed only
  when the last referencing Video (across all workspaces) is gone.
- Media is immutable once `ready`; "replace video" makes a new Vod, never mutates a shared
  one.

## Key tasks
1. `Share` model + visibility + grants; share pages (read-only) + slugs.
2. Deep-copy service per content type (Course/Curriculum/Note/Folder/Video), as a Sidekiq
   job for big subtrees; Vod reference-count increment.
3. Taxonomy re-point/match-by-name on fork.
4. `Fork` attribution record; "forked from" UI badge.
5. Reference-counted Vod deletion (destroy Aliyun asset only on last reference) + specs.
6. Authorization: who can view (Share) vs. who can fork.

## Out of scope
- "Pull upstream updates" from source (future ADR — `forked_from` makes it possible).
- Monetized/paid sharing (deferred, ADR 0007).
- Multi-member workspace collaboration UX (membership exists; rich collab is later).

## Exit criteria
- Share a Course publicly; a second user opens the share page read-only.
- Second user forks it → an independent copy appears in **their** workspace; editing it does
  not change the original (spec asserts row independence).
- Forked videos reference the **same** Vod (no re-upload); deleting the source Course/Video
  does not break the fork's playback (reference-count spec).
- Forked copy starts with **no** progress/review state (Axis-3 not copied; spec).
- A `Fork` record links source→target for attribution.
