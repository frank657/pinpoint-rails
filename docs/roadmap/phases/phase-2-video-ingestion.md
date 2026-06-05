# Phase 2 — Video ingestion (Aliyun VOD + YouTube)

**Goal:** a user can add a video two ways — **upload** (direct to Aliyun VOD) or **paste a
YouTube link** — and watch it in-app. This ports method-channel's proven VOD pipeline and
adds a YouTube source, unified behind one `Video` model.

**Depends on:** Phase 1 · **Locked by:** ADR 0007 (port VOD), 0002 (tenancy)

## Scope

### Ported Aliyun VOD pipeline (ADR 0007)
- Bring `app/lib/ali_vod/**`, `app/services/vod_service/aliyun/**`, the `Vod` +
  `Vod::Attachment` models, the `Vod::Providers` concern, `vod_attached` macro, and the
  Aliyun VOD **webhook controller** — adapted to Pinpoint.
- Flow (unchanged): create `Vod` → `after_create` → Aliyun `CreateUploadVideo` → return
  Base64 `upload_address` + `upload_auth` + signed id → **browser uploads direct to OSS** →
  webhooks `FileUploadComplete` (→ `uploaded`) and `TranscodeComplete` (→ `ready` +
  `duration` + cover). Playback URLs via `GetPlayInfo` (m3u8 + mezzanine fallback).
- **Tenancy adaptation:** the webhook has no session — resolve the workspace from the
  `Vod`/`Video` and wrap work in `ActsAsTenant.with_tenant` (ADR 0002). Verify webhook
  signature exactly as method-channel does.

### Unified Video model
- `Video` (acts_as_tenant): `source:enum { upload, youtube }`, `title`,
  `duration_seconds`, `youtube_id` (nullable). Upload videos `has_one :vod`.
- **Reference-counted Vod** (ADR 0005 foreshadow): a Vod may be referenced by multiple
  Videos (future forks); destroy the Aliyun object only when the last Video is gone. Build
  the counting now even though forking lands in Phase 5.

### YouTube ingestion
- Paste a URL → parse `youtube_id` (handle watch/share/shorts/embed forms) → fetch
  title + duration via oEmbed/metadata → create `Video(source: youtube)`. No Vod.

### Frontend
- "Add video" UI: upload (with progress, direct-to-OSS) and "paste YouTube link".
- A **video player page**: Aliyun HLS player for uploads, YouTube embed for youtube
  source — both exposing `currentTime` and `seek(seconds)` so Phase 3 notes can hook in.
- Upload status polling via the signed id (uploading → uploaded → ready).

## Key tasks
1. Port `ali_vod` libs + `vod_service` + Vod models + AS Aliyun patch (from Phase 0 storage
   config); adapt namespaces, remove Creator/payments coupling.
2. `Video` model + association to `Vod`; reference-count scaffolding.
3. Aliyun webhook controller with workspace resolution + signature auth; specs with stubbed
   payloads.
4. Direct-upload controller/endpoint returning credentials; React uploader to OSS.
5. YouTube URL parsing + metadata fetch + `Video` creation.
6. Player page (HLS + YouTube) exposing time API.

## Out of scope
- Notes/segments (Phase 3), courses (Phase 4), transcripts (Phase 11), forking (Phase 5 —
  but reference-count groundwork lands here).

## Exit criteria
- Upload a file → it appears `uploading`, flips to `ready` via webhook (simulated in test,
  real in staging), and plays via HLS.
- Paste a YouTube link → a `Video` is created with correct title/duration and plays embedded.
- Webhook rejects bad signatures; tenant is correctly resolved without a session (spec).
- Deleting a Video destroys the Aliyun asset **only** when no other Video references the Vod
  (spec).
