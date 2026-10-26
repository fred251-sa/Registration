# Information Technology Attendance Register

Attendance register for Information Technology students. One file, no install, no server.
Open `index.html` in a browser.

## Using it

1. Type the student's full name.
2. Type the student ID.
3. Pick the date (it defaults to today).
4. Press **Mark present**.

Student IDs use the format `PS/ITC/25/0000`. Typing only the serial number completes it:
`12` becomes `PS/ITC/25/0012`.

## Duplicate checks

An entry is rejected when:

- the ID is already registered to a different name,
- the name is already registered with a different ID,
- the student is already marked for the selected date.

Case and extra spaces are ignored, so `amina  yusuf` and `Amina Yusuf` count as the same
person. A student can be marked on other dates; that is normal daily use.

## Data

Records live in this browser's local storage. Clearing site data deletes them. The gear
menu has **Export CSV** for a backup, **Print** for the selected day, and **Reset all**.

## Files

- `index.html`: the whole app.
- `assets/citsa-logo.png`: logo in the header. The untouched original is
  `assets/citsa-logo-original.jpg`.

## Changing the rules

- ID format: `ID_PREFIX` and `ID_DIGITS` near the top of the script in `index.html`.
- Names: `NAME_RE` beside them.

## Sharing

Each browser keeps its own records. You can serve the folder, for example
`python -m http.server 8000`, and open it from other devices on the same network, but
they will not share data without a real database.
