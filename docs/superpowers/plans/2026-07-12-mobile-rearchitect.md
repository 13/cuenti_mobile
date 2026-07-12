# Mobile Rearchitect Implementation Plan (Phase 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Provider + raw maps + monolithic DataProvider with Riverpod + freezed + feature-first structure, keeping the app's look and behavior identical (except transactions gain server-side pagination).

**Architecture:** Incremental coexist migration — Riverpod foundation added alongside Provider; features migrate one by one (auth → accounts → transactions → remaining domains); Provider and the old files are deleted in the final task. After every task: `flutter analyze` clean and `flutter test` green.

**Tech Stack:** flutter_riverpod + riverpod_annotation/riverpod_generator, freezed + json_serializable, dio (kept), go_router (kept; typed routes NOT introduced — see constraints), flutter_secure_storage, local_auth, mocktail, very_good_analysis.

**Spec:** `docs/superpowers/specs/2026-07-12-mobile-rearchitect-design.md`

## Global Constraints

- App compiles, `flutter analyze` is clean, and `flutter test` is green at the END of every task. During a task the tree may be temporarily broken.
- No visual changes: screens keep their current widget trees; only state-access code changes. (Phase 3 does visuals.)
- No raw `Map<String, dynamic>` above the repository layer. Repositories accept/return freezed models and throw `ApiException` only.
- The self-signed-cert bypass and JWT header interceptor in the dio client stay exactly as they are today.
- One behavior change allowed: transactions list uses server pagination (`page`/`size` envelope) with infinite scroll.
- Models include Phase 1 backend additions: `Transaction.splits` (list, default empty), `UserProfile.defaultVehicleCategoryId` (nullable int).
- Old Provider code keeps working until Task 10 removes it. Never leave a screen half-migrated at a task boundary.
- Lints: `very_good_analysis` via `analysis_options.yaml`; targeted `// ignore:` allowed only on generated-code friction, each with a reason.
- **Deviation from spec, decided at planning:** error surfacing uses call-site `try { … } on ApiException catch (e)` + snackbar (context is at hand) instead of the spec's `ref.listen` global listener — same user-visible behavior, less indirection. The spec's `ref.listen` sentence is superseded.
- **Deviation from spec, decided at planning:** go_router stays on string routes (current `router.dart` pattern). `go_router_builder` typed routes add codegen churn to every screen for zero user-visible gain in this phase; revisit in Phase 3 when screens are rewritten anyway. The spec's "typed routes" line is superseded by this paragraph.
- Commands: run from `/home/ben/repo/cuenti_mobile`. Codegen: `dart run build_runner build --delete-conflicting-outputs`. Tests: `flutter test`. Analyze: `flutter analyze`.
- Commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

## File Structure (target)

```
lib/
  main.dart                              (modified: ProviderScope, AppLockObserver)
  router.dart                            (modified: reads auth via Riverpod)
  core/
    api/api_client.dart                  (moved+adapted from lib/api/api_client.dart)
    api/api_exception.dart
    api/dio_provider.dart
    storage/secure_storage.dart
    theme/app_theme.dart                 (moved verbatim from main.dart _buildTheme)
    widgets/async_value_widget.dart
  features/
    auth/{data/auth_repository.dart, ui/auth_controller.dart, ui/{login,register,server_setup}_screen.dart, ui/app_lock_observer.dart}
    accounts/{domain/account.dart, data/accounts_repository.dart, ui/accounts_controller.dart, ui/accounts_screen.dart}
    transactions/{domain/{transaction.dart, transaction_split.dart, transaction_page.dart}, data/transactions_repository.dart, ui/{transactions_controller.dart, transactions_screen.dart, transaction_dialog.dart}}
    categories/…  payees/…  tags/…  currencies/…  assets/…  scheduled/…   (same shape)
    dashboard/{domain/{dashboard_data.dart, asset_performance.dart}, data/dashboard_repository.dart, ui/{dashboard_controller.dart, dashboard_screen.dart}}
    statistics/{domain/statistics_data.dart, data/statistics_repository.dart, ui/{statistics_controller.dart, statistics_screen.dart}}
    user/{domain/user_profile.dart, data/user_repository.dart, ui/{user_controller.dart, settings_screen.dart, about_screen.dart}}
  screens/shell_screen.dart              (modified in Task 9)
  utils/number_format.dart               (kept)
test/
  core/api_exception_test.dart
  features/<domain>/<domain>_repository_test.dart
  features/<domain>/<domain>_controller_test.dart   (where behavior warrants)
  features/auth/login_screen_test.dart
  features/transactions/{transactions_screen_test.dart, transaction_dialog_test.dart}
  helpers/fake_dio.dart
```

---

### Task 1: Foundation — dependencies, lints, core API layer

**Files:**
- Modify: `pubspec.yaml`, `analysis_options.yaml`
- Create: `lib/core/api/api_exception.dart`, `lib/core/api/api_client.dart`, `lib/core/api/dio_provider.dart`, `lib/core/storage/secure_storage.dart`, `lib/core/theme/app_theme.dart`, `lib/core/widgets/async_value_widget.dart`
- Modify: `lib/main.dart` (wrap tree in `ProviderScope`, use `AppTheme.build`)
- Test: `test/core/api_exception_test.dart`, `test/helpers/fake_dio.dart`

**Interfaces (later tasks rely on these exact signatures):**
- `sealed class ApiException implements Exception { String get message; }` with subclasses `NetworkException`, `UnauthorizedException`, `ValidationException`, `ServerException`, `UnknownApiException`; factory `ApiException.fromDio(DioException e)`.
- `class ApiClient` — same public API as today (`init()`, `baseUrl`, `setServerUrl`, `saveToken`, `getToken`, `clearToken`, `hasToken`, `dio`), constructed with a `SecureStorage`.
- Providers in `dio_provider.dart`: `final secureStorageProvider = Provider<SecureStorage>(...)`, `final apiClientProvider = Provider<ApiClient>(...)`, `final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio)`.
- `class SecureStorage` — thin wrapper: `Future<String?> read(String key)`, `Future<void> write(String key, String value)`, `Future<void> delete(String key)`; single `FlutterSecureStorage` instance with `AndroidOptions(resetOnError: true)`.
- `class AppTheme { static ThemeData build(Color seed, Brightness brightness); }` — body is today's `_buildTheme` from `lib/main.dart:103-132` moved verbatim (parameter `seed` replaces `auth.colorSchemeSeed`).
- `class AsyncValueWidget<T> extends StatelessWidget` — `({required AsyncValue<T> value, required Widget Function(T) data, Widget? loading, Widget Function(Object error)? error})`; default loading = centered `CircularProgressIndicator`, default error = centered `Text(error.toString())` with a retry-less simple message.

