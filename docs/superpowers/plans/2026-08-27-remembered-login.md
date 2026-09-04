# Remembered Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After one successful sign-in, remember username + password in secure storage; on the next login screen visit prefill the username and, when Biometric Unlock is on, sign in via fingerprint/face.

**Architecture:** Two new `SecureStorage` keys owned by `AuthController` (same pattern as `biometric_enabled`). `AuthState` exposes `savedUsername` / `hasSavedPassword`; `LoginScreen` reads them to prefill and to show/auto-trigger a biometric sign-in button that calls `AuthController.loginWithSavedCredentials()`. `AppLockObserver` is untouched.

**Tech Stack:** Flutter, Riverpod 3 (`riverpod_annotation` + generator), freezed 3, `flutter_secure_storage`, `local_auth`, `mocktail`.

Spec: `docs/superpowers/specs/2026-08-27-remembered-login-design.md`

## Global Constraints

- Run all commands from `/home/ben/repo/cuenti_mobile`.
- Flutter binary: `~/fvm/versions/stable/bin/flutter` (not on PATH). Dart: `~/fvm/versions/stable/bin/dart`.
- Codegen after editing `auth_controller.dart` state: `~/fvm/versions/stable/bin/dart run build_runner build`.
- Tests: `~/fvm/versions/stable/bin/flutter test <path>`. Analyze: `~/fvm/versions/stable/bin/flutter analyze`.
- Storage keys exactly: `saved_username`, `saved_password`.
- Error strings exactly: `'No saved credentials'`, `'Saved password no longer valid'`.
- UI copy exactly: button `'Sign in with biometrics'`, link `'Not you?'`, biometric reason `'Sign in to Cuenti'`, settings subtitle `'Require fingerprint/face to reopen or sign in'`.
- Credentials cleared only by `logout()`, `forgetSavedCredentials()`, or (password only) a 401 in `loginWithSavedCredentials()`.
- Do not modify `lib/features/auth/ui/app_lock_observer.dart`.
- Commit messages: conventional (`feat(auth): ...`), end with the Co-Authored-By trailer used in this repo.

---

### Task 1: AuthState fields + persist credentials on login/register/logout

**Files:**
- Modify: `lib/features/auth/ui/auth_controller.dart`
- Regenerate: `lib/features/auth/ui/auth_controller.freezed.dart`, `lib/features/auth/ui/auth_controller.g.dart`
- Test: `test/features/auth/auth_controller_test.dart`

**Interfaces:**
- Produces: `AuthState.savedUsername: String?`, `AuthState.hasSavedPassword: bool`; storage keys `saved_username`, `saved_password`; `AuthController.login/register/logout` side effects on those keys.

- [ ] **Step 1: Write failing tests**

Replace the `MemoryStorage` class in `test/features/auth/auth_controller_test.dart` so the map is inspectable, and add tests. The full file becomes:

