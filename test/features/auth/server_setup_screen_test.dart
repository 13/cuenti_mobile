import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/certificate_pins.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/auth/ui/server_setup_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

const _fingerprint = 'AA:BB:CC:DD';

void main() {
  late MockAuthRepository repo;
  late CertificatePins pins;
  late ApiClient client;

  setUp(() {
    repo = MockAuthRepository();
    pins = CertificatePins(_MemoryStorage());
    client = ApiClient(_MemoryStorage(), dioOverride: Dio(), pins: pins);
    when(() => repo.serverUrl).thenReturn('https://cuenti.muh');
    when(() => repo.setServerUrl(any())).thenAnswer((_) async {});
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async => true);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/server-setup',
      routes: [
        GoRoute(
          path: '/server-setup',
          builder: (context, state) => const ServerSetupScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Text('login page'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          apiClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp.router(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save & Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('a server with a valid certificate goes straight through', (
    tester,
  ) async {
    await pumpScreen(tester);
    await save(tester);

    expect(find.text('login page'), findsOneWidget);
  });

  testWidgets('an untrusted certificate stops at a prompt showing its '
      'fingerprint instead of being accepted silently', (tester) async {
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async {
      pins.evaluate('cuenti.muh', _fingerprint);
      return true;
    });

    await pumpScreen(tester);
    await save(tester);

    expect(find.textContaining(_fingerprint), findsOneWidget);
    expect(
      find.text('login page'),
      findsNothing,
      reason: 'the user has not vouched for this certificate yet',
    );
  });

  testWidgets('trusting the certificate pins it and continues', (
    tester,
  ) async {
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async {
      pins.evaluate('cuenti.muh', _fingerprint);
      return true;
    });

    await pumpScreen(tester);
    await save(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Trust'));
    await tester.pumpAndSettle();

    expect(pins.pinFor('cuenti.muh'), _fingerprint);
    expect(find.text('login page'), findsOneWidget);
  });

  testWidgets('declining leaves the server unpinned and stays put', (
    tester,
  ) async {
    when(() => repo.fetchRegistrationEnabled()).thenAnswer((_) async {
      pins.evaluate('cuenti.muh', _fingerprint);
      return true;
    });

    await pumpScreen(tester);
    await save(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(pins.pinFor('cuenti.muh'), isNull);
    expect(find.text('login page'), findsNothing);
  });

  testWidgets('a server that is merely unreachable still lets the user on, '
      'since it may just be offline', (tester) async {
    when(
      () => repo.fetchRegistrationEnabled(),
    ).thenThrow(Exception('connection refused'));

    await pumpScreen(tester);
    await save(tester);

    expect(find.text('login page'), findsOneWidget);
  });
}
