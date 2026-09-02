## The app-switcher preview is hidden again on older Android

2.4.1 stopped blocking screenshots, which was the right call — but the
mechanism that hides the preview on its own only exists from Android 13, so
2.4.1 left Android 12 and older with the preview showing your dashboard
again.

This version restores protection there, by the only means those versions
offer:

- **Android 13 and newer** — the preview is hidden, screenshots work.
- **Android 12 and older** — the preview is hidden and screenshots of
  Cuenti are blocked, as they were in 2.4.0. Nothing else hides the preview
  on those versions, and the balances are worth more than the screenshots.

So Cuenti behaves differently on two phones running different Android
versions. That is deliberate, and this is the note that says so.