- [ ] **Step 1: Add dependencies**

```bash
flutter pub add flutter_riverpod riverpod_annotation freezed_annotation json_annotation
flutter pub add dev:riverpod_generator dev:build_runner dev:freezed dev:json_serializable dev:mocktail dev:very_good_analysis dev:custom_lint dev:riverpod_lint
```

Expected: pubspec updated, `flutter pub get` resolves. (`provider` stays for now.)

- [ ] **Step 2: Lints**

Replace `analysis_options.yaml` content with:

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    public_member_api_docs: false
    lines_longer_than_80_chars: false
```

Run `flutter analyze`. Expected: a wall of new lint findings in OLD files is acceptable ONLY if they are info-level; to keep the gate meaningful, add to the analyzer block:

```yaml
  errors:
    # Old Provider-era files are deleted in Task 10; don't fail the build on them.
    # New code must not add ignores.
```

If old files produce warnings/errors that block `flutter analyze`'s exit code, list those specific rules under `linter.rules: false` overrides (each with a `# old-code, remove in Task 10` comment) rather than excluding files. Record the list in the task report.

- [ ] **Step 3: Write the failing ApiException test**

`test/core/api_exception_test.dart`:

```dart
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException dioError({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  dynamic body,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('connection error maps to NetworkException', () {
    final e = ApiException.fromDio(
        dioError(type: DioExceptionType.connectionError));
    expect(e, isA<NetworkException>());
    expect(e.message, 'Cannot connect to server');
  });

  test('timeout maps to NetworkException', () {
    final e = ApiException.fromDio(
        dioError(type: DioExceptionType.receiveTimeout));
    expect(e, isA<NetworkException>());
  });

  test('401 maps to UnauthorizedException', () {
    final e = ApiException.fromDio(dioError(status: 401));
    expect(e, isA<UnauthorizedException>());
  });

  test('400 with error body surfaces server message', () {
    final e = ApiException.fromDio(
        dioError(status: 400, body: {'error': 'Split amounts must sum'}));
    expect(e, isA<ValidationException>());
    expect(e.message, 'Split amounts must sum');
  });

  test('400 with string body surfaces it', () {
    final e = ApiException.fromDio(dioError(status: 400, body: 'Bad input'));
    expect(e.message, 'Bad input');
  });

  test('500 maps to ServerException', () {
    final e = ApiException.fromDio(dioError(status: 500));
    expect(e, isA<ServerException>());
  });

  test('no response maps to UnknownApiException', () {
    final e = ApiException.fromDio(dioError(type: DioExceptionType.unknown));
    expect(e, isA<UnknownApiException>());
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/core/api_exception_test.dart`
Expected: FAIL — `api_exception.dart` doesn't exist.

- [ ] **Step 5: Implement core files**

`lib/core/api/api_exception.dart`:

```dart
import 'package:dio/dio.dart';

/// Typed API error. Repositories throw only this; DioException never
/// escapes the data layer.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Cannot connect to server');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final body = e.response?.data;
        final serverMessage = switch (body) {
          {'error': final String msg} => msg,
          final String s when s.isNotEmpty => s,
          _ => null,
        };
        if (status == 401) {
          return UnauthorizedException(serverMessage ?? 'Not authenticated');
        }
        if (status == 403) {
          return UnauthorizedException(
              serverMessage ?? 'API access is not enabled');
        }
        if (status >= 400 && status < 500) {
          return ValidationException(serverMessage ?? 'Invalid request');
        }
        return ServerException(serverMessage ?? 'Server error ($status)');
      case DioExceptionType.badCertificate:
        return const NetworkException(
            'SSL certificate error. Install the server certificate on your device.');
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return UnknownApiException(e.message ?? 'An error occurred');
    }
  }

  @override
  String toString() => message;
}

final class NetworkException extends ApiException {
  const NetworkException(super.message);
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message);
}

final class ValidationException extends ApiException {
  const ValidationException(super.message);
}

final class ServerException extends ApiException {
  const ServerException(super.message);
}

final class UnknownApiException extends ApiException {
  const UnknownApiException(super.message);
}
```

`lib/core/storage/secure_storage.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single wrapper around FlutterSecureStorage so tests can fake it and the
/// AndroidOptions live in exactly one place.
class SecureStorage {
  const SecureStorage([this._storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  )]);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
}
```

`lib/core/api/api_client.dart` — copy `lib/api/api_client.dart` verbatim with two changes: (1) constructor takes `SecureStorage` (`ApiClient(this._storage)`) and every `_storage.read(key: k)` call becomes `_storage.read(k)` etc.; (2) keep everything else identical — timeouts, cert bypass, JWT interceptor, `defaultServerUrl`, key names (`jwt_token`, `server_url`).

`lib/core/api/dio_provider.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);
```

`lib/core/theme/app_theme.dart` — move `_buildTheme` from `lib/main.dart` verbatim:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build(Color seed, Brightness brightness) {
    return ThemeData(
      colorSchemeSeed: seed,
      useMaterial3: true,
      brightness: brightness,
      // ... exact body of current _buildTheme (main.dart:104-131), with
      // auth.colorSchemeSeed replaced by the seed parameter.
    );
  }
}
```

(Copy the full body from the current file — inputDecorationTheme, cardTheme, dialogTheme, bottomSheetTheme, floatingActionButtonTheme, navigationBarTheme — unchanged.)

`lib/core/widgets/async_value_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standard loading/error/data switcher for AsyncValue-backed screens.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          error?.call(e) ?? Center(child: Text(e.toString())),
    );
  }
}
```

`test/helpers/fake_dio.dart` (used by every repository test):

```dart
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

/// Builds a dio Response for stubbing.
Response<T> ok<T>(T data, {int status = 200}) => Response<T>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: status,
      data: data,
    );
```

`lib/main.dart` changes (only these):
- Wrap the existing widget tree: `runApp(const ProviderScope(child: CuentiApp()));`
- Replace the private `_buildTheme(auth, brightness)` calls with `AppTheme.build(auth.colorSchemeSeed, brightness)` and delete the private function; add imports.
- Everything else (Provider wiring, lock screen, lifecycle) unchanged in this task.

- [ ] **Step 6: Run tests + analyze**

Run: `flutter test` — Expected: PASS (7 new tests; no old tests exist).
Run: `flutter analyze` — Expected: clean (subject to the Step 2 old-code rule adjustments).
Run: `flutter build apk --debug 2>&1 | tail -3` — Expected: build succeeds (app still boots on Provider).

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml lib/core lib/main.dart test/
git commit -m "feat(core): riverpod foundation - ApiException, core api layer, lints"
```

