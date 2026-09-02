## Signing in to a self-hosted server

A fresh install now asks you to approve your server's certificate on the
sign-in screen, showing you its fingerprint to check against your server.
Until this version it refused the connection and told you to re-run Server
Setup — a screen a first install never passes through, so there was no way
to approve the certificate from where you were.

## Coming from 2.2.1 or older

Releases from 2.3.0 on are signed with Cuenti's own release key rather than
the Android debug key that ships with every Android SDK. Android will not
install an update whose signing key differs, so **a version older than
2.3.0 cannot update in place** — uninstall Cuenti and install this APK
fresh. Nothing is lost: your data lives on the server and you just sign in
again. Updating from 2.3.0 works normally.
