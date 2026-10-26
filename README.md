# Information Technology Attendance Register

Two pages share one Supabase database.

- `index.html`: student check-in. Public, no sign-in.
- `admin.html`: administrator panel. Sign-in required.

## Student check-in

Open the site root. Students type their full name and student ID and press
**Submit**. The date is always today.

Student IDs use the format `PS/ITC/25/0000`. Typing only the serial number completes it:
`12` becomes `PS/ITC/25/0012`.

The check-in is rejected when:

- the ID is already registered to a different name,
- the name is already registered with a different ID,
- the student is already marked for today.

Case and extra spaces are ignored. Students can only add a check-in. They cannot read the
register, see other students, or edit anything.

## Administrator panel

Open `admin.html` and sign in with the administrator account. After the password, enter the
6-digit code from an authenticator app (Google Authenticator, Microsoft Authenticator or
Authy).

The first sign-in shows a QR code. Scan it once, then enter the code shown in the app. The
account is remembered on that device. Every new sign-in still needs a fresh code.

If the phone or authenticator is lost, open **Authentication, Users** in Supabase, select the
administrator, open **Factors**, and remove the authenticator factor. Sign in again to set up
a new one.

The panel has the full register for any date, the student roster, search, CSV export, print,
reset and sign out. The gear menu links back to the student check-in page.

## Setup

You need a Supabase project (the free plan is enough).

1. Create a project at https://supabase.com/dashboard.
2. Open **SQL Editor**, paste `supabase/schema.sql`, and run it once.
3. Open **Authentication, Users, Add user**. Create the administrator with an email and a
   long, unique password. Turn on **Auto Confirm User** so no confirmation email is needed.
4. Copy the new user's ID and run this in the SQL Editor, replacing the email:

   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'you@example.com';
   ```

5. Turn off new sign-ups under **Authentication, Providers, Email**. Only the account you
   created should exist.
6. Open **Project Settings, API**. Copy the **Project URL** and the **publishable** key
   (or the `anon` key on older projects).
7. Put both in `assets/config.js`:

   ```js
   window.SUPABASE_URL = "https://your-project.supabase.co";
   window.SUPABASE_KEY = "sb_publishable_...";
   ```

8. Serve the folder over HTTP, for example `python -m http.server 8000`, or host it on
   GitHub Pages. Opening the files directly also works in most browsers.

9. Open `admin.html`, sign in, and scan the QR code with an authenticator app. Two-step
   verification is required before the register opens.

The publishable key is meant to be public. It gives no access to the tables on its own.

## Access

Row level security is on for `students`, `attendance` and `admins`.

- Visitors without a session cannot read or write the tables. Their only allowed action is
  the `check_in` function, which adds one student and today's attendance row and returns
  that row.
- Signed-in accounts that are not in `admins` get no rows and cannot write.
- The account in `admins` gets full access only after the authenticator code is accepted.
  A session that stops at the password step cannot read or change the register.

Sign-ups are not part of either page. Turn off new sign-ups under **Authentication,
Providers, Email**, create the administrator yourself, and keep the password private. The
password is the first step; the authenticator code is the second.

The security advisor flags `check_in` because visitors can run it. That is required for the
public page. The function only adds one student and one row for today, then returns that
row. It cannot read or change anything else.

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
