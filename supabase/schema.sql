-- Levio Supabase schema
-- NOTE:
-- Policies below are bootstrap policies so the current mobile client can sync.
-- Before production release, replace with auth-bound RLS policies.

create extension if not exists pgcrypto;

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
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
  content text not null,
  reports integer not null default 0,
  is_flagged boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
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

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row execute function set_updated_at();

drop trigger if exists trg_logs_updated_at on public.logs;
create trigger trg_logs_updated_at
before update on public.logs
for each row execute function set_updated_at();

drop trigger if exists trg_schedules_updated_at on public.schedules;
create trigger trg_schedules_updated_at
before update on public.schedules
for each row execute function set_updated_at();

drop trigger if exists trg_posts_updated_at on public.community_posts;
create trigger trg_posts_updated_at
before update on public.community_posts
for each row execute function set_updated_at();

drop trigger if exists trg_comments_updated_at on public.community_comments;
create trigger trg_comments_updated_at
before update on public.community_comments
for each row execute function set_updated_at();

alter table public.users enable row level security;
alter table public.logs enable row level security;
alter table public.schedules enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'bootstrap_users_all'
  ) then
    create policy bootstrap_users_all on public.users
      for all to anon, authenticated
      using (true)
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'logs'
      and policyname = 'bootstrap_logs_all'
  ) then
    create policy bootstrap_logs_all on public.logs
      for all to anon, authenticated
      using (true)
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'schedules'
      and policyname = 'bootstrap_schedules_all'
  ) then
    create policy bootstrap_schedules_all on public.schedules
      for all to anon, authenticated
      using (true)
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'community_posts'
      and policyname = 'bootstrap_posts_all'
  ) then
    create policy bootstrap_posts_all on public.community_posts
      for all to anon, authenticated
      using (true)
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'community_comments'
      and policyname = 'bootstrap_comments_all'
  ) then
    create policy bootstrap_comments_all on public.community_comments
      for all to anon, authenticated
      using (true)
      with check (true);
  end if;
end $$;
