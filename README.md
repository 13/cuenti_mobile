# Cuenti Mobile

Flutter client for the [Cuenti](https://github.com/your-org/cuenti) personal-finance server.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Android](https://img.shields.io/badge/Android-9%2B-green?logo=android)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- **Dashboard** — Net worth, available cash, portfolio value, and accounts overview
- **Transactions** — Full CRUD with monthly separators, account filtering, and search
- **Scheduled Transactions** — Recurring payments with post/skip actions
- **Statistics** — Income vs Expense, cash flow trends, category breakdowns with interactive charts
- **Accounts, Payees, Categories, Tags, Currencies, Assets** — Complete management
- **Material Design 3** — Adaptive light/dark theme with customisable colour scheme
- **Biometric Lock** — Optional fingerprint/face unlock when returning from background
- **Locale-aware formatting** — Decimal `,` and thousands `.` (German convention)

---

## Prerequisites

| Tool | Minimum version | Notes |
|------|----------------|-------|
| **Flutter SDK** | 3.22+ (Dart ≥ 3.11) | `flutter --version` to check |
| **Android SDK** | API 28 (Android 9) | via Android Studio SDK Manager |
| **Java JDK** | 17 | required by Gradle / AGP |
| **Android Studio** | 2024.x+ | recommended IDE |

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/your-org/cuenti_mobile.git
cd cuenti_mobile
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure your Cuenti server URL

The default server URL is `https://cuenti.muh`. You can change it on the
**Server Setup** screen inside the app, or edit the default in
`lib/api/api_client.dart`.

---

## Running with Android Studio

1. **Open the project** — *File → Open …* → select the `cuenti_mobile` folder.
2. **Install SDK components** — When prompted, let Android Studio download any missing SDK platforms or build tools.
3. **Create / select an emulator**
   - *Tools → Device Manager → Create Virtual Device*
   - Pick a device profile (e.g. Pixel 7) and a system image (API 33+ recommended, x86\_64).
   - Start the emulator.
4. **Select the device** in the toolbar device dropdown.
5. **Run the app** — click the green **▶ Run** button or press `Shift+F10`.

> **Tip:** Enable *KVM* on Linux for hardware-accelerated emulation:
> ```bash
> sudo apt install qemu-kvm && sudo usermod -aG kvm $USER
> ```

---

## Building the APK

### Debug build

```bash
flutter run
```

### Release build

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The APK is written to:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs (smaller per-architecture)

```bash
flutter build apk --split-per-abi
```

---

## Versioning

The app version is defined in **`pubspec.yaml`**:

```yaml
version: 1.0.3+3
#         ^^^^^  ^
#         name   build number
```

- **`build-name`** (1.0.3) → shown to users as the version string.
- **`build-number`** (3) → Android `versionCode`; increment on every release.

Update both values before publishing a new release.

---

## CI / CD — GitHub Actions

The workflow at `.github/workflows/build-apk.yml` does the following:

| Trigger | What happens |
|---------|-------------|
| Push / PR to `main` | Analyse, build APK, upload as workflow artefact |
| Push a **tag** matching `v*` | All of the above **+ create a GitHub Release** with the APK attached |

### Creating a release

```bash
# bump version in pubspec.yaml, then:
git add pubspec.yaml
git commit -m "release: v1.0.4"
git tag v1.0.4
git push origin main --tags
```

The workflow will automatically build the APK and publish a GitHub Release
with the universal APK and per-architecture split APKs attached.

---

## Project Structure

```
lib/
├── main.dart                 # App entry point, biometric lock, theming
├── router.dart               # GoRouter navigation config
├── api/
│   ├── api_client.dart       # Dio HTTP client with JWT auth
│   └── api_services.dart     # API endpoint classes
├── models/
│   └── models.dart           # Data models (Account, Transaction, …)
├── providers/
│   ├── auth_provider.dart    # Auth state, login/register, preferences
│   └── data_provider.dart    # CRUD state for all entities
├── screens/                  # One folder per feature
│   ├── auth/                 # Login, Register, Server Setup
│   ├── dashboard/
│   ├── transactions/
│   ├── statistics/
│   ├── settings/
│   └── …
├── utils/
│   └── number_format.dart    # Locale-aware number formatting
└── widgets/
    └── transaction_dialog.dart
```

## Android 9 Compatibility & SSL

The app targets **Android 9 (API 28)** and above.
Self-signed certificates are accepted by default (see `api_client.dart`).
For production, install your server's CA certificate on the device.
