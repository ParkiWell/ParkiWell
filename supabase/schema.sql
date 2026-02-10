-- Levio Supabase schema (production-hardened)
--
-- This schema assumes Supabase Auth is enabled.
-- The mobile app establishes an authenticated session (anonymous or user auth)
-- and RLS binds write operations to auth.uid().

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.current_uid()
returns text
language sql
stable
as $$
  select auth.uid()::text;
$$;

create table if not exists public.users (
  id text primary key,
  name text not null default '[Name]',
  email text,
  age integer not null default 0,
  profile_image text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.logs (
  id text primary key,
  user_id text not null references public.users(id) on delete cascade,
  title text not null,
  data text not null,
  event_time text,
  symptom text,
  severity text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.schedules (
  id text primary key,
  user_id text not null references public.users(id) on delete cascade,
  title text not null,
  data text not null,
  details text,
  days text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.community_posts (
  id text primary key,
  user_id text not null references public.users(id) on delete cascade,
  user_name text not null,
  profile_image text,
  content text not null,
  category text,
  likes integer not null default 0,
  reports integer not null default 0,
  is_flagged boolean not null default false,
  is_hidden boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.community_comments (
  id text primary key,
  post_id text not null references public.community_posts(id) on delete cascade,
  user_id text not null references public.users(id) on delete cascade,
  user_name text not null,
  profile_image text,
  content text not null,
  reports integer not null default 0,
  is_flagged boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.community_post_likes (
  post_id text not null references public.community_posts(id) on delete cascade,
  user_id text not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (post_id, user_id)
);

create table if not exists public.community_group_memberships (
  group_id text not null,
  user_id text not null references public.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (group_id, user_id)
);

create index if not exists idx_logs_user_created
  on public.logs(user_id, created_at desc);
create index if not exists idx_schedules_user_created
  on public.schedules(user_id, created_at desc);
create index if not exists idx_posts_created
  on public.community_posts(created_at desc);
create index if not exists idx_posts_user_created
  on public.community_posts(user_id, created_at desc);
create index if not exists idx_comments_post_created
  on public.community_comments(post_id, created_at asc);
create index if not exists idx_comments_user_created
  on public.community_comments(user_id, created_at desc);
create index if not exists idx_post_likes_user_created
  on public.community_post_likes(user_id, created_at desc);
create index if not exists idx_group_memberships_user_created
  on public.community_group_memberships(user_id, created_at desc);
create index if not exists idx_group_memberships_group_created
  on public.community_group_memberships(group_id, created_at desc);

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists trg_logs_updated_at on public.logs;
create trigger trg_logs_updated_at
before update on public.logs
for each row execute function public.set_updated_at();

drop trigger if exists trg_schedules_updated_at on public.schedules;
create trigger trg_schedules_updated_at
before update on public.schedules
for each row execute function public.set_updated_at();

drop trigger if exists trg_posts_updated_at on public.community_posts;
create trigger trg_posts_updated_at
before update on public.community_posts
for each row execute function public.set_updated_at();

drop trigger if exists trg_comments_updated_at on public.community_comments;
create trigger trg_comments_updated_at
before update on public.community_comments
for each row execute function public.set_updated_at();

drop trigger if exists trg_group_memberships_updated_at on public.community_group_memberships;
create trigger trg_group_memberships_updated_at
before update on public.community_group_memberships
for each row execute function public.set_updated_at();

create or replace function public.increment_post_like(p_post_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.community_posts
    set likes = likes + 1,
        updated_at = timezone('utc', now())
  where id = p_post_id
    and is_hidden = false;
end;
$$;

revoke all on function public.increment_post_like(text) from public;
grant execute on function public.increment_post_like(text) to authenticated;

alter table public.users enable row level security;
alter table public.logs enable row level security;
alter table public.schedules enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
alter table public.community_post_likes enable row level security;
alter table public.community_group_memberships enable row level security;

drop policy if exists bootstrap_users_all on public.users;
drop policy if exists bootstrap_logs_all on public.logs;
drop policy if exists bootstrap_schedules_all on public.schedules;
drop policy if exists bootstrap_posts_all on public.community_posts;
drop policy if exists bootstrap_comments_all on public.community_comments;
drop policy if exists bootstrap_post_likes_all on public.community_post_likes;
drop policy if exists bootstrap_group_memberships_all on public.community_group_memberships;

drop policy if exists users_select_own on public.users;
drop policy if exists users_insert_own on public.users;
drop policy if exists users_update_own on public.users;
drop policy if exists users_delete_own on public.users;

create policy users_select_own on public.users
  for select to authenticated
  using (id = public.current_uid());

create policy users_insert_own on public.users
  for insert to authenticated
  with check (id = public.current_uid());

create policy users_update_own on public.users
  for update to authenticated
  using (id = public.current_uid())
  with check (id = public.current_uid());

create policy users_delete_own on public.users
  for delete to authenticated
  using (id = public.current_uid());

drop policy if exists logs_select_own on public.logs;
drop policy if exists logs_insert_own on public.logs;
drop policy if exists logs_update_own on public.logs;
drop policy if exists logs_delete_own on public.logs;

create policy logs_select_own on public.logs
  for select to authenticated
  using (user_id = public.current_uid());

create policy logs_insert_own on public.logs
  for insert to authenticated
  with check (user_id = public.current_uid());

create policy logs_update_own on public.logs
  for update to authenticated
  using (user_id = public.current_uid())
  with check (user_id = public.current_uid());

create policy logs_delete_own on public.logs
  for delete to authenticated
  using (user_id = public.current_uid());

drop policy if exists schedules_select_own on public.schedules;
drop policy if exists schedules_insert_own on public.schedules;
drop policy if exists schedules_update_own on public.schedules;
drop policy if exists schedules_delete_own on public.schedules;

create policy schedules_select_own on public.schedules
  for select to authenticated
  using (user_id = public.current_uid());

create policy schedules_insert_own on public.schedules
  for insert to authenticated
  with check (user_id = public.current_uid());

create policy schedules_update_own on public.schedules
  for update to authenticated
  using (user_id = public.current_uid())
  with check (user_id = public.current_uid());

create policy schedules_delete_own on public.schedules
  for delete to authenticated
  using (user_id = public.current_uid());

drop policy if exists posts_select_all on public.community_posts;
drop policy if exists posts_insert_own on public.community_posts;
drop policy if exists posts_update_own on public.community_posts;
drop policy if exists posts_delete_own on public.community_posts;

create policy posts_select_all on public.community_posts
  for select to authenticated
  using (is_hidden = false);

create policy posts_insert_own on public.community_posts
  for insert to authenticated
  with check (
    user_id = public.current_uid()
    and length(trim(content)) > 0
  );

create policy posts_update_own on public.community_posts
  for update to authenticated
  using (user_id = public.current_uid())
  with check (user_id = public.current_uid());

create policy posts_delete_own on public.community_posts
  for delete to authenticated
  using (user_id = public.current_uid());

drop policy if exists comments_select_all on public.community_comments;
drop policy if exists comments_insert_own on public.community_comments;
drop policy if exists comments_update_own on public.community_comments;
drop policy if exists comments_delete_own on public.community_comments;

create policy comments_select_all on public.community_comments
  for select to authenticated
  using (is_flagged = false);

create policy comments_insert_own on public.community_comments
  for insert to authenticated
  with check (
    user_id = public.current_uid()
    and length(trim(content)) > 0
  );

create policy comments_update_own on public.community_comments
  for update to authenticated
  using (user_id = public.current_uid())
  with check (user_id = public.current_uid());

create policy comments_delete_own on public.community_comments
  for delete to authenticated
  using (user_id = public.current_uid());

drop policy if exists post_likes_select_own on public.community_post_likes;
drop policy if exists post_likes_insert_own on public.community_post_likes;
drop policy if exists post_likes_delete_own on public.community_post_likes;

create policy post_likes_select_own on public.community_post_likes
  for select to authenticated
  using (user_id = public.current_uid());

create policy post_likes_insert_own on public.community_post_likes
  for insert to authenticated
  with check (user_id = public.current_uid());

create policy post_likes_delete_own on public.community_post_likes
  for delete to authenticated
  using (user_id = public.current_uid());

drop policy if exists group_memberships_select_own on public.community_group_memberships;
drop policy if exists group_memberships_insert_own on public.community_group_memberships;
drop policy if exists group_memberships_update_own on public.community_group_memberships;
drop policy if exists group_memberships_delete_own on public.community_group_memberships;

create policy group_memberships_select_own on public.community_group_memberships
  for select to authenticated
  using (user_id = public.current_uid());

create policy group_memberships_insert_own on public.community_group_memberships
  for insert to authenticated
  with check (user_id = public.current_uid());

create policy group_memberships_update_own on public.community_group_memberships
  for update to authenticated
  using (user_id = public.current_uid())
  with check (user_id = public.current_uid());

create policy group_memberships_delete_own on public.community_group_memberships
  for delete to authenticated
  using (user_id = public.current_uid());
