# Release signing

Published APKs must be signed with a key only you hold. Until v2.2.1 they
were signed with the Android debug key, which ships with every SDK install
under a known password — meaning anyone could build an APK that Android
would accept as an in-place update to Cuenti, inheriting its data
directory along with the stored token and saved password.

The build now reads a real keystore, and the release workflow fails rather
than fall back to the debug key.

## One-time setup

Everything below runs on your machine. The key is never committed, never
printed into a chat, and never leaves your control.

### 1. Create the keystore

```sh
keytool -genkey -v \
  -keystore ~/cuenti-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -alias cuenti
```

Keep `~/cuenti-release.jks` and its passwords backed up somewhere you will
still have in ten years. **Losing this key means no existing install can
ever be updated in place again** — the only route back is uninstall and
reinstall for every user.

### 2. Point local release builds at it

```sh
cat > android/key.properties <<'PROPS'
storeFile=/absolute/path/to/cuenti-release.jks
storePassword=<store password>
keyAlias=cuenti
keyPassword=<key password>
PROPS
```

`android/key.properties` and `*.jks` are gitignored. Without this file a
local `flutter build apk --release` still works, falling back to the debug
key — fine for a device on your desk, never for a release.

### 3. Give CI the same key

```sh
base64 -w0 ~/cuenti-release.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD   # store password
gh secret set ANDROID_KEY_ALIAS           # cuenti
gh secret set ANDROID_KEY_PASSWORD        # key password
```

The workflow writes the keystore back out, builds, and then verifies with
`apksigner` that the result is not debug-signed. A missing secret fails the
job with a pointer to this file.

## The cut-over

Android refuses an update whose signing certificate differs from the
installed app's. Every install of v2.2.1 or earlier carries the debug
certificate, so the first release signed with the new key **cannot install
over them**.

Those users have to uninstall and reinstall once. App data lives on the
server, so nothing is lost but the local session — they sign in again.

Say so in the release body for that version. The in-app updater will offer
the download as usual; the install will fail with a signature mismatch and
no explanation from Android, so the release notes are the only place a user
can find out why.

This cost only grows with the number of installs. Do it at the next
release.
