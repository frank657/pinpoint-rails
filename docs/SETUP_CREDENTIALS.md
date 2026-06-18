# Setup — credentials & things YOU need to provide

This is the running checklist of secrets/config **you** must supply. Items are marked:

- 🔴 **required** for the feature to work at all
- 🟡 **optional** / enhances a feature
- ✅ **already handled** (no action needed)

Secrets live in Rails **encrypted credentials** — edit with:

```bash
bin/rails credentials:edit          # opens the decrypted YAML in $EDITOR
```

The expected YAML shape is at the bottom. Non-secret config goes in `.env` (see `.env.example`).

---

## 1. Rails master key — ✅ handled (but keep it safe)

`config/master.key` exists locally and decrypts credentials. **For deploy**, set
`RAILS_MASTER_KEY` (the contents of that file) as an environment variable. Never commit it.

## 2. App hosts — ✅ default for local, 🔴 set for deploy

`.env` → `APP_DOMAIN` (default `lvh.me:3000` for local subdomain dev). In production set it to
your real domain so the three hosts resolve (`pinpoint.com`, `app.pinpoint.com`,
`admin.pinpoint.com` — docs/decisions/0006).

## 3. Redis (Sidekiq) — ✅ default

`.env` → `REDIS_URL` (default `redis://localhost:6379/0`). Background jobs + the Aliyun
webhook processing use it. A local Redis is already running in dev.

## 4. Aliyun OSS + VOD — 🔴 required for **video upload** (Phase 2)

Without these, **uploading video files does nothing** (YouTube links still work — they need
no credentials). You need an Aliyun account with **OSS** (object storage) and **VOD** (video
on demand) enabled, then provide:

| Credential key | What it is | Where to get it |
|---|---|---|
| `aliyun.access_key_id` | RAM access key id | Aliyun console → RAM → AccessKeys |
| `aliyun.access_key_secret` | RAM access key secret | same |
| `aliyun.bucket` | OSS bucket name (for note images & cover images via Active Storage) | OSS console → create a bucket |
| `aliyun.endpoint` | OSS endpoint, e.g. `oss-cn-shanghai.aliyuncs.com` | OSS bucket overview |
| `aliyun.vod.endpoint` | VOD API endpoint, e.g. `vod.cn-shanghai.aliyuncs.com` | VOD region |
| `aliyun.vod.api_version` | API version, use `"2017-03-21"` | fixed |
| `aliyun.vod.storage_location` | VOD storage location | VOD console → Configuration → Storage |
| `aliyun.vod.video_template` | Transcode **template group id** (controls HLS/mp4 outputs) | VOD console → Transcode → Template Groups |
| `aliyun.vod.callback_auth` | A secret string **you choose**, used to verify webhook signatures | you invent it; also set it on the Aliyun callback config |

**Also configure on the Aliyun side (console, not code):**
1. A **transcode template group** that outputs **HLS (m3u8)** — its id is `video_template`.
2. **Event notifications / callback**: set the VOD **MessageCallback** URL to
   `https://app.<your-domain>/webhooks/aliyun/vod` and the callback key to the same value as
   `callback_auth`. (The app also passes the callback URL per-upload, but configuring it in
   the console is the reliable path.) This is how `uploading → uploaded → ready` transitions
   reach the app.
3. CORS on the OSS/VOD bucket to allow browser `PUT`/`POST` from `https://app.<your-domain>`
   (direct upload happens browser → OSS).

> Until these are set: the upload UI will fail when it calls `POST /videos/upload`
> (provisioning needs the keys). Everything else — auth, workspaces, YouTube videos — works.

## 5. YouTube Data API key — 🟡 optional (powers **duration** + **chapter import**)

`youtube.api_key`. Without it, pasted YouTube videos still work (title + thumbnail come from
the keyless oEmbed endpoint), but two features go dark: the **duration** is left blank (the
player reports it client-side anyway), and **"Import from YouTube"** on the video page can't
read the description, so chapter→segment import finds nothing. Get one at Google Cloud console
→ enable "YouTube Data API v3" → Create credentials → **Public data** (a plain API key, no
OAuth). Restrict the key to the YouTube Data API. Both features ride the same key.

## 6. Email delivery (Devise password reset) — 🟡 optional now, 🔴 for production

In development, password-reset emails open in the browser (`letter_opener`) — nothing to set.
For production you'll need an SMTP/provider (e.g. Postmark/SES) wired into Action Mailer.
Tracked for a later phase; not needed to develop.

## 7. Database (production) — ✅ local, 🔴 deploy

Local dev uses your Postgres with no password. Production needs `DATABASE_URL` (and
`PINPOINT_RAILS_DATABASE_PASSWORD` per `config/database.yml`).

---

## Credentials YAML shape

Run `bin/rails credentials:edit` and structure it like this (only fill what you have):

```yaml
secret_key_base: <generated>

aliyun:
  access_key_id: "LTAI..."
  access_key_secret: "..."
  bucket: "pinpoint-prod"
  endpoint: "oss-cn-shanghai.aliyuncs.com"
  vod:
    endpoint: "vod.cn-shanghai.aliyuncs.com"
    api_version: "2017-03-21"
    storage_location: "out-xxxx.oss-cn-shanghai.aliyuncs.com"
    video_template: "<template group id>"
    callback_auth: "<a secret you choose>"

youtube:
  api_key: "AIza..."          # optional

host:
  domain: "pinpoint.com"      # optional; APP_DOMAIN env overrides
```

---

## What's verified vs. what needs your credentials

| Path | Status |
|---|---|
| Auth, workspaces, tenancy | ✅ tested (specs + live) |
| **YouTube** ingest → video → player | ✅ tested live (real oEmbed) |
| Aliyun upload **provisioning + webhook + reference counting** | ✅ tested with the provider **stubbed** |
| Aliyun **provisioning (CreateUploadVideo)** against the real account | ✅ verified live (bucket `pinpoint-vod-dev`, oss-cn-shanghai) |
| Aliyun **real** browser upload + transcode + HLS playback | ◻️ end-to-end browser upload still to be exercised manually |
| YouTube **duration** + **chapter import** | needs `youtube.api_key` (item 5) |
