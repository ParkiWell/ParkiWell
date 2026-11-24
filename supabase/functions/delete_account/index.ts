// Deletes the calling user's auth identity and owned data in one transaction.
//
// The client cannot delete a Supabase auth user with the publishable key,
// so "Delete Account" must go through this function or the email/OAuth
// identity survives forever. Apply supabase/schema.sql before deploying:
//   supabase functions deploy delete_account
// Requires the service role key, which the Edge runtime injects as
// SUPABASE_SERVICE_ROLE_KEY.

import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }
  const token = req.headers.get("Authorization")?.match(/^Bearer (\S+)$/i)?.[1];
  if (!token) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  // Resolve the caller from their JWT with the anon key; the privileged
  // client below is used only after the identity is proven.
  const userClient = createClient(supabaseUrl, anonKey);
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(token);
  if (userError || !user) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);

  // The auth.users trigger removes the profile and dependent data in the
  // same transaction as the auth identity.
  const { error: authError } = await admin.auth.admin.deleteUser(user.id);
  if (authError) {
    return Response.json({ error: "auth_deletion_failed" }, { status: 500 });
  }

  return Response.json({ ok: true });
});
