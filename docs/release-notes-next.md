## Screenshots work again

2.4.0 blocked screenshots of Cuenti entirely. That was heavier than the
problem warranted: what needed hiding was the app-switcher preview, which
showed your dashboard and balances to anyone who pressed the recents
button, not the screenshots you take on purpose.

This version hides the preview and leaves screenshots alone.

The mechanism that does this narrowly arrived in Android 13, so **on
Android 12 and older the preview is no longer hidden either**. If you are
on an older device and would rather keep 2.4.0's behaviour there, say so —
it can be brought back for those versions alone.

Everything else from 2.4.0 is unchanged: backups still exclude your data,
and an `http://` server address is still warned about.