---

### Task 2: Freezed models for every domain

**Files:**
- Create: `lib/features/accounts/domain/account.dart`, `lib/features/transactions/domain/transaction.dart`, `lib/features/transactions/domain/transaction_split.dart`, `lib/features/transactions/domain/transaction_page.dart`, `lib/features/categories/domain/category.dart`, `lib/features/payees/domain/payee.dart`, `lib/features/tags/domain/tag.dart`, `lib/features/assets/domain/asset.dart`, `lib/features/currencies/domain/currency.dart`, `lib/features/scheduled/domain/scheduled_transaction.dart`, `lib/features/dashboard/domain/dashboard_data.dart`, `lib/features/dashboard/domain/asset_performance.dart`, `lib/features/statistics/domain/statistics_data.dart`, `lib/features/user/domain/user_profile.dart`
- Test: `test/features/models_test.dart`

**Interfaces:** Every model is `@freezed` with `fromJson`. Field names/defaults MUST match the current hand-written models in `lib/models/models.dart` exactly (they mirror the backend DTOs), with these additions:
- `Transaction`: `@Default([]) List<TransactionSplit> splits`
- `TransactionSplit`: `int? id, int? categoryId, String? categoryName, required double amount, String? memo`
- `TransactionPage`: `required List<Transaction> content, required int page, required int size, required int totalElements, required int totalPages`
- `UserProfile`: `int? defaultVehicleCategoryId`
- Static const lists move with their models (`Account.accountTypes`, `Transaction.types`, `Transaction.paymentMethods`, `Asset.assetTypes`, `ScheduledTransaction.patterns`) — as `abstract final class AccountTypes { static const values = [...]; }` companions OR kept as statics on a mixin; simplest: declare them as top-level consts in the same file (`const accountTypes = [...]`) and update call sites when screens migrate. Choose top-level consts; name them `kAccountTypes`, `kTransactionTypes`, `kPaymentMethods`, `kAssetTypes`, `kRecurrencePatterns`.
- Computed getters move too: `Account.displayType`, `UserProfile.isAdmin` — freezed supports getters in the class body.

Model template (repeat for each; example `Account`):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

const kAccountTypes = [
  'BANK', 'CASH', 'ASSET', 'CREDIT_CARD', 'LIABILITY', 'CURRENT', 'SAVINGS',
];

@freezed
abstract class Account with _$Account {
  const factory Account({
    int? id,
    @Default('') String accountName,
    String? accountNumber,
    @Default('BANK') String accountType,
    String? accountGroup,
    String? institution,
    @Default('EUR') String currency,
    @Default(0) double startBalance,
    @Default(0) double balance,
    @Default(0) int sortOrder,
    @Default(false) bool excludeFromSummary,
    @Default(false) bool excludeFromReports,
  }) = _Account;

  const Account._();

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  String get displayType => switch (accountType) {
        'BANK' => 'Bank',
        'CASH' => 'Cash',
        'ASSET' => 'Asset',
        'CREDIT_CARD' => 'Credit Card',
        'LIABILITY' => 'Liability',
        'CURRENT' => 'Current Account',
        'SAVINGS' => 'Savings Account',
        _ => accountType,
      };
}
```

Numeric caution: backend sends integers for whole amounts. Every `double` field that the old model parsed with `.toDouble()` needs `@JsonKey(fromJson: _toDouble)` (and `_toDoubleN` for nullables) — define once per file or in a shared `lib/features/json_converters.dart`:

```dart
double jsonToDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
double? jsonToDoubleN(dynamic v) => (v as num?)?.toDouble();
```

Create `lib/features/json_converters.dart` with exactly those two functions and use `@JsonKey(fromJson: jsonToDouble)` on every double field (`amount`, `balance`, `startBalance`, `units`, `currentPrice`, all statistics/dashboard doubles).

`StatisticsData` map fields: `@JsonKey(fromJson: jsonToDoubleMap) Map<String, double>` with

```dart
Map<String, double> jsonToDoubleMap(dynamic map) =>
    (map as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0)) ??
    {};
