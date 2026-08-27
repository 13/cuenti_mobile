# Remembered Login (username prefill + biometric sign-in)

**Date:** 2026-08-27
**Status:** Approved

## Goal

After one successful sign-in, the app remembers username and password. On the
next visit to the login screen (no valid JWT):

- Username field is prefilled.
- If **Biometric Unlock** is enabled in Settings, a fingerprint/face prompt
  signs the user in with the stored credentials.
- If biometric is disabled (or fails/cancelled), the user only types the
  password.

The existing `AppLockObserver` (lock while a valid JWT is restored) is
unchanged. The new flow applies only on `LoginScreen`.

## Decisions

| Question | Decision |
|---|---|
| When are saved credentials cleared? | Explicit logout only. Session expiry keeps them. Additionally: server rejects saved password (401) → saved password dropped, username kept; "Not you?" on login screen drops both. |
| What happens after biometric success? | Auto-login: `POST /auth/login` with stored username + password. |
| Cold start with valid JWT? | Existing app-lock behaviour. Not touched. |
| Turning biometric off in Settings | Credentials stay. Login screen falls back to prefilled username + password entry. |

## Storage

`SecureStorage` (flutter_secure_storage, already used for JWT and
`biometric_enabled`) gets two new keys:

- `saved_username`
- `saved_password`

Security note: the password is stored as-is inside platform secure storage
(Android EncryptedSharedPreferences / iOS Keychain). It is not readable by other
apps; a rooted/jailbroken device could extract it. Accepted for this
self-hosted personal-finance app. Cleared on logout.

## AuthController

`AuthState` gains:

```dart
String? savedUsername,
@Default(false) bool hasSavedPassword,
```

Behaviour:

- `_init()` reads both keys. `savedUsername` = stored value (null if absent);
  `hasSavedPassword` = stored password non-empty.
- `login(username, password)` on success writes both keys and sets
  `savedUsername = username`, `hasSavedPassword = true`.
- `register(...)` on success does the same (a registered user is signed in).
- `logout()` deletes both keys, sets `savedUsername = null`,
  `hasSavedPassword = false`.
- `loginWithSavedCredentials()` → `Future<String?>` (null = success, else
  error message, same contract as `login`):
  - Reads password from storage. If `savedUsername == null` or password
    missing → returns `'No saved credentials'` and sets
    `hasSavedPassword = false`.
  - Calls `_repo.login(savedUsername, password)`. Success → sets `user`.
  - On `UnauthorizedException` → deletes `saved_password`, sets
    `hasSavedPassword = false`, returns `'Saved password no longer valid'`.
  - Other errors → returned via `_extractError` (network etc.), credentials
    kept.
- `forgetSavedCredentials()` deletes both keys and clears the two state fields.
- `setBiometricEnabled` unchanged.

## LoginScreen

- After `init()` completes (existing `didChangeDependencies` hook), if not
  already navigating to dashboard:
  - If `savedUsername != null`: set username controller text, request focus on
    password field.
  - If `biometricEnabled && hasSavedPassword`: trigger biometric prompt once
    automatically (`_biometricAttempted` guard).
- New widget below the **Sign In** button, visible only when
  `biometricEnabled && hasSavedPassword`:
  `OutlinedButton.icon(icon: Icons.fingerprint, label: 'Sign in with biometrics')`.
  Tapping re-runs the prompt (for the cancel-then-retry case).
- Biometric prompt: `LocalAuthentication.authenticate(localizedReason:
  'Sign in to Cuenti')`. `LoginScreen` gets an optional `authenticator`
  constructor parameter (test seam, same pattern as `AppLockObserver`).
  - `true` → set `_submitting`, call `loginWithSavedCredentials()`. Success →
    `context.go('/dashboard')`. Error → shown in the existing `_error` text;
    if the saved password was rejected, the biometric button disappears
    (state no longer satisfies the condition) and the password field is
    focused.
  - `false` or exception (unavailable, cancelled) → no error shown, user
    types password.
- Username prefilled state shows a small `TextButton('Not you?')` (placed as a
  row under the username field, right-aligned). Tapping calls
  `forgetSavedCredentials()`, clears both text fields, focuses username.
- Manual password sign-in path unchanged; on success the controller
  overwrites the saved credentials with the ones just used.

## Settings

No change. The existing **Biometric Unlock** switch now also governs biometric
sign-in on the login screen. Its subtitle becomes
`'Require fingerprint/face to reopen or sign in'`.

## Tests

`test/features/auth/auth_controller_test.dart` (existing `MemoryStorage`
fake):

1. `login` success writes `saved_username` / `saved_password`, state fields
   set.
2. `logout` deletes both keys and clears state fields.
3. `_init` restores `savedUsername` / `hasSavedPassword` from storage.
4. `loginWithSavedCredentials` success calls `repo.login` with stored values.
5. `loginWithSavedCredentials` on `UnauthorizedException` deletes only the
   password, keeps username, returns error.
6. `forgetSavedCredentials` deletes both.

`test/features/auth/login_screen_test.dart` (existing pattern +
`MockLocalAuthentication` from `app_lock_test.dart`):

7. Username prefilled when storage has `saved_username`; "Not you?" visible.
8. Biometric button absent when `biometric_enabled` false even with saved
   password.
9. Biometric button present and auto-prompt fires once when enabled + saved
   password; fake authenticator `true` → `repo.login('demo', 'secret')`
   called, navigates.
10. Fake authenticator `false` → no `repo.login` call, no error text.
11. "Not you?" clears fields and storage keys.

## Out of scope

- OS-level biometric-bound keystore entries.
- Multiple saved accounts.
- Changing `AppLockObserver`.
