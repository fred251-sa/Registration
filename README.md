# Information Technology Attendance Register

Attendance register for Information Technology students. The page is static, but names,
student IDs and attendance are stored in a Supabase database. Only the administrator account
can read or write them.

## Using it

1. Sign in with the administrator email and password.
2. Type the student's full name.
3. Type the student ID.
4. Pick the date (it defaults to today).
5. Press **Mark present**.

Student IDs use the format `PS/ITC/25/0000`. Typing only the serial number completes it:
`12` becomes `PS/ITC/25/0012`.

## Duplicate checks

An entry is rejected when:

- the ID is already registered to a different name,
- the name is already registered with a different ID,
- the student is already marked for the selected date.

The database enforces the same rules, so they hold even if two people use the page at once.
Case and extra spaces are ignored. A student can be marked on other dates; that is normal
daily use.

## Setup

You need a Supabase project (the free plan is enough).

1. Create a project at https://supabase.com/dashboard.
2. Open **SQL Editor**, paste `supabase/schema.sql`, and run it once.
3. Open **Authentication, Users, Add user**. Create the administrator with an email and
   password. Turn on **Auto Confirm User** so no confirmation email is needed.
4. Copy the new user's ID and run this in the SQL Editor, replacing the email:

   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'you@example.com';
   ```

5. Open **Project Settings, API**. Copy the **Project URL** and the **publishable** key
   (or the `anon` key on older projects).
6. Put both at the top of the script in `index.html`:

   ```js
   var SUPABASE_URL = "https://your-project.supabase.co";
   var SUPABASE_KEY = "sb_publishable_...";
   ```

7. Serve the folder over HTTP, for example `python -m http.server 8000`, or host it on
   GitHub Pages. Opening the file directly also works in most browsers.

The publishable key is meant to be public. It gives no access to the tables on its own: every
row is behind row level security, and only the account listed in `public.admins` passes.

## Data and access

- `students`: one row per student. The ID and the name (ignoring case and outer spaces) are
  unique.
- `attendance`: one row per student per date. Deleting a student deletes their records.
- `admins`: accounts allowed to use the register.

Row level security is on for all three tables. Visitors without a session, and signed-in
accounts that are not in `admins`, get no rows and cannot insert, update or delete. Sign-ups
are not part of the page; create the administrator yourself and keep it private.

The gear menu has **Export CSV** for a backup, **Print** for the selected day, **Reset all**,
and **Sign out**.

## Files

- `index.html`: the whole app.
- `supabase/schema.sql`: tables, constraints and row level security.
- `assets/citsa-logo.png`: logo in the header. The untouched original is
  `assets/citsa-logo-original.jpg`.

## Changing the rules

- ID format: `ID_PREFIX` and `ID_DIGITS` near the top of the script in `index.html`. The
  database has a matching check constraint in `supabase/schema.sql`
  (`students_id_format`); update both.
- Names: `NAME_RE` in `index.html`.