```

added to `json_converters.dart`.

`Transaction.toJson` semantics: the old model omitted response-only fields (`fromAccountName` etc.) when POSTing. With freezed, `toJson` includes everything; the backend DTO simply ignores unknown/extra name fields — acceptable. But `paymentMethod` must default to `'NONE'` when null at POST time — handle in the repository (Task 5), not the model.

DateTime fields (`transactionDate`, `nextOccurrence`, `lastUpdate`): backend sends ISO LocalDateTime without zone; default `DateTime.parse` handles it. `transactionDate`/`nextOccurrence` are non-null with `DateTime.now()` fallback in old code — keep them `required DateTime` and let the repository never hit the null case (backend always sends them); `lastUpdate` stays nullable.

- [ ] **Step 1: Write the failing model test**

`test/features/models_test.dart` — round-trip and parsing checks for the tricky models:

```dart
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/statistics/domain/statistics_data.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Account parses ints as doubles and defaults', () {
    final a = Account.fromJson(const {
      'id': 1, 'accountName': 'Giro', 'accountType': 'BANK',
      'currency': 'EUR', 'startBalance': 100, 'balance': 250,
    });
    expect(a.balance, 250.0);
    expect(a.excludeFromReports, false);
    expect(a.displayType, 'Bank');
  });

  test('Transaction parses splits and date', () {
    final t = Transaction.fromJson(const {
      'id': 5, 'type': 'EXPENSE', 'amount': 50,
      'transactionDate': '2026-05-01T12:00:00',
      'splits': [
        {'id': 1, 'categoryId': 2, 'categoryName': 'Food', 'amount': 30},
        {'id': 2, 'categoryId': 3, 'amount': 20, 'memo': 'x'},
      ],
    });
    expect(t.splits.length, 2);
    expect(t.splits.first.amount, 30.0);
    expect(t.transactionDate.year, 2026);
  });

  test('Transaction without splits key defaults to empty list', () {
    final t = Transaction.fromJson(const {
      'type': 'EXPENSE', 'amount': 10, 'transactionDate': '2026-01-01T00:00:00',
    });
    expect(t.splits, isEmpty);
  });

  test('TransactionPage parses envelope', () {
    final p = TransactionPage.fromJson(const {
      'content': [
        {'type': 'EXPENSE', 'amount': 10, 'transactionDate': '2026-01-01T00:00:00'},
      ],
      'page': 0, 'size': 50, 'totalElements': 1, 'totalPages': 1,
    });
    expect(p.content.single.amount, 10.0);
    expect(p.totalPages, 1);
  });

  test('StatisticsData parses category maps', () {
    final s = StatisticsData.fromJson(const {
      'totalIncome': 100, 'totalExpense': 40, 'balance': 60,
      'currency': 'EUR', 'transactionCount': 3,
      'expenseByCategory': {'Food': 25, 'Fuel': 15},
    });
    expect(s.expenseByCategory['Food'], 25.0);
    expect(s.monthlyIncome, isEmpty);
  });

  test('UserProfile isAdmin and vehicle category', () {
    final u = UserProfile.fromJson(const {
      'username': 'demo', 'email': 'd@x', 'firstName': 'D', 'lastName': 'M',
      'roles': ['ROLE_ADMIN'], 'defaultVehicleCategoryId': 7,
    });
    expect(u.isAdmin, true);
    expect(u.defaultVehicleCategoryId, 7);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/models_test.dart`
Expected: FAIL — imports unresolved.

- [ ] **Step 3: Write all 14 model files + converters**

Follow the `Account` template above for each model, transcribing every field/default from `lib/models/models.dart` (lines 1-593) 1:1, plus the interface additions listed above. `ScheduledTransaction.enabled` default true; `Currency` defaults (`decimalChar: ','`, `fracDigits: 2`, `groupingChar: '.'`); `UserProfile` defaults (`defaultCurrency: 'EUR'`, `darkMode: true`, `locale: 'de-DE'`, `apiEnabled: false`, `roles: const {}` — use `@Default(<String>{}) Set<String> roles`).

Then: `dart run build_runner build --delete-conflicting-outputs`
Expected: `.freezed.dart` + `.g.dart` generated for all 14 files, no errors.

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test` — Expected: PASS.
Run: `flutter analyze` — Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features test/features pubspec.lock
git commit -m "feat(models): freezed models for all domains incl. splits and pagination envelope"
```

---

### Task 3: Auth feature on Riverpod (repository, controller, screens, app lock, router)

**Files:**
- Create: `lib/features/auth/data/auth_repository.dart`, `lib/features/auth/ui/auth_controller.dart`, `lib/features/auth/ui/app_lock_observer.dart`
- Move+modify: `lib/screens/auth/login_screen.dart` → `lib/features/auth/ui/login_screen.dart`; same for `register_screen.dart`, `server_setup_screen.dart`
- Modify: `lib/main.dart`, `lib/router.dart`
- Test: `test/features/auth/auth_repository_test.dart`, `test/features/auth/login_screen_test.dart`

**Interfaces:**
- `class AuthRepository { AuthRepository(this._client); final ApiClient _client; Future<UserProfile> login(String username, String password); Future<UserProfile> register({required String username, required String email, required String password, required String firstName, required String lastName}); Future<UserProfile> getProfile(); Future<bool> fetchRegistrationEnabled(); Future<void> logout(); Future<bool> hasToken(); String get serverUrl; Future<void> setServerUrl(String url); }` — `login`/`register` POST `/auth/login`/`/auth/register`, persist `data['token']` via `_client.saveToken`, build the `UserProfile` from the auth response map (same field fallbacks as `AuthProvider.login` today). Errors: `throw ApiException.fromDio(e)`.
- `final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));`
- `AuthState` (freezed, in `auth_controller.dart`): `{UserProfile? user, @Default(true) bool registrationEnabled, @Default(Color(0xFF6750A4)) Color colorSchemeSeed, @Default(false) bool biometricEnabled, @Default(false) bool initialized}` with `bool get isLoggedIn => user != null;`
- `@Riverpod(keepAlive: true) class AuthController extends _$AuthController` — `AuthState build()` returns initial state and kicks off `_init()`; methods: `Future<void> init()` (ApiClient.init, read color/biometric prefs from `SecureStorage` keys `color_scheme_seed`/`biometric_enabled`, restore session via `getProfile()` when `hasToken()`, fetch registrationEnabled), `Future<String?> login(String u, String p)` (returns error message or null — screens show it inline like today), `Future<String?> register(...)`, `Future<void> logout()`, `Future<void> refreshProfile()`, `Future<void> setColorSchemeSeed(Color c)`, `Future<void> setBiometricEnabled(bool b)`, `Future<void> setServerUrl(String url)`, `String get serverUrl`.
- Router: `AppRouter.router` signature becomes `static GoRouter router(Listenable refresh, AuthState Function() readAuth)`; `main.dart` builds it with a `ValueNotifier`/listener bridged from `ref.listen(authControllerProvider, ...)`. Simplest concrete bridge (use exactly this): keep a small `class GoRouterRefreshNotifier extends ChangeNotifier { void refresh() => notifyListeners(); }` in `router.dart`; `main.dart` (now a `ConsumerStatefulWidget`) creates it, and in `build` does `ref.listen(authControllerProvider, (_, __) => _refreshNotifier.refresh());`. The redirect closure calls `readAuth().isLoggedIn` (passed as `() => ref.read(authControllerProvider)`).
- `class AppLockObserver extends ConsumerStatefulWidget` — wraps a child; contains the `WidgetsBindingObserver` + `LocalAuthentication` logic currently in `_CuentiAppState` (lines 22-72 of main.dart) reading `isLoggedIn`/`biometricEnabled` from `ref.read(authControllerProvider)`; renders the `_LockScreen` (move it into this file) when locked.

**Screen migration rule (applies to all three auth screens and every later screen task):** the widget tree stays identical. Mechanical replacements only:
- `StatefulWidget` → `ConsumerStatefulWidget`, `State<X>` → `ConsumerState<X>` (or `StatelessWidget` → `ConsumerWidget` adding `WidgetRef ref`).
- `context.watch<AuthProvider>()` → `ref.watch(authControllerProvider)` (+ `.notifier` for method calls); `context.read<AuthProvider>().login(...)` → `ref.read(authControllerProvider.notifier).login(...)` adapting to the new return-error-string contract (old code read `auth.error` after a bool; new code gets the message directly).
- `auth.isLoading` → local `_submitting` state flag around the await (auth controller no longer exposes isLoading; screens own their button-disable state).

`test/features/auth/auth_repository_test.dart` (pattern for all repository tests — mocktail-stubbed Dio injected through a test ApiClient):

```dart
import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

class MemoryStorage extends SecureStorage {
  MemoryStorage() : super();
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  late MockDio dio;
  late ApiClient client;
  late AuthRepository repo;

  setUp(() {
    dio = MockDio();
    client = ApiClient(MemoryStorage(), dioOverride: dio);
    repo = AuthRepository(client);
  });

