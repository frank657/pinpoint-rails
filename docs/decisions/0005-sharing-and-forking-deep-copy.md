# ADR 0005 — Sharing & forking = deep-copy of a content subtree

- **Status:** Accepted
- **Date:** 2026-06-04
- **Decision owner:** Frank Zhu

---

## Context

Requirement: *"I can share my video, notes, etc. to others. Others can save those as their
own. After they save as their own, whatever they do with them doesn't impact mine."* That
last clause is the whole design constraint: a saved copy must be **fully independent** of the
source.

Notion implements exactly this as **"Duplicate as template"** — a deep copy of an entire
page subtree into the duplicator's workspace.

## Decision

Two distinct operations:

### 1. Share (grant view access — no copy)

A **Share** makes a content object (Video or Note) viewable by others, via:
- a **link/visibility** setting (`private` / `unlisted-link` / `public`), and/or
- an explicit grant to specific users/workspaces.

A shared-but-not-forked object is **read-only** to the recipient. It still belongs to the
owner's workspace; the owner can edit or revoke. No data is duplicated. Shareability is the
`Shareable` concern, mixed into `Video` and `Note`.

### 2. Fork / "Save as my own" (deep copy)

**Forking deep-copies the content subtree into the forker's current workspace.** After
forking, the copy is the forker's — fully independent; edits on either side never affect the
other.

What a fork copies, per the three-axis model (ADR 0004):
- **Axis 1 — Content: deep-copied.** Forking a Video copies the Video and (by the forker's
  choice) its Notes and Segments. The underlying **media is shared by reference, not
  re-uploaded**: the new Video rows point at the same `Vod` (Aliyun asset) or the same YouTube
  id — we copy the *reference*, never the bytes.
- **Axis 2 — Taxonomy: not carried over (for now).** Forked notes start **unlabelled** —
  category and tags are dropped. Re-pointing taxonomy into the forker's workspace is a
  deliberate future enhancement, kept out to keep the fork simple. See `ForkService`.
- **Axis 3 — Per-user state: never copied.** The forker starts with zero progress on the copy.

Every fork records a **`Fork`** attribution row (source type/id + source workspace → target
type/id + target workspace) for provenance and a possible future "pull upstream updates"
feature. Attribution is a back-reference only; it creates **no** ongoing data coupling.

### Media ownership nuance

Because forked Videos share the same underlying `Vod`/YouTube reference, deleting the
**source** must not break forks. The `Vod` (Aliyun asset) is reference-counted by its
`Video` rows; the Aliyun object is only destroyed when the **last** referencing Video is
gone (`Video#cleanup_orphaned_vod`). (YouTube-sourced videos have no asset to delete.)

## Consequences

- ✅ Satisfies the core requirement: a saved copy is independent; later edits don't
  cross-contaminate.
- ✅ No media re-upload on fork — forking a 2-hour instructional is cheap (rows, not
  gigabytes).
- ✅ Per-user state separation (ADR 0004) makes "independent after save" structurally true,
  not just by convention.
- ⚠️ Reference-counted Vod deletion must be implemented carefully (don't destroy an Aliyun
  asset another workspace's fork still points at). Tracked in the Video/Vod model and tests.
- ⚠️ Visibility/permission inheritance needs a single unambiguous owner per object — a fork's
  owner is the forking user/workspace; the source's owner is unchanged.
- ⚠️ If a forked video's media reference is shared, editing the *media* (re-transcode,
  replace) would affect all forks. We treat the media as immutable once `ready`; "replace
  video" creates a new Vod, it does not mutate a shared one.

## Alternatives considered

- **Fork by reference (shared rows, copy-on-write).** Rejected: the forker can't freely edit
  (writes would hit shared rows), and upstream edits leak downstream — the opposite of "no
  impact on mine."
- **Fork copies media too (re-upload to forker's storage).** Rejected: wasteful (gigabytes
  per fork) with no benefit, since media is immutable-once-ready and reference-counting gives
  the same independence guarantee for everything that actually changes (content rows, notes).
- **No fork, only share (read-only).** Rejected: the requirement explicitly wants "save as
  my own and then edit freely."

## Sources

- Notion "Duplicate as template" (deep-copy a subtree): <https://www.notion.com/help/database-templates>
- Notion permissions/single-parent model: <https://www.notion.com/blog/data-model-behind-notion>