```dart
import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MemoryStorage extends SecureStorage {
  MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late MockAuthRepository repo;
  late MockApiClient apiClient;
  late MemoryStorage storage;
  late ProviderContainer container;

  const user = UserProfile(
    username: 'demo',
    email: 'd@x',
    firstName: 'D',
    lastName: 'M',
  );

  setUp(() {
    repo = MockAuthRepository();
    apiClient = MockApiClient();
    storage = MemoryStorage();
    when(() => apiClient.init()).thenAnswer((_) async {});
    when(() => repo.hasToken()).thenAnswer((_) async => true);
    when(() => repo.getProfile()).thenAnswer((_) async => user);
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async => true);
    when(() => repo.logout()).thenAnswer((_) async {});

    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      apiClientProvider.overrideWithValue(apiClient),
      secureStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });

  test('concurrent init() calls are single-flight: getProfile called once',
      () async {
    final notifier = container.read(authControllerProvider.notifier);

    // Two explicit concurrent calls, plus the microtask `build()` already
    // scheduled internally, all race for the same in-flight init.
    await Future.wait([notifier.init(), notifier.init()]);

    verify(() => repo.getProfile()).called(1);
    expect(container.read(authControllerProvider).user, user);
  });

  group('saved credentials', () {
    test('login success persists username and password', () async {
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login('demo', 'secret');

      expect(error, isNull);
      expect(storage.data['saved_username'], 'demo');
      expect(storage.data['saved_password'], 'secret');
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
    });

    test('login failure does not persist credentials', () async {
      when(() => repo.login(any(), any()))
          .thenThrow(Exception('Invalid username or password'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.login('demo', 'wrong');

      expect(error, 'Invalid username or password');
      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
    });

    test('register success persists username and password', () async {
      when(() => repo.register(
            username: 'new',
            email: 'n@x',
            password: 'pw',
            firstName: 'N',
            lastName: 'U',
          )).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.register(
        username: 'new',
        email: 'n@x',
        password: 'pw',
        firstName: 'N',
        lastName: 'U',
      );

      expect(storage.data['saved_username'], 'new');
      expect(storage.data['saved_password'], 'pw');
      expect(container.read(authControllerProvider).savedUsername, 'new');
    });

    test('init restores savedUsername and hasSavedPassword from storage',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isTrue);
    });

    test('init with username but no password: hasSavedPassword false',
        () async {
      storage.data['saved_username'] = 'demo';
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.init();

      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isFalse);
    });

    test('logout deletes both keys and clears state', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.logout();

      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, isNull);
      expect(state.hasSavedPassword, isFalse);
      expect(state.user, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/auth_controller_test.dart`
Expected: compile error — `savedUsername` / `hasSavedPassword` not defined on `AuthState`.

- [ ] **Step 3: Implement state fields and persistence**

In `lib/features/auth/ui/auth_controller.dart`:

Add constants after `_biometricKey`:

```dart
const _savedUsernameKey = 'saved_username';
const _savedPasswordKey = 'saved_password';
```

Extend `AuthState`:

```dart
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    UserProfile? user,
    @Default(true) bool registrationEnabled,
    @Default(false) bool biometricEnabled,
    @Default(false) bool initialized,
    String? savedUsername,
    @Default(false) bool hasSavedPassword,
  }) = _AuthState;

  const AuthState._();

  bool get isLoggedIn => user != null;
}
```

In `_init()`, after reading `bioStr`:

```dart
    final savedUsername = await _storage.read(_savedUsernameKey);
    final savedPassword = await _storage.read(_savedPasswordKey);
```

and extend the final `state = state.copyWith(...)`:

```dart
    state = state.copyWith(
      user: user,
      biometricEnabled: biometricEnabled,
      registrationEnabled: registrationEnabled,
      initialized: true,
      savedUsername: savedUsername,
      hasSavedPassword: savedPassword != null && savedPassword.isNotEmpty,
    );
```

Add a private helper (below `refreshProfile`):

```dart
  Future<void> _saveCredentials(String username, String password) async {
    await _storage.write(_savedUsernameKey, username);
    await _storage.write(_savedPasswordKey, password);
    state = state.copyWith(savedUsername: username, hasSavedPassword: true);
  }
```

Update `login`:

```dart
  Future<String?> login(String username, String password) async {
    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(user: user);
      await _saveCredentials(username, password);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }
```

Update `register` (inside the `try`, after `state = state.copyWith(user: user);`):

```dart
      await _saveCredentials(username, password);
```

Update `logout`:

```dart
  Future<void> logout() async {
    await _repo.logout();
    await _storage.delete(_savedUsernameKey);
    await _storage.delete(_savedPasswordKey);
    state = state.copyWith(
      user: null,
      savedUsername: null,
      hasSavedPassword: false,
    );
  }
```

- [ ] **Step 4: Regenerate freezed/riverpod code**

Run: `~/fvm/versions/stable/bin/dart run build_runner build`
Expected: `Succeeded after ...` and `auth_controller.freezed.dart` now contains `savedUsername` / `hasSavedPassword`.

Note: `git status` at session start showed pre-existing uncommitted changes to `audit_controller.g.dart` and `transactions_controller.g.dart`; build_runner may touch them again. Leave them out of this feature's commits unless the diff is only the generator re-emitting the same content.

