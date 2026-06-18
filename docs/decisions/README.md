# Architecture Decision Records (ADRs)

This folder captures **deliberate, hard-to-reverse decisions** and the reasoning behind
them — the structural choices that shape the whole app and that a future reader could not
re-derive from the code alone.

If a decision can be re-derived by reading the code or a guide, it does **not** belong here.
ADRs exist for the choices where the *rationale and the rejected alternatives* are the
valuable part.

## These are locked

An **Accepted** ADR is a commitment. Code must not contradict it. To change a decision,
write a **new** ADR that supersedes the old one and update the `Status` of both — never
edit an accepted decision into something different, and never silently diverge in code.

## Conventions

- Files: `NNNN-kebab-title.md`, zero-padded sequential (`0001-`, `0002-`, …).
- Status values: `Proposed` → `Accepted` → (`Superseded by NNNN` | `Deprecated`).
- Every ADR carries: Context, Decision, Consequences, Alternatives considered, and (when a
  choice is driven by an external constraint or vendor behavior) Sources.
- Numbers are not reused. Gaps in the sequence (0003, 0009, 0010) are ADRs that were removed
  when their feature was torn out — see the note below.

> **Removed decisions:** 0003 (Course/Curriculum content model), 0010 (Notebook content model,
> which had superseded 0003), and 0009 (AI provider) were deleted along with their features.
> The content model is now flat — `Video → {Note, Video::Segment}` with no grouping layer —
> and is described by ADR 0004 + `docs/ARCHITECTURE.md`.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-monolith-inertia-react.md) | Monolith Rails + Inertia/React (not API + separate SPA) | Accepted |
| [0002](0002-workspaces-and-multi-tenancy.md) | Workspaces as the multi-account / tenancy boundary | Accepted |
| [0004](0004-content-taxonomy-userstate-separation.md) | Three-axis model: content vs. taxonomy vs. per-user state | Accepted |
| [0005](0005-sharing-and-forking-deep-copy.md) | Sharing & forking = deep-copy of a content subtree | Accepted |
| [0006](0006-subdomain-architecture.md) | Subdomain layout (landing / app / admin) | Accepted |
| [0007](0007-port-from-method-channel.md) | What to port from method-channel vs. drop/replace | Accepted |
| [0008](0008-authorization-action-policy.md) | Authorization via Action Policy (not CanCanCan) | Accepted |
| [0011](0011-note-segment-mapping.md) | Notes mapped into segments (stored association, orphan/pinned) | Accepted |
| [0012](0012-uuid-primary-keys.md) | UUID primary keys everywhere (in-place conversion) | Accepted |
