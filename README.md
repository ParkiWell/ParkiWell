# Levio

Levio is a Parkinson's care companion app for symptom tracking, medication scheduling, guided recovery exercises, and community support.

## Core Features

- Symptom logging with severity tracking
- Medication schedule management
- Recovery hub (speech + physical exercise videos)
- Community feed with posts, comments, likes, and sharing
- Group membership and resource links in Community
- Light/dark mode with animated splash and onboarding
- Cloud-only persistence with Supabase

## Tech Stack

- Flutter 3.x
- Supabase (`supabase_flutter`) for auth + database
- Charts (`fl_chart`)
- Media (`youtube_player_iframe`, `video_player`)

## Getting Started

Levio is cloud-only with Supabase as its backend.

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
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.levio.app://login-callback/
```

### 3. Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the schema in `supabase/schema.sql` via the SQL editor
3. Enable **Anonymous Sign-In** and **Google OAuth** in Authentication > Providers
4. Set the Google OAuth redirect URL to `com.levio.app://login-callback/`

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
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Content Attribution

Therapy video sources and usage notes:
- `docs/CONTENT_SOURCES.md`

## Privacy and License

- Privacy policy: `PRIVACY_POLICY.md`
- License: `LICENSE`

## Medical Disclaimer

Levio is for education and self-tracking only.  
It is not a medical device and does not provide medical diagnosis or treatment.