- [ ] **Step 5: Run tests to verify they pass**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/auth_controller_test.dart`
Expected: all 7 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/ui/auth_controller.dart lib/features/auth/ui/auth_controller.freezed.dart lib/features/auth/ui/auth_controller.g.dart test/features/auth/auth_controller_test.dart
git commit -m "feat(auth): persist credentials in secure storage after sign-in"
```

---

### Task 2: `loginWithSavedCredentials()` and `forgetSavedCredentials()`

**Files:**
- Modify: `lib/features/auth/ui/auth_controller.dart`
- Test: `test/features/auth/auth_controller_test.dart`

**Interfaces:**
- Consumes: Task 1 keys/state.
- Produces: `Future<String?> AuthController.loginWithSavedCredentials()` (null = success), `Future<void> AuthController.forgetSavedCredentials()`.

- [ ] **Step 1: Write failing tests**

Add to the `saved credentials` group in `test/features/auth/auth_controller_test.dart`. Add import at top:

```dart
import 'package:cuentimobile/core/api/api_exception.dart';
```

Tests:

```dart
    test('loginWithSavedCredentials calls repo with stored values', () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, isNull);
      verify(() => repo.login('demo', 'secret')).called(1);
      expect(container.read(authControllerProvider).user, user);
    });

    test('loginWithSavedCredentials without stored password returns error',
        () async {
      storage.data['saved_username'] = 'demo';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, 'No saved credentials');
      verifyNever(() => repo.login(any(), any()));
      expect(container.read(authControllerProvider).hasSavedPassword, isFalse);
    });

    test('loginWithSavedCredentials on 401 drops password, keeps username',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'old';
      when(() => repo.login('demo', 'old')).thenThrow(
          const UnauthorizedException('Invalid username or password'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, 'Saved password no longer valid');
      expect(storage.data['saved_username'], 'demo');
      expect(storage.data.containsKey('saved_password'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, 'demo');
      expect(state.hasSavedPassword, isFalse);
    });

    test('loginWithSavedCredentials on network error keeps credentials',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      when(() => repo.login('demo', 'secret'))
          .thenThrow(const NetworkException('No connection'));
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      final error = await notifier.loginWithSavedCredentials();

      expect(error, isNotNull);
      expect(storage.data['saved_password'], 'secret');
      expect(container.read(authControllerProvider).hasSavedPassword, isTrue);
    });

    test('forgetSavedCredentials deletes both keys and clears state',
        () async {
      storage.data['saved_username'] = 'demo';
      storage.data['saved_password'] = 'secret';
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.init();

      await notifier.forgetSavedCredentials();

      expect(storage.data.containsKey('saved_username'), isFalse);
      expect(storage.data.containsKey('saved_password'), isFalse);
      final state = container.read(authControllerProvider);
      expect(state.savedUsername, isNull);
      expect(state.hasSavedPassword, isFalse);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/auth_controller_test.dart`
Expected: compile error — `loginWithSavedCredentials` / `forgetSavedCredentials` undefined.

- [ ] **Step 3: Implement**

In `lib/features/auth/ui/auth_controller.dart` add import:

```dart
import '../../../core/api/api_exception.dart';
```

Add methods after `logout()`:

```dart
  /// Signs in with the credentials persisted by the last successful
  /// [login]/[register]. Returns null on success, else an error message.
  /// A 401 means the password changed server-side: the saved password is
  /// dropped (username kept) so the UI falls back to manual entry.
  Future<String?> loginWithSavedCredentials() async {
    final username = state.savedUsername;
    final password = await _storage.read(_savedPasswordKey);
    if (username == null || password == null || password.isEmpty) {
      state = state.copyWith(hasSavedPassword: false);
      return 'No saved credentials';
    }
    try {
      final user = await _repo.login(username, password);
      state = state.copyWith(user: user);
      return null;
    } on UnauthorizedException {
      await _storage.delete(_savedPasswordKey);
      state = state.copyWith(hasSavedPassword: false);
      return 'Saved password no longer valid';
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<void> forgetSavedCredentials() async {
    await _storage.delete(_savedUsernameKey);
    await _storage.delete(_savedPasswordKey);
    state = state.copyWith(savedUsername: null, hasSavedPassword: false);
  }
```

