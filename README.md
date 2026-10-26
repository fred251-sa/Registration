# Information Technology Attendance Register

Two pages share one Supabase database.

- `index.html`: student check-in. Public, no sign-in.
- `admin.html`: administrator panel. Sign-in required.

## Student check-in

Open the site root. Students type their full name and student ID and press
**Mark me present**. The date is always today.

Student IDs use the format `PS/ITC/25/0000`. Typing only the serial number completes it:
`12` becomes `PS/ITC/25/0012`.

The check-in is rejected when:

- the ID is already registered to a different name,
- the name is already registered with a different ID,
- the student is already marked for today.

Case and extra spaces are ignored. Students can only add a check-in. They cannot read the
register, see other students, or edit anything.

## Administrator panel

Open `admin.html` and sign in with the administrator account. It has the full register for
any date, the student roster, search, CSV export, print, reset and sign out. The gear menu
links back to the student check-in page.

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
6. Put both in `assets/config.js`:

   ```js
   window.SUPABASE_URL = "https://your-project.supabase.co";
   window.SUPABASE_KEY = "sb_publishable_...";
   ```

7. Serve the folder over HTTP, for example `python -m http.server 8000`, or host it on
   GitHub Pages. Opening the files directly also works in most browsers.

The publishable key is meant to be public. It gives no access to the tables on its own.

## Access

Row level security is on for `students`, `attendance` and `admins`.

- Visitors without a session cannot read or write the tables. Their only allowed action is
  the `check_in` function, which adds one student and today's attendance row and returns
  that row.
- Signed-in accounts that are not in `admins` get no rows and cannot write.
- The account in `admins` has full access.

Sign-ups are not part of either page. Create the administrator yourself and keep the
password private. You can also turn off new sign-ups under **Authentication, Providers,
Email**.

## Data

- `students`: one row per student. The ID and the name (ignoring case and outer spaces) are
  unique.
- `attendance`: one row per student per date. Deleting a student deletes their records.
- `admins`: accounts allowed to use the administrator panel.

## Files

- `index.html`: student check-in page.
- `admin.html`: administrator panel.
- `assets/config.js`: Supabase URL and publishable key.
- `supabase/schema.sql`: tables, constraints, row level security and the check-in function.
- `assets/citsa-logo.png`: logo. The untouched original is `assets/citsa-logo-original.jpg`.

## Changing the rules

- ID format: `ID_PREFIX` and `ID_DIGITS` in both HTML files, the `students_id_format`
  constraint in `supabase/schema.sql`, and the regex inside `check_in`.
- Names: `NAME_RE` in both HTML files.
