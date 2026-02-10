# Environment Setup Guide

## Branch Protection Rules

Configure these rules in GitHub repository settings under Settings > Branches.

### Main Branch Protection

Branch: `main`

- [x] Require a pull request before merging
  - [x] Require approvals: 1
  - [x] Dismiss stale pull request approvals when new commits are pushed
  - [x] Require review from Code Owners
- [x] Require status checks to pass before merging
  - [x] Require branches to be up to date before merging
  - Status checks required:
    - `Code Analysis`
    - `Run Tests`
    - `Build Android`
    - `Build iOS`
- [x] Require conversation resolution before merging
- [x] Do not allow bypassing the above settings

### Staging Branch Protection

Branch: `staging`

- [x] Require a pull request before merging
  - [x] Require approvals: 1
- [x] Require status checks to pass before merging
  - Status checks required:
    - `Code Analysis`
    - `Run Tests`

### Develop Branch Protection

Branch: `develop`

- [x] Require status checks to pass before merging
  - Status checks required:
    - `Code Analysis`

## GitHub Environments

Create these environments in Settings > Environments:

### staging

- Protection rules: None (auto-deploy on push)
- Environment secrets:
  - `ANDROID_KEYSTORE_BASE64` (optional for staging)
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_STORE_PASSWORD`

### production

- Protection rules:
  - [x] Required reviewers: 1
  - [x] Wait timer: 5 minutes (optional)
- Environment secrets:
  - `ANDROID_KEYSTORE_BASE64` (required)
  - `ANDROID_KEY_ALIAS` (required)
  - `ANDROID_KEY_PASSWORD` (required)
  - `ANDROID_STORE_PASSWORD` (required)
  - `APPLE_CERTIFICATE_BASE64`
  - `APPLE_CERTIFICATE_PASSWORD`
  - `APPLE_PROVISIONING_PROFILE_BASE64`
  - `KEYCHAIN_PASSWORD`

## Creating Android Keystore Secret

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore levio-release.jks -keyalias levio -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Convert to base64:
   ```bash
   base64 -i levio-release.jks -o keystore.txt
   ```

3. Add the contents of `keystore.txt` as `ANDROID_KEYSTORE_BASE64` secret

## Release Process

### Staging Release

1. Merge feature branches into `develop`
2. Create PR from `develop` to `staging`
3. Merge PR - triggers staging build automatically
4. Download and test staging APK from GitHub Actions artifacts

### Production Release

1. Ensure staging is tested and approved
2. Create PR from `staging` to `main`
3. Get required approvals
4. Merge PR
5. Create a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
6. Production build triggers automatically
7. Verify draft release in GitHub Releases
8. Edit release notes and publish

## Backend Environments (Supabase)

For cloud sync, create separate Supabase projects:

- `levio-dev` - Development
- `levio-staging` - Staging
- `levio-prod` - Production

Set environment-specific Dart defines in your build and run commands:

```bash
--dart-define=BACKEND_PROVIDER=supabase \
--dart-define=SUPABASE_URL=... \
--dart-define=SUPABASE_ANON_KEY=...
```

When these values are not provided, Levio runs in local-only mode (SQLite on-device).
