# Cuenti Mobile

Flutter client for the [Cuenti](https://github.com/your-org/cuenti) personal-finance server.

## Setup

```bash
git clone <repo-url> && cd cuenti_mobile

# install the pinned Flutter SDK
fvm install

# fetch Dart packages
fvm flutter pub get
```

## Build APK

To generate a release APK for distribution:

```bash
# Clean previous builds
fvm flutter clean

# Fetch dependencies
fvm flutter pub get

# Build the release APK
fvm flutter build apk --release
```

The resulting APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

For smaller file sizes, you can build split APKs for different architectures:
```bash
fvm flutter build apk --split-per-abi
```

## Android 9 Compatibility & SSL

The app is configured for **Android 9 (API 28)** and above.

