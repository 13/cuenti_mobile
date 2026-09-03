## Search and sort, on the screens that hold lists

Konten, Empfänger, Kategorien, Tags, Währungen and Anlagen each have a
search box and a row of sort chips. Type to narrow the list; tap a chip to
sort by it, tap it again to reverse. Searching matches in any order, so
"spar giro" finds "Sparkasse Girokonto" without typing it in full, and it
looks beyond the name — an account's bank, a payee's notes, an asset's
ticker.

Geplante Buchungen and Budgets have the same, sorted by when they are next
due or by what they have spent.

Konten keeps its drag-to-reorder under a "custom order" chip, which is where
it starts. Dragging is switched off while a search or another sort is
active, because the position you drop a row into would no longer describe
the order being saved.

What you searched for is remembered while you step into an account and back,
and forgotten when you sign out.

## Screens that used to close on themselves

Several forms threw away rather than opening, always for the same reason:
the app was showing a fixed list of options and the server had sent a value
that was not on it.

- Editing a payee that had a default category
- Adding an account before the currency list had loaded, or on a server with
  no euro
- Editing a transaction, payee, account or asset whose payment method or
  type this version has not heard of

Those all open now. An option Cuenti does not recognise is shown as the
value the record actually holds, and you can pick something else.

## Amounts and dates that follow your settings

Asset prices and the fuel price per litre were written as plain numbers with
a currency code after them, ignoring the currency's own separators. They now
read like every other amount — and, importantly, **they are hidden along
with everything else when privacy mode is on.** They were not before.

Dates on assets, scheduled transactions and the audit log were always
written day-first, whatever your language. They now follow it.

## Words instead of the codes underneath them

Payment methods, account and asset types, category types and recurrences
were shown as the constants the server sends: `BANK_TRANSFER`,
`CREDIT_CARD`, `EXPENSE`, `MONTHLY`. They are now written out, and
translated.

## Fixes

- **"Change server" in Settings did nothing.** It sent you to the dashboard
  instead of the server screen. It works.
- **The sign-up form answered in English** whatever language you had chosen
  — every "required", "invalid email" and "passwords do not match".
- **A sheet could stick on a spinner.** If saving failed in a way the app had
  not anticipated, Save and Cancel both stayed disabled and the sheet could
  not be closed. Failures now say so and let you try again.
- **A category nested more than two deep was invisible**, and so could not be
  edited or deleted. Anything the app cannot draw in its usual place is now
  shown at the top level rather than skipped.
- **A delete or a reorder could fail with nothing shown at all.** Errors
  the app expected — offline, refused by the server — were always
  reported; anything else went by in silence. Now nothing does.
