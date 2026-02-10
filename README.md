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

## Solo Maintainer Setup (Primary)

Levio is configured for cloud-only storage.  
Run with Supabase defines:

```bash
flutter pub get
flutter run \
  --dart-define=BACKEND_PROVIDER=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.levio.app://login-callback/
```

Full backend setup:
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
