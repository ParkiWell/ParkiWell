# Backend Setup (Supabase + Local-First Sync)

ParkiWell stores pending health-record mutations on-device and replays them to
Supabase after connectivity returns. User profiles, logs, schedules, medication
events, recovery sessions, community posts/comments/likes, and group membership
persist in Supabase for authenticated cross-device access.

## 1. Create a Supabase project


1. Create one Supabase project for active development.
2. In SQL Editor, run `supabase/schema.sql`.
3. Optional: run `supabase/seed.sql` to populate sample profile data, symptom logs, medication schedules, recovery exercise sessions, community posts, comments, likes, and group memberships.
   - To see private demo data in-app, replace `demo_user_id` at the top of `supabase/seed.sql` with the UUID of the Supabase Auth user you use for demos.
   - If you leave the placeholder id unchanged, seeded community posts/comments are visible to authenticated users, but private logs/schedules/recovery sessions stay scoped to the placeholder user.
4. In Auth settings:
   - enable **Anonymous sign-in**
   - enable **Google provider**
   - set redirect URL to `com.parkiwell.app://login-callback/`
5. Run locally with Dart defines:

```bash
flutter run \
  --dart-define=BACKEND_PROVIDER=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.parkiwell.app://login-callback/
```

Optional local helper:
- Create `.env.local` with `SUPABASE_URL`, `SUPABASE_ANON_KEY` (and optional `BACKEND_PROVIDER`, `SUPABASE_AUTH_REDIRECT_URL`).
- Run `scripts/run-backend.sh`.

Without these values, sign-in and cloud synchronization are unavailable. The
mutation journal is an offline queue, not a replacement authentication system
or standalone database.

## 2. Identity Fields Stored

On account creation/Google sign-in ParkiWell stores:

- `uuid` (Supabase Auth user id) -> `users.id`
- `name` -> `users.name`
- `email` -> `users.email`
- `profile_image` -> `users.profile_image`

## 3. Production Checklist

Schema already includes:

- RLS policies tied to authenticated users
- indexes for logs/schedules/community feeds
- recovery session storage for physical and speech exercise completion history
- medication-adherence event storage for longitudinal analysis
- batched `apply_health_mutations` RPC with deterministic last-write-wins conflict resolution
- per-user sync tombstones that prevent stale offline writes from resurrecting deleted records
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
- `SUPABASE_AUTH_REDIRECT_URL=com.parkiwell.app://login-callback/`
