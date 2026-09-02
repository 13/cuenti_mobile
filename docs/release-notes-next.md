## Figures from one server can no longer appear under another

Cuenti keeps a local copy of your latest figures so they are still there
when the server cannot be reached. That copy was not tied to the server it
came from, so pointing the app at a different Cuenti instance and then
going offline showed the *previous* instance's balances as though they were
this one's — marked only as offline, with nothing to say they belonged
somewhere else.

Changing the server address now clears those figures, exactly as signing
out already did.

## An expired session takes you back to sign-in

When the server stopped accepting your login — because it expired, or was
revoked — the app carried on as if you were still signed in. Every screen
showed "Not authenticated" and none of them recovered; the only way out was
finding Logout in the menu.

Now it returns you to the sign-in screen, with your username still filled
in.

## Errors are in your language

Failures on the accounts, assets, categories, currencies, payees and
settings screens were reported in English whatever language you had
chosen. They are translated now.

## Exports are tidied up

The export file is written to the app's own private storage, and an earlier
export is removed when you make a new one, rather than a full copy of your
financial history being left behind each time.