  test('login saves token and returns profile', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'token': 'jwt-abc',
              'username': 'demo',
              'email': 'd@x',
              'firstName': 'D',
              'lastName': 'M',
              'roles': ['ROLE_USER'],
            }));

    final user = await repo.login('demo', 'pw');

    expect(user.username, 'demo');
    expect(await client.getToken(), 'jwt-abc');
  });

  test('login maps 401 to UnauthorizedException', () async {
    when(() => dio.post('/auth/login', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401),
      ),
    );

    expect(() => repo.login('demo', 'bad'),
        throwsA(isA<UnauthorizedException>()));
  });

  test('logout clears token', () async {
    await client.saveToken('t');
    await repo.logout();
    expect(await client.hasToken(), false);
  });
}
```

This requires `ApiClient` to accept a `dioOverride` for tests: add optional named param `ApiClient(this._storage, {Dio? dioOverride})` that skips building the real Dio when provided (interceptors still added). Add that in this task.

`test/features/auth/login_screen_test.dart` — widget test: pump `ProviderScope` with `authRepositoryProvider` overridden by a mocktail mock; enter username/password, tap login, verify mock called and error text shown on failure. (Router not needed: pump `MaterialApp(home: LoginScreen())`; navigation side effects are guarded by `if (mounted)` and the redirect lives in the router, not the screen.)

Steps: write repo test (fails: no repository) → implement repository + ApiClient dioOverride → repo test green → implement AuthState/AuthController + AppLockObserver → migrate three auth screens + router + main.dart (delete Provider usage for auth ONLY: `MultiProvider` keeps `DataProvider`; `ChangeNotifierProvider<AuthProvider>` is REMOVED and `AuthProvider` class becomes unused-but-present until Task 10 — check every remaining `context.watch<AuthProvider>`/`read<AuthProvider>` usage across `lib/` and migrate them in this task: `shell_screen.dart` and `settings_screen.dart` reference auth; for those two files replace ONLY the auth references with `ref` equivalents by converting the widgets to Consumer variants, leaving their DataProvider usage untouched) → write+run login widget test → `flutter test` + `flutter analyze` + `flutter build apk --debug` all green.

Manual smoke (document result in report): `flutter run` if a device is available, else rely on the build + tests.

Commit: `git add -A lib test && git commit -m "feat(auth): riverpod auth controller, repository, app lock, router bridge"`

---

### Task 4: Accounts feature (establishes the domain migration pattern)

**Files:**
- Create: `lib/features/accounts/data/accounts_repository.dart`, `lib/features/accounts/ui/accounts_controller.dart`
- Move+modify: `lib/screens/accounts/accounts_screen.dart` → `lib/features/accounts/ui/accounts_screen.dart`
- Modify: `lib/router.dart` (import path)
- Test: `test/features/accounts/accounts_repository_test.dart`, `test/features/accounts/accounts_controller_test.dart`

**Interfaces:**

`accounts_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_provider.dart';
import '../domain/account.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>(
    (ref) => AccountsRepository(ref.watch(dioProvider)));

class AccountsRepository {
  AccountsRepository(this._dio);
  final Dio _dio;

