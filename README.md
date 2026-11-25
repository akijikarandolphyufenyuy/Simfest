# SplitSure

**Protect your music. Promote your sound.**

SplitSure is a Flutter Web PWA built for music creators in Africa. It lets artists collaborate, protect their work through digital split agreements, promote their sound, and connect with opportunities — all in one place.

## Core Features

- **Protect** – Draft and send split agreements for review, collect digital approvals, track version history, and generate a final signed PDF (Free preview / Pro or pay-per-document unlock).
- **Music Passport** – A public artist profile with portfolio, roles, genres, and contact preferences. Shareable via `/#/passport/:slug`.
- **Opportunity Hub** – Post and discover collaboration opportunities. Free users get one post; Pro users post unlimited.
- **DealFlow** – Negotiate terms with collaborators in a shared workspace, then push directly into a Protect agreement.
- **Reach** – Generate promo videos and captions for campaigns (Pro only).
- **Payments** – Mobile Money (MTN / Orange) via MeSomb Edge Function. Pro plan: 100 FCFA one-time. Final agreement unlock: 50 FCFA.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web (Dart) |
| State management | Riverpod |
| Navigation | go_router |
| Backend / DB | Supabase (Postgres + RLS + Edge Functions) |
| Payments | MeSomb (via Supabase Edge Function) |
| Push notifications | Firebase Cloud Messaging |
| Localisation | EN / FR (Flutter l10n) |

---

## Running the App

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- A Supabase project with migrations applied (see [SETUP.md](SETUP.md))
- Chrome or Edge (recommended for full PWA + video generation support)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure environment

Set your Supabase URL and anon key in `lib/core/constants/supabase_config.dart`.

### 3. Run in development

```bash
flutter run -d chrome
```

### 4. Build for production

```bash
flutter build web --release
# Deploy the contents of build/web to your hosting (Vercel, Firebase Hosting, etc.)
```

### Regenerate PWA icons (after changing the logo)

```bash
dart run tool/generate_icons.dart
```

---

## Database Setup

Run the migrations in `supabase/migrations/` in order (001 → 015) via the Supabase SQL Editor.  
See [SETUP.md](SETUP.md) for the full setup guide including Edge Functions, push notifications, and payment secrets.
