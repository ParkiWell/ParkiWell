# Backend Setup (Supabase)

This app works fully offline with local SQLite.  
Cloud sync is optional and can be enabled with Supabase.

## 1. Create a Supabase project

1. Create a project in Supabase.
2. Open SQL Editor and run `supabase/schema.sql`.
3. Copy:
- Project URL
- Project `anon` key

## 2. Run app with cloud backend enabled

Use Dart defines:

```bash
flutter run \
  --dart-define=BACKEND_PROVIDER=supabase \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Without these values, Levio runs in local-only mode.

## 3. Data model covered

Cloud sync currently supports:
- user profile (`users`)
- symptom logs (`logs`)
- medication schedules (`schedules`)
- community posts (`community_posts`)
- community comments (`community_comments`)

## 4. Capacity for thousands of users

The provided schema includes indexes for:
- per-user reads (`logs.user_id`, `schedules.user_id`)
- feed pagination (`community_posts.created_at`)
- comment fan-out (`community_comments.post_id`, `community_comments.created_at`)

Recommended production settings:
- enable daily backups
- enable connection pooling
- enable PITR (Point in Time Recovery)
- monitor p95 query latency and add composite indexes as feed size grows
- add moderation workflows for community content

## 5. Production hardening checklist

Before App Store release, complete:

1. Replace permissive bootstrap RLS policies with auth-bound policies.
2. Add Supabase Auth (email, OAuth, or anonymous + account linking).
3. Bind `user_id` columns to `auth.uid()` in policies.
4. Add request rate limits (Edge Functions/API gateway).
5. Add abuse controls for post/comment creation.
6. Run load tests on feed and comment endpoints.

## 6. Staging and production separation

Use separate Supabase projects:
- `levio-dev`
- `levio-staging`
- `levio-prod`

Set project-specific Dart defines in CI workflows for staging vs production builds.
