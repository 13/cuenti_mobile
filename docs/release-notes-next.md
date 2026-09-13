## Signing in without a connection

If fingerprint unlock is off, the app now asks for your password when it
starts without a connection, instead of opening straight into your data.
With fingerprint unlock on, it asks for your fingerprint -- including in one
case where it used to open without asking.

After five wrong passwords without a connection, each further try has to wait
a little longer. After ten, sign in once while connected.

## Your data on the phone

The figures kept for offline use and the transactions waiting to be sent are
now encrypted on the phone. Transactions entered offline are also no longer
kept anywhere Android might clear.

## Sending what you entered offline

With an up-to-date server, a transaction that is sent twice because the
connection dropped is created only once, and an offline change to a
transaction that was changed elsewhere in the meantime is shown as refused
instead of silently overwriting the other change.

## Downloads

Release files now carry the app name and version, for example
Cuenti-v2.9.3-arm64-v8a-release.apk.

This update installs over 2.9.2 as usual; no reinstall is needed.