Refactor `logout()` to reuse it:

```dart
  Future<void> logout() async {
    await _repo.logout();
    await forgetSavedCredentials();
    state = state.copyWith(user: null);
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/auth_controller_test.dart`
Expected: all 12 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/ui/auth_controller.dart test/features/auth/auth_controller_test.dart
git commit -m "feat(auth): sign in with saved credentials, forget credentials"
```

---

### Task 3: LoginScreen — username prefill + "Not you?"

**Files:**
- Modify: `lib/features/auth/ui/login_screen.dart`
- Test: `test/features/auth/login_screen_test.dart`

**Interfaces:**
- Consumes: `AuthState.savedUsername`, `AuthController.forgetSavedCredentials()`.
- Produces: `LoginScreen` prefill behaviour; `_MemoryStorage` in the test gains a public `data` map used by Task 4.

- [ ] **Step 1: Write failing tests**

In `test/features/auth/login_screen_test.dart`, rename the private map in `_MemoryStorage` to public `data`:

```dart
class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}
```

Change `pumpLogin` to accept a storage instance:

```dart
  Future<_MemoryStorage> pumpLogin(
    WidgetTester tester, {
    _MemoryStorage? storage,
  }) async {
    final s = storage ?? _MemoryStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          secureStorageProvider.overrideWithValue(s),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return s;
  }
