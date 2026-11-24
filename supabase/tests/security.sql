-- Runs against the local CI schema and stub auth roles. All data is synthetic.
begin;

do $$
begin
  if has_function_privilege('anon',
       'public.claim_motion_summary_attempt(text,text,integer)', 'execute')
     or has_function_privilege('authenticated',
       'public.claim_motion_summary_attempt(text,text,integer)', 'execute')
     or not has_function_privilege('service_role',
       'public.claim_motion_summary_attempt(text,text,integer)', 'execute') then
    raise exception 'Unexpected motion summary claim privileges';
  end if;

  if has_column_privilege('authenticated', 'public.users', 'community_alias', 'insert')
     or has_column_privilege('authenticated', 'public.users', 'community_alias', 'update')
     or has_column_privilege('authenticated', 'public.community_posts', 'likes', 'insert')
     or has_column_privilege('authenticated', 'public.community_comments', 'is_flagged', 'insert')
     or has_table_privilege('authenticated', 'public.community_post_reports', 'insert')
     or has_table_privilege('authenticated', 'public.community_comment_reports', 'insert') then
    raise exception 'Community server-owned fields are writable by clients';
  end if;
end $$;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000002');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000001', true);
select set_config('request.jwt.claims', '{"is_anonymous":false}', true);

insert into public.users (id, name) values
  ('00000000-0000-0000-0000-000000000001', 'Test Member');
insert into public.community_posts (id, user_id, user_name, content) values
  ('test-post', '00000000-0000-0000-0000-000000000001', 'Test Member', 'Hello');

do $$
declare
  cutoff timestamptz := now() - interval '1 hour';
  old_session jsonb := jsonb_build_object(
    'entity_type', 'motionSession', 'entity_id', 'older-session',
    'operation', 'upsert', 'mutation_id', 'old-write',
    'payload', jsonb_build_object('completed_at', cutoff - interval '1 minute')
  );
  late_session jsonb := jsonb_build_object(
    'entity_type', 'motionSession', 'entity_id', 'offline-session',
    'operation', 'upsert', 'mutation_id', 'late-write',
    'payload', jsonb_build_object('completed_at', cutoff)
  );
  new_session jsonb := jsonb_build_object(
    'entity_type', 'motionSession', 'entity_id', 'newer-session',
    'operation', 'upsert', 'mutation_id', 'new-write',
    'payload', jsonb_build_object('completed_at', cutoff + interval '1 minute')
  );
  deletion_state jsonb;
begin
  perform public.apply_health_mutations(jsonb_build_array(old_session, new_session));
  if public.delete_my_motion_sessions(cutoff) <> 1 then
    raise exception 'The sweep should delete the one older session';
  end if;
  if public.delete_my_motion_sessions(cutoff - interval '1 minute') <> 0 then
    raise exception 'Retrying an older sweep should preserve the newer session';
  end if;

  perform public.apply_health_mutations(jsonb_build_array(old_session, late_session));
  if (select array_agg(id) from public.motion_sessions) is distinct from
       array['newer-session']::text[] then
    raise exception 'Only the session completed after the sweep should remain';
  end if;

  deletion_state := public.get_my_motion_session_deletions(array['older-session']);
  if (deletion_state ->> 'cutoff')::timestamptz is distinct from cutoff
     or deletion_state -> 'deleted_ids' is distinct from '["older-session"]'::jsonb then
    raise exception 'The owner should read the sweep cutoff and requested tombstone';
  end if;
end $$;

select public.apply_health_mutations('[{
  "entity_type":"motionSession", "entity_id":"second-session",
  "operation":"upsert", "mutation_id":"second-write"
}]'::jsonb);

select set_config('request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000002', true);
insert into public.users (id, name) values
  ('00000000-0000-0000-0000-000000000002', 'Other Member');
select public.report_post('test-post', 'Off topic');

do $$
begin
  if (select reports from public.community_posts where id = 'test-post') <> 1 then
    raise exception 'A submitted report should update moderation state';
  end if;
  if public.get_my_motion_session_deletions(array['older-session'])
       is distinct from '{"cutoff":null,"deleted_ids":[]}'::jsonb then
    raise exception 'Motion deletion state should be scoped to the current owner';
  end if;
end $$;

reset role;
insert into public.motion_summary_attempt_events (user_id, attempted_at)
select '00000000-0000-0000-0000-000000000001'::uuid, now()
from generate_series(1, 19);

set local role service_role;
do $$
begin
  if not public.claim_motion_summary_attempt(
    'newer-session', '00000000-0000-0000-0000-000000000001', 3
  ) then
    raise exception 'The twentieth summary attempt should be available';
  end if;
  if public.claim_motion_summary_attempt(
    'second-session', '00000000-0000-0000-0000-000000000001', 3
  ) then
    raise exception 'The rolling quota should cap the account at twenty attempts';
  end if;
end $$;

reset role;
delete from auth.users where id = '00000000-0000-0000-0000-000000000001';
do $$
begin
  if exists (select 1 from public.users where id = '00000000-0000-0000-0000-000000000001')
     or exists (select 1 from public.motion_sessions)
     or exists (select 1 from public.community_posts)
     or exists (select 1 from public.motion_history_deletions)
     or exists (select 1 from public.motion_summary_attempt_events) then
    raise exception 'Deleting the test auth identity should cascade to account data';
  end if;
end $$;

rollback;
