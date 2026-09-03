import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/user/ui/widgets/edit_profile_sheet.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockApiClient extends Mock implements ApiClient {}

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
  const user = UserProfile(
    username: 'demo',
    email: 'demo@example.com',
    firstName: 'Ada',
    lastName: 'Lovelace',
  );

  late MockUserRepository repo;
  late MockAuthRepository authRepo;
  late MockApiClient apiClient;

  setUp(() {
    repo = MockUserRepository();
    authRepo = MockAuthRepository();
    apiClient = MockApiClient();
    when(() => apiClient.init()).thenAnswer((_) async {});
    when(() => authRepo.hasToken()).thenAnswer((_) async => true);
    when(
      () => authRepo.fetchRegistrationEnabled(),
    ).thenAnswer((_) async => true);
    when(() => authRepo.getProfile()).thenAnswer((_) async => user);
    when(
      () => repo.updateProfile(
        email: any(named: 'email'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenAnswer((_) async => user);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(authRepo),
          apiClientProvider.overrideWithValue(apiClient),
          secureStorageProvider.overrideWithValue(MemoryStorage()),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const EditProfileSheet(user: user),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on what the profile already holds', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Lovelace'), findsOneWidget);
    expect(find.text('demo@example.com'), findsOneWidget);
  });

  testWidgets('sends the edited name and email', (tester) async {
    await pumpSheet(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Grace');
    await tester.enterText(fields.at(2), 'grace@example.com');
    await tester.pumpAndSettle();
    await save(tester);

    verify(
      () => repo.updateProfile(
        email: 'grace@example.com',
        firstName: 'Grace',
        lastName: 'Lovelace',
      ),
    ).called(1);
  });

  testWidgets('re-reads the profile afterwards, so the settings screen shows '
      'what the server stored rather than what was typed', (tester) async {
    await pumpSheet(tester);

    await save(tester);

    verify(() => authRepo.getProfile()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('a saved profile closes the sheet', (tester) async {
    await pumpSheet(tester);

    await save(tester);

    expect(find.text('Edit Profile'), findsNothing);
  });

  testWidgets('a refused save keeps the sheet open, with the edits intact', (
    tester,
  ) async {
    when(
      () => repo.updateProfile(
        email: any(named: 'email'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenThrow(const ValidationException('Email already taken'));

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Grace');
    await tester.pumpAndSettle();
    await save(tester);

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Grace'), findsOneWidget);
  });

  testWidgets('a failure the app did not anticipate does not put developer '
      'text in front of anyone', (tester) async {
    when(
      () => repo.updateProfile(
        email: any(named: 'email'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenThrow(Exception('SocketException: connection reset by peer'));

    await pumpSheet(tester);
    await save(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('An error occurred'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets('cancelling changes nothing', (tester) async {
    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Grace');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repo.updateProfile(
        email: any(named: 'email'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    );
  });
}