```

Add tests:

```dart
  testWidgets('prefills username from storage and shows Not you?',
      (tester) async {
    final storage = _MemoryStorage()..data['saved_username'] = 'demo';

    await pumpLogin(tester, storage: storage);

    final usernameField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(usernameField.controller!.text, 'demo');
    expect(find.text('Not you?'), findsOneWidget);
  });

  testWidgets('no Not you? link without saved username', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Not you?'), findsNothing);
  });

  testWidgets('Not you? clears fields and storage', (tester) async {
    final storage = _MemoryStorage()
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';

    await pumpLogin(tester, storage: storage);
    await tester.tap(find.text('Not you?'));
    await tester.pumpAndSettle();

    final usernameField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(usernameField.controller!.text, isEmpty);
    expect(storage.data.containsKey('saved_username'), isFalse);
    expect(storage.data.containsKey('saved_password'), isFalse);
    expect(find.text('Not you?'), findsNothing);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/login_screen_test.dart`
Expected: the three new tests FAIL (`'demo'` not prefilled / `Not you?` not found); the original test still passes.

- [ ] **Step 3: Implement prefill and "Not you?"**

In `lib/features/auth/ui/login_screen.dart`:

Add a focus node field next to the controllers:

```dart
  final _passwordFocus = FocusNode();
```

Dispose it in `dispose()`:

```dart
    _passwordFocus.dispose();
```

Replace the `didChangeDependencies` body:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      ref.read(authControllerProvider.notifier).init().then((_) {
        if (!mounted) return;
        final auth = ref.read(authControllerProvider);
        if (auth.isLoggedIn) {
          context.go('/dashboard');
          return;
        }
        _applySavedCredentials(auth);
      });
    }
  }

  void _applySavedCredentials(AuthState auth) {
    final saved = auth.savedUsername;
    if (saved == null || saved.isEmpty) return;
    _usernameController.text = saved;
    _passwordFocus.requestFocus();
  }

  Future<void> _forgetSavedCredentials() async {
    await ref.read(authControllerProvider.notifier).forgetSavedCredentials();
    if (!mounted) return;
    setState(() {
      _usernameController.clear();
      _passwordController.clear();
      _error = null;
    });
  }
```

Attach the focus node to the password field: add `focusNode: _passwordFocus,` to the password `TextFormField`.

Under the username field (between the username `TextFormField` and the `SizedBox(height: 16)`), insert:

```dart
                  if (auth.savedUsername != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting ? null : _forgetSavedCredentials,
                        child: const Text('Not you?'),
                      ),
                    ),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/login_screen_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/ui/login_screen.dart test/features/auth/login_screen_test.dart
git commit -m "feat(auth): prefill remembered username on login screen"
```

---

### Task 4: LoginScreen — biometric sign-in button + auto prompt

**Files:**
- Modify: `lib/features/auth/ui/login_screen.dart`
- Test: `test/features/auth/login_screen_test.dart`

**Interfaces:**
- Consumes: `AuthState.biometricEnabled`, `AuthState.hasSavedPassword`, `AuthController.loginWithSavedCredentials()`.
- Produces: `LoginScreen({Key? key, LocalAuthentication? authenticator})`.

- [ ] **Step 1: Write failing tests**

In `test/features/auth/login_screen_test.dart` add imports and mock:

```dart
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:local_auth/local_auth.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}
```

Extend `pumpLogin` to take an authenticator and a navigation target so `context.go('/dashboard')` can be observed. Replace `pumpLogin` with:

```dart
  Future<_MemoryStorage> pumpLogin(
    WidgetTester tester, {
    _MemoryStorage? storage,
    LocalAuthentication? authenticator,
  }) async {
    final s = storage ?? _MemoryStorage();
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(authenticator: authenticator),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          secureStorageProvider.overrideWithValue(s),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return s;
  }
```

Add import `import 'package:go_router/go_router.dart';`. The existing tests keep working because they only look inside `LoginScreen`.

Add in `main()` before `setUp`:

```dart
  setUpAll(() {
    registerFallbackValue('');
  });

  const user = UserProfile(username: 'demo', email: 'd@x');

  MockLocalAuthentication authenticatorReturning(bool result) {
    final a = MockLocalAuthentication();
    when(() => a.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).thenAnswer((_) async => result);
    return a;
  }
```

Add tests:

```dart
  testWidgets('no biometric button when biometric disabled', (tester) async {
    final storage = _MemoryStorage()
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';

    await pumpLogin(tester, storage: storage);

    expect(find.text('Sign in with biometrics'), findsNothing);
  });

  testWidgets('no biometric button when enabled but no saved password',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo';

    await pumpLogin(tester, storage: storage);

    expect(find.text('Sign in with biometrics'), findsNothing);
  });

  testWidgets('auto-prompts biometric once and signs in on success',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = authenticatorReturning(true);
    when(() => repo.login('demo', 'secret')).thenAnswer((_) async => user);

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verify(() => authenticator.authenticate(
          localizedReason: 'Sign in to Cuenti',
        )).called(1);
    verify(() => repo.login('demo', 'secret')).called(1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('biometric cancel: button stays, no login, no error',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = authenticatorReturning(false);

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verifyNever(() => repo.login(any(), any()));
    expect(find.text('Sign in with biometrics'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    // Tapping the button retries the prompt.
    await tester.tap(find.text('Sign in with biometrics'));
    await tester.pumpAndSettle();
    verify(() => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).called(2);
  });

  testWidgets('biometric exception falls back silently', (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'secret';
    final authenticator = MockLocalAuthentication();
    when(() => authenticator.authenticate(
          localizedReason: any(named: 'localizedReason'),
        )).thenThrow(Exception('NotAvailable'));

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    verifyNever(() => repo.login(any(), any()));
    expect(find.text('NotAvailable'), findsNothing);
  });

  testWidgets('rejected saved password shows error and hides button',
      (tester) async {
    final storage = _MemoryStorage()
      ..data['biometric_enabled'] = 'true'
      ..data['saved_username'] = 'demo'
      ..data['saved_password'] = 'old';
    final authenticator = authenticatorReturning(true);
    when(() => repo.login('demo', 'old')).thenThrow(
        const UnauthorizedException('Invalid username or password'));

    await pumpLogin(tester, storage: storage, authenticator: authenticator);

    expect(find.text('Saved password no longer valid'), findsOneWidget);
    expect(find.text('Sign in with biometrics'), findsNothing);
    expect(storage.data.containsKey('saved_password'), isFalse);
    final usernameField =
        tester.widget<TextFormField>(find.byType(TextFormField).at(0));
    expect(usernameField.controller!.text, 'demo');
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/login_screen_test.dart`
Expected: compile error — `LoginScreen` has no `authenticator` parameter.

- [ ] **Step 3: Implement biometric sign-in**

In `lib/features/auth/ui/login_screen.dart`:

Add import:

```dart
import 'package:local_auth/local_auth.dart';
```

Change the widget constructor:

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.authenticator});

  /// Injectable seam for tests (the default constructs a real
  /// [LocalAuthentication], which talks to a platform channel unavailable in
  /// widget tests). Same pattern as `AppLockObserver`.
  final LocalAuthentication? authenticator;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
