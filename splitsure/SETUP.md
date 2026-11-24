# SplitSure – Setup Guide

## 1. Supabase database

In your Supabase project → **SQL Editor**, run these files **in order**:

1. `supabase/migrations/001_initial_schema.sql` – base tables, RLS, profile trigger
2. `supabase/migrations/002_collaboration_projects_plans.sql` – collaboration workflow,
   music projects, plans & feature limits, localized notifications
3. `supabase/migrations/003_storage.sql` – storage buckets & policies (if the SQL editor refuses
   with "must be owner of table objects", create the buckets in Dashboard → Storage instead)

Migrations 002 and 003 are idempotent (safe to re-run). Together they add:

| Area | What you get |
|------|--------------|
| Collaboration | Collaborators can open agreements they're invited to (by e-mail or secure invite link), accept / request changes / decline. Every send creates an immutable **version**; every answer is logged with user + timestamp. Accepted agreements are locked. |
| Security | Status and responses can only change through the `send_agreement_for_review`, `respond_to_agreement` and `claim_agreement_invite` functions — a creator can't mark an agreement accepted or answer for someone else. Clients can no longer insert notifications for other users. |
| Projects | `projects` table; agreements and campaigns can belong to a project. |
| Plans | `plans` (prices in FCFA) and `plan_features` (per-plan limits/flags). **Edit `plan_features` rows to change what the free/paid plans allow** — no app change needed. |
| Storage | Buckets `avatars`, `agreement-assets`, `campaign-assets` (public read, write only to `<uid>/…`) and **private** `agreement-pdfs` (readable only by the agreement's parties). |
| Realtime | `notifications` is added to the realtime publication so the badge updates live. |

4. `supabase/migrations/004_hub_passport_pro.sql` – Free/Pro plans & entitlements, payments,
   paid final agreements, Music Passport, Opportunity Hub, applications, DealFlow workspaces,
   Reach Pro-only (applied to the live project on 2026-11-23)

| Area (004) | What you get |
|------|--------------|
| Plans | `plans` = **free** (0) + **pro** (100 FCFA, one-time; set `duration_days` on `pro` for recurring later). Monthly/quarterly/annual are deactivated. Limits in `plan_features` (`opportunity_posts`, `max_projects`, `reach`, …). |
| Entitlements | `user_entitlements` (plan_type, subscription_status, pro_activated_at, pro_expires_at, payment_status, free_posts_used). **Read-only for clients**: Pro is only granted by `complete_payment()`, which only the payments function can call. |
| Payments | `payment_transactions` (unique reference, type PRO_UPGRADE / AGREEMENT_GENERATION, status pending/success/failed/cancelled). One successful payment per agreement (unique index). |
| Protect | `agreement_documents`: the final PDF can only be uploaded once the agreement is unlocked (Pro, or a verified 50 FCFA payment); it is stored once and readable by every party. Previews stay free. |
| Passport | `music_passports`, `passport_portfolio_items`, public views `public_passports` / `public_portfolio_items` (only published passports, only fields marked public), bucket `passport-media`. |
| Hub | `collaboration_opportunities` (role-targeted visibility via RLS; Free = 1 post counted permanently in `free_posts_used`, Pro unlimited), `opportunity_applications` (one per person per opportunity; status changes only through `set_application_status` / `withdraw_application`). |
| DealFlow | `collaboration_workspaces`, `workspace_members`, `workspace_messages` + RPCs to propose terms, agree, and link the Protect agreement. |
| Reach | Campaign inserts require Pro (`plan_allows('reach')`). |

5. `supabase/migrations/005_whatsapp_profile.sql` – replaces `profiles.instagram_url` with `whatsapp_url` (live).
6. `supabase/migrations/006_hardening.sql` – security fixes from the Supabase advisor: internal helpers
   no longer callable over the API, pinned `search_path` on trigger functions, and the old
   "demo subscription" insert policy removed (Pro is only granted by the payments function).

> After changing columns outside a migration run `notify pgrst, 'reload schema';` so the REST API sees them.

### Payments (MeSomb) – Edge Function `payments`
The app never talks to MeSomb and holds no keys. Deploy `supabase/functions/payments/index.ts`
(already deployed to the live project, legacy JWT check off – the function verifies the user itself),
then in **Dashboard → Edge Functions → Secrets** add:

| Secret | Value |
|--------|-------|
| `MESOMB_APP_KEY` | MeSomb application key |
| `MESOMB_ACCESS_KEY` | MeSomb access key |
| `MESOMB_SECRET_KEY` | MeSomb secret key |

> The keys that used to be in `lib/core/services/mesomb_service.dart` were in the app source and
> must be treated as exposed: **rotate them in the MeSomb dashboard** and use the new ones here.

Flow: app → `payments {action:"initiate"}` (server sets the price, records a pending transaction,
asks MeSomb to collect) → user approves on their phone → app polls `payments {action:"verify"}` →
the function checks the status **with MeSomb** and calls `complete_payment()`, which applies the
result exactly once.

### Subscription expiry (optional, recommended)
Enable the **pg_cron** extension (Database → Extensions), then run:
```sql
select cron.schedule('splitsure-expiry', '0 7 * * *', 'select public.process_subscription_expiry()');
```
This marks expired subscriptions and sends "expiring soon" / "expired" notifications.

---

## 2. Push notifications (Firebase Cloud Messaging)

The web app already contains the Firebase web config, VAPID key and `web/firebase-messaging-sw.js`.
Browser tokens are saved to `fcm_tokens` when a user signs in (or taps **Enable push** in
Settings → Notification preferences).

Pushes are sent server-side by the Edge Function `supabase/functions/send-push`:

1. Firebase Console → Project settings → **Service accounts** → *Generate new private key*.
2. Deploy and configure the function (Supabase CLI):
   ```bash
   supabase functions deploy send-push --no-verify-jwt
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
   supabase secrets set WEBHOOK_SECRET="<any long random string>"
   supabase secrets set APP_URL="https://<your-app-domain>"
   ```
3. Supabase Dashboard → Database → **Webhooks** → *Create*:
   - Table `public.notifications`, event **Insert**
   - Type *Supabase Edge Function* → `send-push`
   - HTTP header `x-webhook-secret: <same WEBHOOK_SECRET>`

Every notification row (agreement invited / accepted / changes requested / declined / new version /
finalised, campaign completed, subscription expiring / expired) then also arrives as a push, in the
recipient's language, unless they switched that category off.

> The service-account key lives only in Supabase secrets — never in the Flutter app.

---

## 3. Running the app

```bash
flutter pub get
flutter run -d chrome          # development
flutter build web --release    # production PWA (deploy build/web)
```

Regenerate the PWA icons from the logo after changing `assets/images/logo.jpeg`:
```bash
dart run tool/generate_icons.dart
```

---

## 4. Feature notes

- **Invitations** – a creator saves an agreement, then *Send for review*. Collaborators with an e-mail
  see it in their account automatically (also after they register with that e-mail). Each line also has a
  **Copy invite link** (`/#/invite/<token>`) to share privately.
- **Versions** – editing a sent agreement publishes a new version and resets everyone's answers; older
  versions and answers stay in *Version history*.
- **PDF** – *Download PDF* builds the agreement in the user's language and stores a copy in the private
  `agreement-pdfs` bucket.
- **Promo videos** – generated in the browser (canvas + Web Audio + MediaRecorder) in real time: a vertical
  9:16 video with artwork, title, artist, message and the chosen snippet. Chrome/Edge/Safari produce **MP4**;
  Firefox produces WebM (the app says so). The file is uploaded to `campaign-assets` and can be downloaded.
  Audio and cover files must be served with CORS (Supabase Storage does this by default).
- **Payments** – the subscription flow is a clearly labelled **demo** (`payment_status = 'demo'`); clients
  cannot create paid rows. Integrate a Cameroon Mobile Money provider server-side by inserting rows with
  `status = 'active'`, `payment_status = 'paid'` from a trusted function.
- **Google sign-in** – not enabled. To add it, configure the Google provider in Supabase Auth and call
  `signInWithOAuth(OAuthProvider.google)`.

---

## 5. Environment summary

| Value | Where |
|-------|-------|
| Supabase URL + publishable key | `lib/core/constants/supabase_config.dart` |
| Firebase web config | `lib/main.dart`, `web/index.html`, `web/firebase-messaging-sw.js` |
| FCM VAPID key | `lib/core/services/fcm_service.dart` |
| Firebase service account, webhook secret, app URL | Supabase secrets (Edge Function only) |

---

## 5. Agreement review e-mails (Edge Function `agreement-emails`)

When the creator presses **Send for review** (or publishes a new version):

1. `send_agreement_for_review()` links every collaborator e-mail to an **existing** SplitSure account
   (case-insensitive) and sends those people the in-app notification (and push, once `send-push` is set up).
2. The app then calls `agreement-emails`, which e-mails **every** collaborator with an address (except the
   creator) a branded message: SplitSure logo and name, song, reference, version, their role and share, all
   parties, the creator's note, and a **Review & approve** button → `APP_URL/#/invite/<token>`.
   Each collaborator line is e-mailed once per version (`agreement_email_log`).

Approval itself happens in the app (the button opens the agreement): a one-click "approve" inside an
e-mail would let anyone who sees the e-mail approve on someone's behalf.

Secrets (Supabase → Edge Functions → Secrets). Either **Gmail** (simplest, same as the Fixit project):

| Secret | Value |
|--------|-------|
| `GMAIL_USER` | The Gmail address that sends the e-mails |
| `GMAIL_APP_PASSWORD` | A Google *App password* for that account (Google Account → Security → 2-Step Verification → App passwords) |
| `APP_URL` | Public URL of the app |

…or **Resend**:

| Secret | Value |
|--------|-------|
| `RESEND_API_KEY` | API key from resend.com (free tier: 3,000 e-mails/month) |
| `EMAIL_FROM` | `SplitSure <noreply@your-domain>` – the domain must be verified in Resend. Until then Resend only delivers to your own address. |
| `APP_URL` | Public URL of the app, e.g. `https://splitsure.app` |

The logo is served from `agreement-assets/branding/splitsure-logo.png` (public bucket).
Preview of the e-mail: `docs/agreement_email_preview_en.html` / `_fr.html`.

---

## 6. "Continue with Google" / "Sign up with Google"

The buttons sit below the login and sign-up forms. Until Google is enabled in Supabase they show
"Google sign-in isn't available yet" instead of an error page. Migration `009` gives Google accounts a
named profile and their photo.

1. Google Cloud Console → APIs & Services → Credentials → **Create OAuth client ID** → *Web application*.
   - Authorized JavaScript origins: your app URL (e.g. `https://splitsure.app`) and `http://localhost:8765` for testing.
   - Authorized redirect URI: `https://xcqdanlnbusgztrigfzg.supabase.co/auth/v1/callback`
2. Supabase → Authentication → **Sign In / Providers → Google** → enable, paste the Client ID and Client Secret, save.
3. Supabase → Authentication → **URL Configuration**: Site URL = your app URL; add the same URL and
   `http://localhost:8765` to *Redirect URLs*.
