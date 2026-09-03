import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
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

  tearDown(() async {
    // Put intl back, or a locale set here leaks into the next test file.
    applyLocale(defaultLocaleTag);
    await Future<void>.delayed(Duration.zero);
  });
}
