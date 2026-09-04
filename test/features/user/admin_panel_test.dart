import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/domain/user_profile.dart';
import 'package:cuentimobile/features/user/ui/widgets/admin_panel.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

const _me = UserProfile(id: 1, username: 'admin', firstName: 'Ada');
const _other = UserProfile(id: 2, username: 'bob', firstName: 'Bob');

/// Signed in as [_me], so [_other] is the only row offering actions.
class _SignedInAsAdmin extends AuthController {
  @override
  AuthState build() => const AuthState(user: _me, initialized: true);
}

void main() {
  late MockUserRepository repo;

  setUp(() {
    repo = MockUserRepository();
    when(() => repo.getAllUsers()).thenAnswer((_) async => [_me, _other]);
    when(() => repo.getAdminSettings()).thenAnswer(
      (_) async => (registrationEnabled: true, apiEnabled: false),
    );
    when(() => repo.deleteUser(any())).thenAnswer((_) async {});
    when(
      () => repo.setUserEnabled(any(), enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(repo),
          authControllerProvider.overrideWith(_SignedInAsAdmin.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: AdminPanel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenuFor(WidgetTester tester, String action) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  testWidgets('an admin cannot act on their own account', (tester) async {
    await pumpPanel(tester);

    expect(
      find.byType(PopupMenuButton<String>),
      findsOneWidget,
      reason:
          'only the other user offers a menu; deleting yourself out of '
          'your own admin panel is not on offer',
    );
  });

  testWidgets('deleting a user asks first, and cancelling deletes nothing', (
    tester,
  ) async {
    await pumpPanel(tester);
    await openMenuFor(tester, 'Delete');

    expect(find.textContaining('bob'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.deleteUser(any()));
  });

  testWidgets('confirming deletes that user and nobody else', (tester) async {
    await pumpPanel(tester);
    await openMenuFor(tester, 'Delete');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => repo.deleteUser(2)).called(1);
  });

  testWidgets('enabling and disabling a user reaches the repository', (
    tester,
  ) async {
    await pumpPanel(tester);
    await openMenuFor(tester, 'Disable');
    verify(() => repo.setUserEnabled(2, enabled: false)).called(1);

    await openMenuFor(tester, 'Enable');
    verify(() => repo.setUserEnabled(2, enabled: true)).called(1);
  });

  testWidgets('a refused delete says so instead of appearing to have worked', (
    tester,
  ) async {
    when(
      () => repo.deleteUser(any()),
    ).thenThrow(
      // serverMessage is quoted inside the translated "Invalid request:"
      // frame: the server knows why it refused and this client does not,
      // but the words around it stay in the user's language.
      const ValidationException(
        'Invalid request',
        serverMessage: 'User owns transactions',
      ),
    );

    await pumpPanel(tester);
    await openMenuFor(tester, 'Delete');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('Invalid request: User owns transactions'),
      findsOneWidget,
    );
  });
}