  Future<List<Account>> getAll() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/accounts');
        return (res.data ?? [])
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Account> save(Account account) => _guard(() async {
        final json = account.toJson()..remove('id');
        final res = account.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/accounts/${account.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/accounts', data: json);
        return Account.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/accounts/$id'));

  Future<void> updateSortOrder(List<int> ids) =>
      _guard(() => _dio.put<void>('/accounts/sort-order', data: ids));
}

/// Shared guard: rethrows DioException as ApiException. Copy this exact
/// helper into each repository file (3 lines; a shared base class would
/// couple repositories for no gain).
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
```

`accounts_controller.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';

part 'accounts_controller.g.dart';

@riverpod
class AccountsController extends _$AccountsController {
  @override
  Future<List<Account>> build() =>
      ref.watch(accountsRepositoryProvider).getAll();

  Future<void> save(Account account) async {
    await ref.read(accountsRepositoryProvider).save(account);
    ref.invalidateSelf();
    await future;
  }

  /// Optimistic delete with revert on failure (matches old DataProvider).
  Future<void> delete(int id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData(previous.where((a) => a.id != id).toList());
    try {
      await ref.read(accountsRepositoryProvider).delete(id);
      ref.invalidateSelf();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateSortOrder(List<int> ids) async {
    await ref.read(accountsRepositoryProvider).updateSortOrder(ids);
    ref.invalidateSelf();
    await future;
  }
}
```

**Screen migration mapping (DataProvider → Riverpod) — this table is the pattern every later screen task reuses with its own domain names:**

| Old (accounts_screen.dart) | New |
|---|---|
| `context.watch<DataProvider>().accounts` | `ref.watch(accountsControllerProvider)` → render via `AsyncValueWidget` |
| initState `context.read<DataProvider>().loadAccounts()` | delete — `build()` loads on first watch |
| pull-to-refresh `loadAccounts()` | `ref.invalidate(accountsControllerProvider)` (await `ref.read(accountsControllerProvider.future)` for the RefreshIndicator future) |
| `dp.saveAccount(map, id: id)` | build an `Account` model from the dialog fields, `ref.read(accountsControllerProvider.notifier).save(account)` |
| `dp.deleteAccount(id)` | `ref.read(accountsControllerProvider.notifier).delete(id)` |
| `dp.saving` gating buttons | local `_submitting` flag around await |
| error snackbar from `dp.lastError` | `try { … } on ApiException catch (e) { ScaffoldMessenger…showSnackBar(SnackBar(content: Text(e.message))); }` at the call site |

Form dialogs that built `Map<String, dynamic>` now build the freezed model (`Account(id: widget.existing?.id, accountName: nameCtrl.text, …)`).

`accounts_controller_test.dart` — ProviderContainer with `accountsRepositoryProvider` overridden by a mocktail `MockAccountsRepository`:

```dart
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

void main() {
  late MockAccountsRepository repo;
  late ProviderContainer container;

  const a1 = Account(id: 1, accountName: 'Giro');
  const a2 = Account(id: 2, accountName: 'Cash');

  setUp(() {
    repo = MockAccountsRepository();
    container = ProviderContainer(overrides: [
      accountsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads accounts', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [a1, a2]);
    final list = await container.read(accountsControllerProvider.future);
    expect(list, [a1, a2]);
  });

  test('delete is optimistic and reverts on failure', () async {
    when(() => repo.getAll()).thenAnswer((_) async => [a1, a2]);
    await container.read(accountsControllerProvider.future);
    when(() => repo.delete(1)).thenThrow(const ServerException('boom'));

    await expectLater(
      container.read(accountsControllerProvider.notifier).delete(1),
      throwsA(isA<ServerException>()),
    );
    expect(container.read(accountsControllerProvider).value, [a1, a2]);
  });
}
```

(`ServerException` import from core; add it.)

Repository test mirrors the auth one: MockDio stubs `get('/accounts')` → list of maps, asserts parsing; stubs `delete` etc. asserting paths; one DioException → ApiException mapping case.

Steps: repo test RED → repository → GREEN → controller test RED → controller (`build_runner`) → GREEN → migrate screen per table → `flutter test`, `flutter analyze`, debug build → commit `feat(accounts): accounts feature on riverpod`.

**Important:** `DataProvider.loadAccounts` is still called by other unmigrated code paths (dashboard/transactions reload accounts after saves). Leave DataProvider untouched; the accounts screen simply stops using it. Cross-feature refresh (transaction save → account balances change) is handled when transactions migrate (Task 5) via `ref.invalidate(accountsControllerProvider)`.

---

### Task 5: Transactions feature with server pagination

**Files:**
- Create: `lib/features/transactions/data/transactions_repository.dart`, `lib/features/transactions/ui/transactions_controller.dart`
- Move+modify: `lib/screens/transactions/transactions_screen.dart` → `lib/features/transactions/ui/transactions_screen.dart`; `lib/widgets/transaction_dialog.dart` → `lib/features/transactions/ui/transaction_dialog.dart`
- Modify: `lib/router.dart`, plus any file importing the old dialog path (`grep -rn "transaction_dialog" lib/`)
- Test: `test/features/transactions/transactions_repository_test.dart`, `test/features/transactions/transactions_controller_test.dart`, `test/features/transactions/transactions_screen_test.dart`, `test/features/transactions/transaction_dialog_test.dart`

**Interfaces:**

Repository:

```dart
final transactionsRepositoryProvider = Provider<TransactionsRepository>(
    (ref) => TransactionsRepository(ref.watch(dioProvider)));

class TransactionsRepository {
  TransactionsRepository(this._dio);
  final Dio _dio;

  /// Paged fetch using the Phase 1 envelope.
  Future<TransactionPage> getPage({
    int? accountId,
    int page = 0,
    int size = 50,
  }) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/transactions',
            queryParameters: {
              if (accountId != null) 'accountId': accountId,
              'page': page,
              'size': size,
            });
        return TransactionPage.fromJson(res.data!);
      });

  Future<Transaction> save(Transaction t) => _guard(() async {
        final json = t.toJson()
          ..remove('id')
          ..remove('fromAccountName')
          ..remove('toAccountName')
          ..remove('categoryName')
          ..remove('assetName')
          ..remove('status');
        json['paymentMethod'] = t.paymentMethod ?? 'NONE';
        if (t.splits.isEmpty) json.remove('splits');
        final res = t.id != null
            ? await _dio.put<Map<String, dynamic>>(
                '/transactions/${t.id}', data: json)
            : await _dio.post<Map<String, dynamic>>('/transactions',
                data: json);
        return Transaction.fromJson(res.data!);
      });

  Future<void> delete(int id) =>
      _guard(() => _dio.delete<void>('/transactions/$id'));
}
```

(NOTE `t.splits.isEmpty → remove('splits')`: preserves Phase-1 back-compat semantics — Phase 2 UI has no split editor, and sending `[]` would clear splits created elsewhere. The split editor is Phase 4.)

Controller — paged state:

```dart
part 'transactions_controller.freezed.dart';
part 'transactions_controller.g.dart';

/// Immutable paged list state for the transactions screen.
@freezed
abstract class TransactionsState with _$TransactionsState {
  const factory TransactionsState({
    @Default([]) List<Transaction> items,
    @Default(0) int nextPage,
    @Default(true) bool hasMore,
    @Default(false) bool loadingMore,
    int? accountId,
  }) = _TransactionsState;
}

@riverpod
class TransactionsController extends _$TransactionsController {
  static const pageSize = 50;

  @override
  Future<TransactionsState> build({int? accountId}) async {
    final page = await ref
        .read(transactionsRepositoryProvider)
        .getPage(accountId: accountId, page: 0, size: pageSize);
    return TransactionsState(
      items: page.content,
      nextPage: 1,
      hasMore: page.totalPages > 1,
      accountId: accountId,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref.read(transactionsRepositoryProvider).getPage(
          accountId: current.accountId,
          page: current.nextPage,
          size: pageSize);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...page.content],
        nextPage: current.nextPage + 1,
        hasMore: current.nextPage + 1 < page.totalPages,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<void> save(Transaction t) async {
    await ref.read(transactionsRepositoryProvider).save(t);
    ref.invalidateSelf();
    // Balances changed server-side:
    ref.invalidate(accountsControllerProvider);
    await future;
  }

  Future<void> delete(int id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
        items: current.items.where((t) => t.id != id).toList()));
    try {
      await ref.read(transactionsRepositoryProvider).delete(id);
      ref
        ..invalidateSelf()
        ..invalidate(accountsControllerProvider);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
```

The controller is family-keyed on `accountId` (riverpod codegen makes `build({int? accountId})` a family automatically): `ref.watch(transactionsControllerProvider(accountId: _selectedAccountId))`. The screen's existing account-filter dropdown sets local state `_selectedAccountId`, which re-targets the family — replaces the old `loadTransactions(accountId:)` calls.

Screen: same widget tree + two additions — `ScrollController` with `_scrollController.position.pixels > position.maxScrollExtent - 200 → loadMore()`, and a bottom `loadingMore` progress row when `state.loadingMore`. Old screen's manual filtering/reload logic maps per the Task 4 table.

Dialog: `transaction_dialog.dart` currently receives DataProvider lists (accounts/categories/payees) for its dropdowns. It becomes a `ConsumerStatefulWidget` reading `ref.watch(accountsControllerProvider).valueOrNull ?? []` and — until categories/payees migrate in Task 6 — **keeps reading categories/payees/tags from `context.watch<DataProvider>()`** (coexist rule; note the mixed state in a `// TODO(task-6):` comment, allowed here as a tracked cross-task marker). On save it builds a `Transaction` model and calls `transactionsControllerProvider(accountId: …).notifier.save`.

Tests:
- Repository: stubs `get('/transactions', queryParameters: {'accountId': 3, 'page': 0, 'size': 50})` → envelope map, asserts `TransactionPage` parse; asserts `save` on a splitless transaction strips `splits`, `id`, and name fields from the payload and defaults `paymentMethod` to `'NONE'` (capture with mocktail `captureAny(named: 'data')`); delete path; one ApiException mapping.
- Controller: mocked repo; `build` loads page 0; `loadMore` appends and flips `hasMore` when last page; `loadMore` no-ops when `hasMore == false`; `delete` optimistic-reverts on failure (same shape as Task 4's test).
- Screen widget test: `ProviderScope` overriding `transactionsRepositoryProvider` (2 pages of 50, then 10) + `accountsRepositoryProvider` (one account) + a `MultiProvider` shim providing the old `DataProvider` (constructed with a dummy ApiClient — never called because the screen only lists); pump, expect first 50 rendered (ListView lazily — assert `find.text` of first item), drag to bottom, expect `loadMore` called (verify repo `getPage(page: 1)` invoked).
- Dialog widget test: pump dialog with overrides + DataProvider shim; fill amount/payee, tap save, verify repo `save` captured payload has `amount` and no `splits` key.

Steps: repo test RED → repo → GREEN → controller tests RED → controller (+ build_runner) → GREEN → migrate screen + dialog → widget tests → full `flutter test` + `flutter analyze` + debug build → commit `feat(transactions): paged transactions on riverpod with infinite scroll`.

---

### Task 6: Categories, payees, tags

**Files:**
- Create per domain d ∈ {categories, payees, tags}: `lib/features/<d>/data/<d>_repository.dart`, `lib/features/<d>/ui/<d>_controller.dart`
- Move+modify: `lib/screens/categories/categories_screen.dart` → `lib/features/categories/ui/categories_screen.dart`; same for payees, tags
- Modify: `lib/router.dart`; `lib/features/transactions/ui/transaction_dialog.dart` (drop the DataProvider shim usage for categories/payees/tags → `ref.watch(categoriesControllerProvider)` etc., delete the `// TODO(task-6)` marker)
- Test: `test/features/<d>/<d>_repository_test.dart` ×3, `test/features/categories/categories_controller_test.dart`

**Interfaces (exact repeat of the Task 4 pattern with these endpoints/models):**
- `CategoriesRepository`: `getAll({String? type})` → GET `/categories` (`type` query param when non-null) → `List<Category>`; `save(Category)` (POST `/categories` / PUT `/categories/{id}`, body `{'name', 'type', 'parentId'}` — build from model, matching old `Category.toJson`); `delete(int id)`.
- `PayeesRepository`: `getAll({String? search})` → GET `/payees`; `save(Payee)` body `{'name','notes','defaultCategoryId','defaultPaymentMethod': model.defaultPaymentMethod ?? 'NONE'}`; `delete`.
- `TagsRepository`: `getAll({String? search})` → GET `/tags`; `save(Tag)` body `{'name'}`; `delete`.
- Controllers `CategoriesController`/`PayeesController`/`TagsController`: identical shape to `AccountsController` (build → getAll, save → invalidate, optimistic delete). Categories controller's `build()` takes no params (screens filter client-side by type as today).
- Providers named `categoriesControllerProvider`, `payeesControllerProvider`, `tagsControllerProvider`.

Screens migrate per the Task 4 mapping table (each screen's `loadX`/`saveX`/`deleteX` DataProvider calls → the corresponding controller). Repository tests: one parse test, one save-payload capture test, one ApiException mapping each. Controller test only for categories (the other two are identical mechanics; categories covers the shared shape — note this reasoning in the test file header).

Steps: RED→GREEN per domain (repo test, repo, controller, screen), then transaction_dialog cleanup, then `flutter test` + `flutter analyze` + debug build → commit `feat(catalog): categories, payees, tags on riverpod`.

---

### Task 7: Currencies, assets, scheduled transactions

**Files:**
- Create per domain: `lib/features/currencies/data/currencies_repository.dart` + `ui/currencies_controller.dart`; `lib/features/assets/data/assets_repository.dart` + `ui/assets_controller.dart`; `lib/features/scheduled/data/scheduled_repository.dart` + `ui/scheduled_controller.dart`
- Move+modify: the three screens into their feature `ui/` folders; `lib/router.dart`
- Test: `test/features/<d>/<d>_repository_test.dart` ×3, `test/features/scheduled/scheduled_controller_test.dart`

**Interfaces:**
- `CurrenciesRepository`: `getAll()` GET `/currencies`; `save(Currency)` (POST/PUT, body from old `Currency.toJson`: code/name/symbol/decimalChar/fracDigits/groupingChar); `delete(int id)`.
- `AssetsRepository`: `getAll({String? search})` GET `/assets`; `save(Asset)` (body symbol/name/type/currency); `delete(int id)`; `refreshPrice(int id)` POST `/assets/{id}/refresh-price` → `Asset` (parse response).
- `ScheduledRepository`: `getAll()` GET `/scheduled-transactions`; `save(ScheduledTransaction)` (body from old toJson incl. `recurrencePattern`, `recurrenceValue`, `nextOccurrence` ISO, `enabled`); `delete(int id)`; `post(int id)` POST `/scheduled-transactions/{id}/post`; `skip(int id)` POST `/scheduled-transactions/{id}/skip`.
- Controllers: standard shape; `AssetsController` adds `Future<void> refreshPrice(int id)` (calls repo then `ref.invalidateSelf(); await future;`); `ScheduledController` adds `post(int id)`/`skip(int id)` (call repo, invalidate self AND `ref.invalidate(accountsControllerProvider)` + `ref.invalidate(transactionsControllerProvider)` after `post` since posting creates a transaction — invalidating the family target invalidates every instance, filtered views included).
- `scheduled_controller_test.dart` covers `post` invalidation behavior (mock repo, verify state reloads) — the others reuse proven mechanics.

Steps as Task 6. Commit `feat(portfolio): currencies, assets, scheduled on riverpod`.

---

### Task 8: Dashboard and statistics

**Files:**
- Create: `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/ui/dashboard_controller.dart`; `lib/features/statistics/data/statistics_repository.dart`, `lib/features/statistics/ui/statistics_controller.dart`
- Move+modify: `lib/screens/dashboard/dashboard_screen.dart` → `lib/features/dashboard/ui/dashboard_screen.dart`; `lib/screens/statistics/statistics_screen.dart` → `lib/features/statistics/ui/statistics_screen.dart`
- Modify: `lib/router.dart`
- Test: `test/features/dashboard/dashboard_repository_test.dart`, `test/features/statistics/statistics_repository_test.dart`

**Interfaces:**
- `DashboardRepository.load()` → GET `/dashboard` → `DashboardData`. `@riverpod Future<DashboardData> dashboard(Ref ref)` — plain async provider (no mutations): `dashboardProvider`.
- `StatisticsRepository.load({String? start, String? end, int? accountId})` → GET `/statistics` with query params → `StatisticsData`. Controller: `@riverpod Future<StatisticsData> statistics(Ref ref, {String? start, String? end, int? accountId})` family — screen's date-range/account pickers become family args instead of manual reloads: `statisticsProvider(start: _, end: _, accountId: _)`.
- Dashboard screen also shows accounts → reuse `accountsControllerProvider` where the old screen read `dp.accounts`, or `dashboardProvider`'s embedded accounts where it read `dp.dashboard.accounts` (match old code line by line — both patterns exist; keep each usage's source).
- statistics_screen.dart is the largest file (617 lines, fl_chart rendering). The chart code does not change; only data access does. Local UI state (`_selectedRange`, pickers) stays in the State class.

Repository tests: envelope parse (dashboard: nested accounts + assetPerformance; statistics: query-param capture with start/end/accountId + map parsing). Steps as before. Commit `feat(insights): dashboard and statistics on riverpod`.

---

### Task 9: User/settings feature + shell + about

**Files:**
- Create: `lib/features/user/data/user_repository.dart`, `lib/features/user/ui/user_controller.dart`
- Move+modify: `lib/screens/settings/settings_screen.dart` → `lib/features/user/ui/settings_screen.dart`; `lib/screens/settings/about_screen.dart` → `lib/features/user/ui/about_screen.dart`
- Modify: `lib/screens/shell_screen.dart` (full Riverpod conversion — last DataProvider consumer among nav chrome), `lib/router.dart`
- Test: `test/features/user/user_repository_test.dart`

**Interfaces:**
- `UserRepository`: `getProfile()` GET `/user/profile` → `UserProfile`; `updateProfile({required String email, required String firstName, required String lastName})` PUT `/user/profile` → `UserProfile`; `updatePassword(String oldPassword, String newPassword)` PUT `/user/password`; `updatePreferences(Map<String, Object?> prefs)` PUT `/user/preferences` → `UserProfile` (the ONE map-typed boundary: preferences are a sparse patch by design; document with a comment); admin: `getAllUsers()` → `List<UserProfile>`, `setUserEnabled(int id, bool enabled)`, `deleteUser(int id)`, `getAdminSettings()` → `({bool registrationEnabled, bool apiEnabled})` record, `updateAdminSettings({bool? registrationEnabled, bool? apiEnabled})`.
- `userRepositoryProvider`. Settings screen calls repository through small `@riverpod` async functions where it needs reads (`adminUsersProvider`, `adminSettingsProvider`) and via `ref.read(userRepositoryProvider)` for writes, then refreshes `authControllerProvider` profile (`ref.read(authControllerProvider.notifier).refreshProfile()`).
- Settings screen keeps its auth-backed pieces on `authControllerProvider` (dark mode toggle → `updatePreferences` + `refreshProfile`; color scheme → `setColorSchemeSeed`; biometric → `setBiometricEnabled`) — the Task 3 migration already converted its auth references; this task converts the rest (currencies list read moves to `currenciesControllerProvider`, user/admin API calls move off `dp.userApi`).
- `shell_screen.dart`: converts to `ConsumerWidget`; any remaining DataProvider reads (badges, current user display) map to their feature providers.
- about_screen: no data dependencies expected beyond package_info — just move + fix imports (verify by reading it).

After this task `grep -rn "DataProvider\|context.watch<\|context.read<\|provider/provider" lib/ --include=*.dart` must return matches ONLY inside `lib/providers/`, `lib/api/api_services.dart`, `lib/models/models.dart`, `lib/api/api_client.dart`, and `lib/main.dart`'s MultiProvider shim — record the grep output in the report.

Repository test: profile parse, preferences patch capture, admin settings record mapping. Commit `feat(user): settings, admin and shell on riverpod`.

---

### Task 10: Remove Provider and the legacy layer

**Files:**
- Delete: `lib/providers/data_provider.dart`, `lib/providers/auth_provider.dart`, `lib/api/api_services.dart`, `lib/models/models.dart`, `lib/api/api_client.dart`, empty `lib/screens/` subfolders left after moves (`accounts`, `transactions`, `categories`, `payees`, `tags`, `currencies`, `assets`, `scheduled`, `dashboard`, `statistics`, `settings`, `auth`), `lib/widgets/` if now empty
- Modify: `lib/main.dart` (remove `MultiProvider`, remove Provider imports), `pubspec.yaml` (remove `provider`), `analysis_options.yaml` (remove any old-code lint relaxations recorded in Task 1 Step 2)
- Test: none new — the existing suite is the safety net

- [ ] **Step 1: Verify nothing references the legacy layer**

Run: `grep -rn "providers/data_provider\|providers/auth_provider\|api/api_services\|models/models.dart\|package:provider" lib/ test/ --include=*.dart`
Expected: matches only in the files being deleted and `main.dart`'s shim. If anything else matches, STOP — that reference must be migrated first (report it; do not delete around it).

- [ ] **Step 2: Delete files, strip main.dart shim, drop dependency**

```bash
git rm lib/providers/data_provider.dart lib/providers/auth_provider.dart \
       lib/api/api_services.dart lib/models/models.dart lib/api/api_client.dart
flutter pub remove provider
```

`main.dart`: `MultiProvider(providers: […], child: X)` → `X`; delete unused imports. Remove Task-1 lint relaxations from `analysis_options.yaml`.

- [ ] **Step 3: Full verification**

Run: `flutter analyze` — Expected: zero issues (relaxations gone, old code gone).
Run: `flutter test` — Expected: all green.
Run: `flutter build apk --debug` — Expected: success.
Run: `grep -rn "Map<String, dynamic>" lib/features lib/core --include=*.dart | grep -v "fromJson\|toJson\|json_converters"` — Expected: only the documented preferences patch in `user_repository.dart`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: remove provider and legacy api/model layer - riverpod migration complete"
```

---

### Task 11: Final verification & manual smoke script

- [ ] Run the full gate one more time: `flutter analyze && flutter test && flutter build apk --debug`.
- [ ] Write `docs/superpowers/plans/2026-07-12-mobile-rearchitect-SMOKE.md` with this manual checklist for the user (emulator/device): login (wrong + right password), dashboard renders, transactions list scrolls past 50 items (pagination), create + edit + delete a transaction (watch account balance change), account CRUD + reorder, categories/payees/tags CRUD, scheduled post/skip, statistics date-range change, settings (dark mode, color seed, biometric toggle, password change), admin panel (if admin), logout → login redirect, background/foreground biometric lock.
- [ ] Commit any stragglers; report done.
