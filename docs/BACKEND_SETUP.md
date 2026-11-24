# Optional Supabase setup

Use a Supabase project you control to test account sign-in, sync, or community
features. The [local-only setup](SETUP.md) is enough to run the core app.

1. Create a development project in Supabase. Run
   [`supabase/schema.sql`](../supabase/schema.sql) in its SQL Editor.
2. Enable email and anonymous sign-in under Authentication. Add
   `com.parkiwell.app://login-callback/` to the allowed redirect URLs.
   Configure Google or Apple only if you want to test that provider.
3. Copy the example configuration and fill in your project's URL and
   publishable or anon key.

```bash
cp .env.example .env.local
bash scripts/run-backend.sh
```

`SUPABASE_ANON_KEY` takes the public client key. Keep service-role and secret
keys in the backend environment. Use synthetic data when testing. The
[`supabase/seed.sql`](../supabase/seed.sql) file has optional sample data for
an isolated development project.

## Optional Edge Functions

Apply the schema before deploying either function. The account deletion
function uses a database trigger installed by the schema. The motion summary
function uses derived measurements and requires a server-side provider key.

```bash
supabase functions deploy delete_account
supabase functions deploy motion_summary
```

Run these commands with the Supabase CLI linked to your development project.
Configure `ANTHROPIC_API_KEY` in that project's Edge Function secrets if you
enable written motion summaries. See [Motion Coach feedback](MOTION_COACH_AI.md)
for what the app sends and how summaries are limited.
