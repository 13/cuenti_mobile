## This update needs a reinstall

Cuenti is now signed with a different release key. Android only installs an
update signed with the same key as the app already on the phone, so updating
over 2.9.1 or earlier stops with "App not installed" and no further
explanation.

Before you uninstall, open the app once with a connection so any transactions
waiting under "not sent yet" reach the server — they exist only on the phone
until then. Then uninstall Cuenti, install this release, and sign in again.
Everything else lives on the server and is still there.

This is the last key change: later updates install over this one as usual.

## The lock screen no longer opens by itself

With biometric unlock enabled, a fingerprint or face check that could not run
at all — the sensor locked out after too many attempts, or no biometrics
enrolled any more — simply removed the lock screen. It now stays locked,
says why, and offers to try again or to sign out and sign in with your
password. Signing out this way keeps your unsent transactions.

## Updates are checked before they are installed

A downloaded update is now compared with the checksum GitHub publishes for
it. If they differ, the file is deleted and nothing is installed.
