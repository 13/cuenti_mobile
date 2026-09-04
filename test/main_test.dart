import 'dart:async';

import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/transactions/data/transaction_sync.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/main.dart';
import 'package:cuentimobile/utils/number_format.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super();
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

/// Hands back a settled auth state synchronously, so the app's composition
/// root can be examined without waiting on a real sign-in.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

/// CuentiApp.initState asks for a drain on every mount; a real
/// TransactionSync needs a real (disk-backed) TransactionOutbox, which
/// these tests have no reason to open. Nothing here is about the outbox.
class _NoopSync implements TransactionSync {
  @override
  Future<int> drain() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Counts how many times the app asked it to drain, without touching the
/// outbox or the network.
class _RecordingSync implements TransactionSync {
  int drains = 0;

  @override
  Future<int> drain() async {
    drains++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Starts uninitialised, the way the real controller does, and settles
/// once [settle] is called -- so a test can watch what the app does on
/// either side of `ApiClient.init()` finishing.
class _SettlingAuthController extends AuthController {
  @override
  AuthState build() => const AuthState();

  /// The login screen calls `init()` on arrival, and the real one talks to
  /// the API client and the repository before flipping `initialized`.
  /// [settle] stands in for that, so a test controls when it happens.
  @override
  Future<void> init() async {}

  void settle() => state = state.copyWith(initialized: true);
}

/// A drain that never completes, so a test can prove the app-start call is
/// not awaited before the first frame.
class _NeverEndingSync implements TransactionSync {
  @override
  Future<int> drain() => Completer<int>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockAuthRepository repo;
  late ApiClient client;

  setUp(() {
    repo = _MockAuthRepository();
    // A real client over an in-memory store: the login screen the router
    // lands on reads its certificate pins, which a mock cannot supply.
    client = ApiClient(
      _MemoryStorage(),
      dioOverride: Dio(),
      pins: CertificatePins(_MemoryStorage()),
    );
    when(repo.hasToken).thenAnswer((_) async => false);
    when(repo.fetchRegistrationEnabled).thenAnswer((_) async => true);
    when(() => repo.serverUrl).thenReturn('https://cuenti.test');
  });

  Future<MaterialApp> pumpApp(WidgetTester tester, AuthState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuthController(state)),
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
          transactionSyncProvider.overrideWithValue(_NoopSync()),
        ],
        child: const CuentiApp(),
      ),
    );
    await tester.pump();
    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  testWidgets('follows the device theme while nobody is signed in', (
    tester,
  ) async {
    final app = await pumpApp(tester, const AuthState());

    expect(app.themeMode, ThemeMode.system);
    await tester.pumpAndSettle();
  });

  // Separate tests rather than two pumps in one: the second pump reuses the
  // same ProviderScope element, so a fresh override never takes effect.
  testWidgets('a profile asking for dark mode gets it', (tester) async {
    final app = await pumpApp(
      tester,
      // darkMode defaults to true on the model.
      const AuthState(
        user: UserProfile(username: 'd', email: 'e'),
      ),
    );

    expect(app.themeMode, ThemeMode.dark);
    await tester.pumpAndSettle();
  });

  testWidgets('a profile that has turned it off gets light', (tester) async {
    // darkMode defaults to true on the model, so this has to be explicit.
    final app = await pumpApp(
      tester,
      const AuthState(
        user: UserProfile(username: 'd', email: 'e', darkMode: false),
      ),
    );

    expect(app.themeMode, ThemeMode.light);
    await tester.pumpAndSettle();
  });

  testWidgets('offers both light and dark themes, so the device setting has '
      'something to choose between', (tester) async {
    final app = await pumpApp(tester, const AuthState());

    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
    await tester.pumpAndSettle();
  });

  testWidgets('speaks the language on the profile', (tester) async {
    // en-US, not de-DE: the model defaults to de-DE, so asking for that
    // would pass even if the profile were ignored entirely.
    final app = await pumpApp(
      tester,
      const AuthState(
        user: UserProfile(username: 'd', email: 'e', locale: 'en-US'),
      ),
    );

    expect(app.locale?.languageCode, 'en');
    await tester.pumpAndSettle();
  });

  testWidgets("sets intl's ambient locale before the first frame, so the "
      'first number formatted is already in the right one', (tester) async {
    await pumpApp(
      tester,
      const AuthState(
        user: UserProfile(username: 'd', email: 'e', locale: 'en-US'),
      ),
    );

    // 1234.5 groups as 1,234.50 in English and 1.234,50 in German, which is
    // the default -- so English is what shows the profile was read.
    expect(formatNumber(1234.5), contains('1,234'));
    await tester.pumpAndSettle();
  });

  testWidgets('carries the app lock over every screen', (tester) async {
    await pumpApp(tester, const AuthState());
    await tester.pumpAndSettle();

    expect(find.byType(CuentiApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sends whatever the outbox is holding as soon as the app is '
      'ready to send it', (tester) async {
    final sync = _RecordingSync();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(const AuthState(initialized: true)),
          ),
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
          transactionSyncProvider.overrideWithValue(sync),
        ],
        child: const CuentiApp(),
      ),
    );
    await tester.pump();

    expect(sync.drains, 1);
  });

  testWidgets('holds the app-start drain until the api client has been '
      'configured, and then sends exactly once', (tester) async {
    final sync = _RecordingSync();
    final auth = _SettlingAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
          transactionSyncProvider.overrideWithValue(sync),
        ],
        child: const CuentiApp(),
      ),
    );
    await tester.pump();

    expect(
      sync.drains,
      0,
      reason:
          'ApiClient.init() sets dio.options.baseUrl behind two '
          'platform-channel awaits; a request composed before that goes '
          'out against a base URL that is not the server',
    );

    auth.settle();
    await tester.pump();
    expect(sync.drains, 1);

    // And not again on every frame after that.
    await tester.pump();
    expect(sync.drains, 1);
  });

  testWidgets("the app-start drain doesn't hold up the first frame -- a "
      'drain that never resolves must not stop CuentiApp from rendering', (
    tester,
  ) async {
    final sync = _NeverEndingSync();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _FakeAuthController(const AuthState(initialized: true)),
          ),
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
          transactionSyncProvider.overrideWithValue(sync),
        ],
        child: const CuentiApp(),
      ),
    );
    // A single pump is enough to produce the first frame. If `main.dart`
    // ever awaited drain() before building the app, this pump would hang
    // rather than complete, because sync.drain() never resolves.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  tearDown(() async {
    // Put intl back, or a locale set here leaks into the next test file.
    applyLocale(defaultLocaleTag);
    await Future<void>.delayed(Duration.zero);
  });
}
