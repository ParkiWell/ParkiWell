# GitHub Environment Setup Guide

This document is for **GitHub repository operations** (external contributors, CI/CD hardening, release process).  
If you are the sole maintainer, use this as optional reference.

## 1. Solo Maintainer Mode (Recommended Default)

If you are working alone:

1. Keep `main` as your primary branch.
2. Run checks locally before push:
   - `dart format --set-exit-if-changed lib test`
   - `flutter analyze`
   - `flutter test`
3. Use production workflow when you are ready to build/release.

You do not need strict PR approvals/branch protection for solo development unless you want them.

## 2. Collaboration Mode (For Other People)

If others contribute through GitHub, configure branch protection under **Settings > Branches**:

### `main`

- Require pull request before merge
- Require status checks:
  - `Code Analysis`
  - `Run Tests`
  - `Build Android`
  - `Build iOS`
- Require conversation resolution
- Restrict direct pushes

### `staging`

- Require pull request before merge
- Require status checks:
  - `Code Analysis`
  - `Run Tests`

### `develop`

- Require status checks:
  - `Code Analysis`

## 3. GitHub Environments

Create environments in **Settings > Environments**:

### `staging`

- Optional protection rules
- Secrets:
  - `ANDROID_KEYSTORE_BASE64` (optional)
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_STORE_PASSWORD`

### `production`

- Optional required reviewer / wait timer
- Secrets:
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_STORE_PASSWORD`
  - `APPLE_CERTIFICATE_BASE64`
  - `APPLE_CERTIFICATE_PASSWORD`
  - `APPLE_PROVISIONING_PROFILE_BASE64`
  - `KEYCHAIN_PASSWORD`

## 4. Android Keystore Secret

1. Generate keystore:
   ```bash
   keytool -genkey -v -keystore levio-release.jks -keyalias levio -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Convert to base64:
   ```bash
   base64 -i levio-release.jks -o keystore.txt
   ```
3. Save as `ANDROID_KEYSTORE_BASE64` secret.

## 5. Release Flow (When Using GitHub Collaboration)

### Staging

1. Merge features to `develop`
2. PR `develop -> staging`
3. Merge PR to trigger staging builds

### Production

1. PR `staging -> main`
2. Merge after checks
3. Tag release:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. Publish release artifacts from GitHub Actions

## 6. Backend Environment Variables

Levio uses Supabase for authenticated cloud persistence and keeps pending
health-record mutations in an on-device journal for offline replay.
Use these defines for local/CI builds:

```bash
--dart-define=BACKEND_PROVIDER=supabase \
--dart-define=SUPABASE_URL=... \
--dart-define=SUPABASE_ANON_KEY=... \
--dart-define=SUPABASE_AUTH_REDIRECT_URL=com.levio.app://login-callback/
```

If defines are missing, authentication and sync will fail.
