# ParkiWell

ParkiWell is a Parkinson's care companion app for symptom tracking, medication scheduling, guided recovery exercises, and community support.

## Core Features

- Local-first symptom, medication, and therapy records with durable offline replay
- Deterministic conflict resolution and batched, idempotent Supabase synchronization
- On-device longitudinal analytics across medication timing, therapy adherence, and symptom severity
- Recovery hub (speech + physical exercise videos)
- Community feed with posts, comments, likes, and sharing
- Group membership and resource links in Community
- Light/dark mode with animated splash and onboarding
- Supabase authentication, PostgreSQL row-level security, and cross-device persistence

## Tech Stack

- Flutter 3.44.0
- Supabase (`supabase_flutter`) for auth + database
- Charts (`fl_chart`)
- Media (`youtube_player_iframe`, `video_player`)

## Getting Started

ParkiWell keeps health-record changes locally until Supabase acknowledges them, so
connectivity drops do not block logging or lose pending work. Supabase remains
the authenticated backend for cross-device persistence and community data.

### 1. Environment Setup

```bash
cp .env.example .env.local
# Fill in your Supabase project URL and anon key in .env.local
```

### 2. Run Locally

```bash
flutter pub get
./scripts/run-backend.sh
```

Or pass defines directly:

```bash
flutter run \
  --dart-define=BACKEND_PROVIDER=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.parkiwell.app://login-callback/
```

### 3. Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the schema in `supabase/schema.sql` via the SQL editor
3. Optional: run `supabase/seed.sql` to populate demo symptoms, medications, recovery exercise sessions, posts, comments, likes, and group memberships
4. Enable **Anonymous Sign-In** and **Google OAuth** in Authentication > Providers
5. Set the Google OAuth redirect URL to `com.parkiwell.app://login-callback/`

Full backend setup: `docs/BACKEND_SETUP.md`

## CI/CD and Branches

Primary branches:
- `main` (production)
- `staging` (pre-production verification)
- `develop` (integration)

Workflows:
- PR checks: analyze, format, tests, debug builds
- Staging build pipeline (push to `staging`)
- Production build and release pipeline (tag `v*`)

### Required GitHub Secrets

**Android (production):**
- `ANDROID_KEYSTORE_BASE64` -- base64-encoded `.jks` keystore
- `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`

**iOS (production):**
- `APPLE_CERTIFICATE_BASE64` -- base64-encoded `.p12` signing certificate
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_PROVISIONING_PROFILE_BASE64` -- base64-encoded `.mobileprovision`
- `APPLE_TEAM_ID` -- Apple Developer Team ID
- `APPLE_PROVISIONING_PROFILE_NAME` -- name of provisioning profile
- `KEYCHAIN_PASSWORD` -- temporary keychain password for CI

Environment/release setup: `docs/SETUP.md`

## Quality Checks

Run before pushing:

```bash
bash scripts/check-public-repo.sh
dart format --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

Release checklist: `docs/RELEASE_READINESS.md`

## Content Attribution

Therapy video sources and usage notes:
- `docs/CONTENT_SOURCES.md`

## Privacy and License

- Privacy policy: `PRIVACY_POLICY.md`
- Terms of service: `TERMS_OF_SERVICE.md`
- License: `LICENSE`

## Medical Disclaimer

ParkiWell is for education and self-tracking only.  
It is not a medical device and does not provide medical diagnosis or treatment.
