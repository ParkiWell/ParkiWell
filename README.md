# Levio

Levio is a Parkinson's care companion app for symptom tracking, medication scheduling, guided recovery exercises, and community support.

## Core Features

- Symptom logging with severity tracking
- Medication schedule management
- Recovery hub (speech + physical exercise videos)
- Community feed with posts and comments
- Light and dark mode UI with animated onboarding/splash
- Local-first persistence (SQLite) with optional cloud sync

## Tech Stack

- Flutter 3.x
- Local DB: `sqflite` + secure key storage
- Optional cloud backend: `supabase_flutter`
- Charts: `fl_chart`
- Media: `youtube_player_iframe`

## Run Locally

```bash
flutter pub get
flutter run
```

## Optional Cloud Backend (Supabase)

By default, Levio runs local-only.

Enable cloud sync:

```bash
flutter run \
  --dart-define=BACKEND_PROVIDER=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Setup details:
- `docs/BACKEND_SETUP.md`
- `supabase/schema.sql`

## CI/CD and Branches

Primary branches:
- `main` (production)
- `staging` (pre-production verification)
- `develop` (integration)

Workflows:
- PR checks: analyze, tests, debug builds
- staging build pipeline
- production build and release pipeline

Environment/release setup:
- `docs/SETUP.md`

## Quality Checks

Run before pushing:

```bash
dart format --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
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
