# SplitSure – Opportunity Hub, Music Passport, Free/Pro & Payments
Implementation plan (Phase 1 audit result). Status: decisions D1, D2, D4 confirmed (D4 = 4 tabs + "More" sheet). Phases 2–9 implemented 2026-11-23; migration 004 applied live; `payments` function deployed (MeSomb secrets pending).

## 0. Decisions needed before building

| # | Decision | Recommendation |
|---|----------|----------------|
| D1 ✅ Replace | The app currently sells Monthly 1,000 / 3-Month 2,500 / Annual 5,000 FCFA plans. The new spec defines Free + **Pro 100 FCFA one-time**. | **Replace** the three paid plans with Pro. Keep the `plans` / `plan_features` tables so recurring Pro can be added later by setting `duration_days`. |
| D2 ✅ Move | MeSomb keys are hard-coded in `lib/core/services/mesomb_service.dart` (live `sk_live_…`). A web build would expose them to every visitor. | Move all MeSomb calls into a Supabase Edge Function (`payments`) that reads the keys from Supabase secrets; delete the Flutter-side keys; **rotate the keys** in the MeSomb dashboard. |
| D3 | Deploying Edge Functions + setting secrets. | Do it in the Supabase dashboard (Edge Functions → Deploy via editor, Secrets) in the browser pane while you're signed in, or with the Supabase CLI if you have it. |
| D4 ✅ Bottom bar + More | The spec lists 8 navigation items; the mobile floating bar fits 5. | Mobile bar: **Home · Protect · Hub · Reach · Profile**. Music Passport, My Projects and Notifications open from the dashboard header/cards and from Profile. Desktop sidebar shows all 8. |
| D5 | MeSomb keys are live: testing Pro (100 FCFA) and agreement (50 FCFA) payments charges real money and needs a phone to approve on. | You approve 1–2 real test payments on your own number when we reach Phase 8. |
| D6 | Social-account linking (TikTok/Instagram/Facebook publishing) needs registered developer apps + platform review (credentials we don't have). | Reach generates copy/download-ready content and stores public profile links; real OAuth publishing is listed as a follow-up needing those developer apps. |

## 1. Audit summary (what exists)

**App**: Flutter Web PWA, Riverpod, go_router (`/welcome /onboarding /login /register /home /invite/:token`), `MainShell` with 5 tabs (Home, Protect, Reach, Alerts, Profile) + desktop sidebar. Shared UI: `AppSliverHeader`, `FadeSlideIn`, `form_widgets.dart`, l10n EN/FR (~545 keys, `l10n_helpers.dart`).

**Protect**: drafts → `send_agreement_for_review` → `respond_to_agreement` (accept / changes / decline), versions + response log, invite links, PDF built client-side and stored in private `agreement-pdfs`.

**Reach**: campaigns, snippet picker, template captions/hashtags, in-browser 9:16 video generator.

**Projects**: `projects` table + My Projects screen; agreements/campaigns link via `project_id`.

**Plans/payments**: `plans`, `plan_features` (limits), `subscriptions` (demo-only inserts), `plan_limits.dart`. Demo payment sheet. `mesomb_service.dart` (unused, insecure — see D2).

**Notifications**: `notifications(kind, params)` + `notify_user()` (respects prefs) + Realtime badge + `send-push` Edge Function (needs deploy + webhook).

**Live DB** (project `xcqdanlnbusgztrigfzg`): migrations 002 + 003 applied. Note: the live schema predates `001_initial_schema.sql` (it used `owner_id`); always check `information_schema` before new SQL.

## 2. Data model (migration `004_hub_passport_pro.sql`)

Reuse where possible; new tables only where nothing exists.

| Table | Purpose | Key rules |
|-------|---------|-----------|
| `user_entitlements` | One row per user: `plan_type free/pro`, `subscription_status`, `pro_activated_at`, `pro_expires_at`, `payment_status`, `free_posts_used` | Clients **read own row only**; writes only via `security definer` functions called by the payments function. Created by the sign-up trigger. |
| `payment_transactions` | `reference` (unique), `user_id`, `type PRO_UPGRADE/AGREEMENT_GENERATION`, `amount_fcfa`, `provider MTN/ORANGE`, `phone`, `status pending/success/failed/cancelled`, `provider_tx_id`, `target_id` (agreement), raw response | Read own; insert/update only by the Edge Function (service role). Unique partial index so one agreement can't be paid twice. |
| `agreement_documents` | `agreement_id` (unique), `unlocked_via pro/payment`, `transaction_id`, `pdf_path`, `generated_at` | Parties read; row created only by `unlock_agreement_generation()`; storage upload policy for the final PDF requires this row. |
| `music_passports` | `user_id` (unique), `slug` (unique), names, photo, primary/secondary roles, location, bio, contact + preferred method, years, genres, instruments, languages, availability, arrangements, links (jsonb), `visibility` jsonb (per-section public flags), `is_published` | Owner full access; anyone can read **published** passports via a `public_passports` view that only returns fields marked public. |
| `passport_portfolio_items` | type (`release, album, production_credit, writing_credit, collaboration, video, award, experience, project`), title, role, year, url, image_path, description, `is_public` | Owner writes; readable when passport published and item public. |
| `collaboration_opportunities` | owner, title, description, category, `required_roles[]`, skills[], genres[], location, `collaboration_type`, compensation, deliverables, deadlines, positions, reference links, requirements, `restrict_to_roles`, `status open/closed` | Insert allowed only if `can_post_opportunity()` (Pro, or `free_posts_used = 0`); trigger increments `free_posts_used` (never decremented on delete). Read: owner, or open + (no role restriction or viewer's passport roles overlap). |
| `opportunity_applications` | opportunity, applicant, message, links[], `status pending/under_review/shortlisted/accepted/rejected/withdrawn` | Unique (opportunity, applicant). Applicant reads/withdraws own; owner reads + changes status via `set_application_status()` (notifies). |
| `collaboration_workspaces` | from opportunity, owner, title, description, `status negotiating/agreed/in_protect/active/completed`, `agreement_id` | Members only. |
| `workspace_members` | user, role, responsibilities, proposed %, `agreed` flag | Members read; owner manages; member edits own proposal. |
| `workspace_messages` | negotiation thread | Members read/insert. |

Reuse: `notifications` + `notify_user` (new kinds), `projects`, `agreements`/Protect RPCs, storage buckets (+ `passport-media` public bucket, owner-folder writes).

## 3. Backend (trusted) – Edge Function `payments`
- `POST /initiate {type, provider, phone, target_id?}` → validates user/price/target, inserts `payment_transactions` (pending, unique reference, idempotent per user+type+target while pending), calls MeSomb `collect` with the reference as nonce/external id, stores result.
- `POST /verify {reference}` → re-checks status with MeSomb's transaction-status API; on SUCCESS runs `grant_payment(reference)` once (status `pending→success` guarded with `for update`), which activates Pro or unlocks the agreement and sends notifications. Failure/cancel → Free kept, retry allowed.
- Secrets: `MESOMB_APP_KEY`, `MESOMB_ACCESS_KEY`, `MESOMB_SECRET_KEY` (never in Flutter).

## 4. App work by phase
- **P2 Plans**: plan-selection screen after sign-up (Free / Pro 100 FCFA), `entitlementProvider`, dashboard plan card (Free → Upgrade; Pro → active since …), Subscription screen rewritten to Free/Pro + transaction history; `plan_limits.dart` switched to entitlements.
- **P3 Passport**: 4-step wizard (identity, professional, portfolio, review), edit anytime, per-section visibility, public page route `/#/passport/:slug` (works signed-out), share link.
- **P4 Hub**: create/edit/close/reopen/delete, free-post limit with upgrade prompt, discovery (search + role/genre/location/compensation/category/date filters, "Recommended for you" from passport roles), detail with owner passport, apply flow, my applications, owner applicant dashboard.
- **P5 DealFlow**: accept applicant → create workspace; members, roles, responsibilities, % proposals, discussion; "Agree" per member; "Continue in Protect" pre-fills `CreateAgreementScreen` and links the agreement back.
- **P6 Protect monetisation**: "Generate final agreement" → Pro: unlock directly (server); Free: 50 FCFA payment sheet → verify → unlock; final PDF stored once and visible to all parties; drafts/preview stay free.
- **P7 Reach**: Pro-only gate screen (benefits + 100 FCFA Upgrade); campaigns insert requires Pro server-side; add bio/announcement generators using Passport + project data.
- **P8 Payments**: payment sheet (MTN / Orange, phone, waiting-for-approval state, retry), history.
- **P9 Notifications**: new kinds (application received/shortlisted/accepted/rejected, workspace created, member added, terms updated, agreement awaiting approval/approved, payment success/failed, Pro activated, recommended opportunity) — localized in-app + push.
- **P10 Testing**: analyzer, RLS checks with two accounts (needs a second test account), real payment test (D5), mobile + desktop.

## 5. Out of scope / needs external setup
- Social-network OAuth publishing (D6). - Dispute workflow (status shown only if added later).
- A second user account is needed to test cross-user flows (applications, workspaces).
