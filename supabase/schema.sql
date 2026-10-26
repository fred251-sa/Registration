-- Information Technology attendance register
-- Run this once in the Supabase SQL editor of a new project.

create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  student_id text not null unique,
  name text not null,
  created_at timestamptz not null default now(),
  constraint students_id_format check (student_id ~ '^PS/ITC/25/[0-9]{4}$'),
  constraint students_name_length check (char_length(btrim(name)) between 2 and 60)
);

-- One student per name, ignoring case and outer spaces.
create unique index if not exists students_name_unique
  on public.students (lower(btrim(name)));

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id text not null references public.students (student_id) on delete cascade,
  date date not null,
  marked_at timestamptz not null default now(),
  unique (student_id, date)
);

create index if not exists attendance_date_idx on public.attendance (date);

alter table public.admins enable row level security;
alter table public.students enable row level security;
alter table public.attendance enable row level security;

-- The check lives in a schema that the API does not expose.
create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon;
grant usage on schema private to authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

revoke all on function private.is_admin() from public;
revoke all on function private.is_admin() from anon;
grant execute on function private.is_admin() to authenticated;

drop policy if exists "admins read own row" on public.admins;
create policy "admins read own row" on public.admins
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "students admin access" on public.students;
create policy "students admin access" on public.students
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

drop policy if exists "attendance admin access" on public.attendance;
create policy "attendance admin access" on public.attendance
  for all to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- No policies for the anon role: without a signed-in administrator account,
-- the tables return nothing and reject writes.
