# Branching and CI/CD

ParkiWell uses long-lived environment branches plus short-lived feature branches.

## Branches

- `develop`: day-to-day integration branch for active work.
- `testing`: QA branch for test builds and internal verification.
- `staging`: release-candidate branch that should mirror the next production release.
- `production`: production branch for deployable app releases.
- `main`: repository default branch; keep protected and use it for stable project state if needed.

Feature branches should branch from `develop` and merge back through pull requests.

## Promotion Flow

1. Merge feature work into `develop`.
2. Promote `develop` into `testing` for QA builds.
3. Promote tested changes into `staging` for release-candidate builds.
4. Promote approved staging changes into `production`.
5. Tag production releases with `vX.Y.Z` when creating a GitHub release.

## CI/CD Workflows

- Pull request checks run on `main`, `develop`, `testing`, `staging`, and `production`.
- `testing` branch runs `Build Testing`, producing debug Android and iOS simulator artifacts.
- `staging` branch runs `Build Staging`, producing release candidate artifacts.
- `production` branch and `v*` tags run `Build Production`, producing production artifacts and draft releases for tags.

## Cloud Backend Checks

PR, testing, staging, and production workflows validate:

- Flutter formatting, analysis, and tests.
- Supabase schema presence and required RLS policy snippets.
- Cloud backend source analysis.
- Supabase `--dart-define` configuration through `test/cloud_backend_config_test.dart`.

Configure GitHub environment variables/secrets per environment:

- Variable: `BACKEND_PROVIDER` set to `supabase` when cloud sync should be enabled.
- Secret: `SUPABASE_URL`.
- Secret: `SUPABASE_ANON_KEY`.
- Variable: `SUPABASE_AUTH_REDIRECT_URL` if different from `com.parkiwell.app://login-callback/`.