```

Add state fields:

```dart
  late final LocalAuthentication _localAuth =
      widget.authenticator ?? LocalAuthentication();
  bool _biometricAttempted = false;
```

Extend `_applySavedCredentials`:

```dart
  void _applySavedCredentials(AuthState auth) {
    final saved = auth.savedUsername;
    if (saved == null || saved.isEmpty) return;
    _usernameController.text = saved;
    _passwordFocus.requestFocus();
    if (auth.biometricEnabled && auth.hasSavedPassword && !_biometricAttempted) {
      _biometricAttempted = true;
      _biometricLogin();
    }
  }
```

Add the biometric login method (below `_login`):

```dart
  Future<void> _biometricLogin() async {
    bool didAuth;
    try {
      didAuth = await _localAuth.authenticate(
        localizedReason: 'Sign in to Cuenti',
      );
    } catch (_) {
      // Biometrics unavailable/cancelled: fall back to password entry.
      return;
    }
    if (!didAuth || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await ref
        .read(authControllerProvider.notifier)
        .loginWithSavedCredentials();
    if (!mounted) return;
    if (error == null) {
      context.go('/dashboard');
    } else {
      setState(() {
        _submitting = false;
        _error = error;
      });
      _passwordFocus.requestFocus();
    }
  }
```

Add the button after the Sign In `SizedBox(...)` and before `const SizedBox(height: 16)`:

```dart
                  if (auth.biometricEnabled && auth.hasSavedPassword) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _biometricLogin,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Sign in with biometrics'),
                      ),
                    ),
                  ],
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/fvm/versions/stable/bin/flutter test test/features/auth/`
Expected: all auth tests PASS (login_screen: 10, controller: 12, app_lock + repository unchanged).

If `find.text('Dashboard')` fails because `context.go` runs after the last `pumpAndSettle`, add `await tester.pumpAndSettle();` after `pumpLogin(...)` in that test.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/ui/login_screen.dart test/features/auth/login_screen_test.dart
git commit -m "feat(auth): biometric sign-in with saved credentials on login screen"
```

---

### Task 5: Settings copy + full verification

**Files:**
- Modify: `lib/features/user/ui/settings_screen.dart:127-129`

- [ ] **Step 1: Update subtitle**

In `lib/features/user/ui/settings_screen.dart`, change the Biometric Unlock `SwitchListTile` subtitle:

```dart
                  subtitle: const Text(
                    'Require fingerprint/face to reopen or sign in',
                  ),
```

- [ ] **Step 2: Analyze + full test run**

Run: `~/fvm/versions/stable/bin/flutter analyze`
Expected: `No issues found!`

Run: `~/fvm/versions/stable/bin/flutter test`
Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/user/ui/settings_screen.dart
git commit -m "feat(auth): settings copy mentions biometric sign-in"
```

- [ ] **Step 4: Manual check on device (not automatable)**

1. Fresh install, sign in with password → expect dashboard.
2. Settings → enable Biometric Unlock.
3. Invalidate the session without logging out (logout would clear the saved credentials): change the password on the server via the web UI so the JWT is rejected, or delete the `jwt_token` secure-storage key in a debug build. Restart the app. Expect login screen with username prefilled and biometric prompt.
4. Cancel prompt → type password → dashboard.
5. Settings → disable Biometric Unlock → repeat step 3 → prefilled username, no biometric button.
6. Logout → login screen empty, no "Not you?".
