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

-- Public check-in for index.html. Visitors can add a student and mark them
-- present for today, but cannot read the tables.
create or replace function public.check_in(p_name text, p_student_id text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g'));
  v_id text := upper(regexp_replace(coalesce(p_student_id, ''), '\s+', '', 'g'));
  v_student public.students%rowtype;
  v_marked_at timestamptz;
  v_latin text;
  v_chunk text;
begin
  if v_name = '' or char_length(v_name) < 2 then
    raise exception 'Enter your full name.' using errcode = '22023';
  end if;
  if char_length(v_name) > 60 then
    raise exception 'That name is too long.' using errcode = '22023';
  end if;
  if v_id !~ '^PS/ITC/25/[0-9]{4}$' then
    raise exception 'Use the format PS/ITC/25/0000.' using errcode = '22023';
  end if;

  -- Reject keyboard-mash so "asdfgh" or "qwerty" is never stored, even when
  -- this function is called directly instead of through the form. Only Latin
  -- script is judged; a name in another alphabet is left alone.
  v_latin := lower(regexp_replace(v_name, '[^a-z]', '', 'g'));

  if v_latin <> '' then
    if v_latin !~ '[aeiouy]'        -- no vowel: "asdfgh", "hjkl"
       or v_latin ~ '^(.)\1+$'      -- one letter repeated: "aaaa"
       or v_latin ~ '(.)\1\1'       -- long runs of a letter: "hgggg"
    then
      raise exception 'That does not look like a real name.' using errcode = '22023';
    end if;

    -- Four letters in a row: alphabetical ("abcdefg"), or lying on one
    -- keyboard row ("asdf", "qwer", "hjkl", "zxcv"), in either direction.
    for i in 1 .. char_length(v_latin) - 3 loop
      v_chunk := substr(v_latin, i, 4);
      if position(v_chunk in 'abcdefghijklmnopqrstuvwxyz') > 0
         or position(v_chunk in 'zyxwvutsrqponmlkjihgfedcba') > 0
         or position(v_chunk in 'qwertyuiop') > 0
         or position(v_chunk in 'poiuytrewq') > 0
         or position(v_chunk in 'asdfghjkl') > 0
         or position(v_chunk in 'lkjhgfdsa') > 0
         or position(v_chunk in 'zxcvbnm') > 0
         or position(v_chunk in 'mnbvcxz') > 0
      then
        raise exception 'That does not look like a real name.' using errcode = '22023';
      end if;
    end loop;
  end if;

  select * into v_student from public.students where student_id = v_id;

  if found then
    if lower(btrim(v_student.name)) <> lower(v_name) then
      raise exception 'That ID belongs to a different student.' using errcode = 'P0001';
    end if;
  else
    if exists (select 1 from public.students where lower(btrim(name)) = lower(v_name)) then
      raise exception 'That name is already registered with a different ID.' using errcode = 'P0001';
    end if;

    insert into public.students (student_id, name)
    values (v_id, v_name)
    returning * into v_student;
  end if;

  begin
    insert into public.attendance (student_id, date)
    values (v_id, current_date)
    returning marked_at into v_marked_at;
  exception
    when unique_violation then
      raise exception 'Already marked present for today.' using errcode = 'P0001';
  end;

  return jsonb_build_object(
    'name', v_student.name,
    'student_id', v_id,
    'date', current_date,
    'marked_at', v_marked_at
  );
end;
$$;

revoke all on function public.check_in(text, text) from public;
grant execute on function public.check_in(text, text) to anon, authenticated;
