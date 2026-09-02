## Screenshots are now blocked

Cuenti no longer appears in screenshots or in the app-switcher preview.
That preview was a full picture of your dashboard, balances and all, and it
sat outside everything else protecting them — the biometric lock only
guards a resume, and the privacy blur only what is on screen.

The cost is that you cannot screenshot the app at all any more. If that
gets in your way, say so and it can be narrowed to the preview alone on
Android 13 and newer.

## Your data no longer leaves the device in a backup

Cuenti keeps a local copy of your latest figures so they are still there
when the server is not. That copy was eligible for Android's cloud backup;
it is now excluded, along with everything else the app stores. Your data
lives on your server, which is the only place it was ever meant to.

## A warning before an unencrypted server

Entering a server address starting with `http://` now says plainly what
that means: your password, your session and every figure the app loads
cross the network readable by anyone on it. You can still go ahead — a
server on your own LAN is a fair reason — but it is now a choice rather
than something the example address quietly suggested.

## Statistics

- Savings rate (Sparquote) alongside income, expense and balance.
- The category chart starts at top-level categories, and tapping one drills
  into its subcategories, as deep as your categories go.
- Large amounts no longer run off the edge of the summary.
- The whole screen is translated. The period buttons, the chart labels and
  the summary headings were English whatever language you had chosen — as
  were headings on the dashboard, forecasts, settings and vehicles screens.
- Charts now describe themselves to screen readers.

## Sign-in

Errors while signing in or registering are shown in your language instead
of always in English, and a wrong password now says so rather than
reporting the session as expired.
