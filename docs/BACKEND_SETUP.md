# Backend Setup (Supabase, Cloud-Only)

Levio runs in **cloud-only mode**.
User profile, logs, schedules, community posts/comments/likes, and group membership all persist in Supabase.

## 1. Create a Supabase project


1. Create one Supabase project for active development.
2. In SQL Editor, run `supabase/schema.sql`.
3. In Auth settings:
   - enable **Anonymous sign-in**
   - enable **Google provider**
   - set redirect URL to `com.levio.app://login-callback/`
4. Run locally with Dart defines:

```bash
flutter run \
  --dart-define=BACKEND_PROVIDER=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.levio.app://login-callback/
```

Optional local helper:
- Create `.env.local` with `SUPABASE_URL`, `SUPABASE_ANON_KEY` (and optional `BACKEND_PROVIDER`, `SUPABASE_AUTH_REDIRECT_URL`).
- Run `scripts/run-backend.sh`.

Without these values, sign-in and sync fail (there is no local DB fallback).

## 2. Identity Fields Stored

On account creation/Google sign-in Levio stores:

- `uuid` (Supabase Auth user id) -> `users.id`
- `name` -> `users.name`
- `email` -> `users.email`
- `profile_image` -> `users.profile_image`

## 3. Production Checklist

Schema already includes:

- RLS policies tied to authenticated users
- indexes for logs/schedules/community feeds
- like increment RPC (`increment_post_like`)
- unique per-user post likes (`community_post_likes` primary key)
- persistent group membership (`community_group_memberships`)

Before production:

1. Enable PITR and backups in Supabase.
2. Add abuse/rate limits for post/comment endpoints.
3. Add monitoring/alerts for auth failures and latency.
4. Load test feed pagination and write throughput.

## 4. GitHub/CI Setup

If external contributors run CI or deploy from GitHub, configure environment variables/secrets:

- `BACKEND_PROVIDER=supabase`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_AUTH_REDIRECT_URL=com.levio.app://login-callback/`
