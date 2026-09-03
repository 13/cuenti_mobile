import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:cuentimobile/features/user/ui/widgets/change_password_sheet.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repo;

  setUp(() {
    repo = MockUserRepository();
    when(() => repo.updatePassword(any(), any())).thenAnswer((_) async {});
  });

  /// Opened the way the settings screen opens it -- as a modal over a page.
  /// The sheet pops itself on success and shows its confirmation on the
  /// messenger above, so there has to be something underneath it.
  Future<void> pumpSheet(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const ChangePasswordSheet(),
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

  /// The three fields in the order the sheet lays them out.
  Future<void> fillIn(
    WidgetTester tester, {
    required String current,
    required String next,
    required String confirm,
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), current);
    await tester.enterText(fields.at(1), next);
    await tester.enterText(fields.at(2), confirm);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Change'));
    await tester.pumpAndSettle();
  }

  testWidgets('every password field is obscured', (tester) async {
    await pumpSheet(tester);

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(3));
    expect(fields.every((f) => f.obscureText), isTrue);
  });

  testWidgets('sends the current and the new password, in that order', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillIn(
      tester,
      current: 'old-one',
      next: 'new-one',
      confirm: 'new-one',
    );

    await submit(tester);

    verify(() => repo.updatePassword('old-one', 'new-one')).called(1);
  });

  testWidgets('a confirmation that does not match is caught here, without '
      'troubling the server', (tester) async {
    await pumpSheet(tester);
    await fillIn(
      tester,
      current: 'old-one',
      next: 'new-one',
      confirm: 'typo',
    );

    await submit(tester);

    verifyNever(() => repo.updatePassword(any(), any()));
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('a mismatch leaves the sheet open so it can be corrected', (
    tester,
  ) async {
    await pumpSheet(tester);
    await fillIn(tester, current: 'a', next: 'b', confirm: 'c');

    await submit(tester);

    expect(find.text('Change Password'), findsOneWidget);
  });

  testWidgets('a successful change confirms it happened', (tester) async {
    await pumpSheet(tester);
    await fillIn(tester, current: 'a', next: 'b', confirm: 'b');

    await submit(tester);

    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets("a refused change says why, in the reader's language", (
    tester,
  ) async {
    when(() => repo.updatePassword(any(), any())).thenThrow(
      const ValidationException('Current password is wrong'),
    );

    await pumpSheet(tester, locale: const Locale('de'));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'a');
    await tester.enterText(fields.at(1), 'b');
    await tester.enterText(fields.at(2), 'b');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ändern'));
    await tester.pumpAndSettle();

    expect(
      find.text('Passwort geändert'),
      findsNothing,
      reason: 'a refused change must not read as a successful one',
    );
    expect(find.text('Change Password'), findsNothing, reason: 'German sheet');
  });

  testWidgets('a failure the app did not anticipate does not put developer '
      'text in front of anyone', (tester) async {
    when(
      () => repo.updatePassword(any(), any()),
    ).thenThrow(Exception('SocketException: connection reset by peer'));

    await pumpSheet(tester);
    await fillIn(tester, current: 'a', next: 'b', confirm: 'b');

    await submit(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('An error occurred'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets('cancelling changes nothing', (tester) async {
    await pumpSheet(tester);
    await fillIn(tester, current: 'a', next: 'b', confirm: 'b');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.updatePassword(any(), any()));
  });
}
