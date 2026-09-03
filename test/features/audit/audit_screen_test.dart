import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/audit/data/audit_repository.dart';
import 'package:cuentimobile/features/audit/domain/audit_entry.dart';
import 'package:cuentimobile/features/audit/domain/audit_page.dart';
import 'package:cuentimobile/features/audit/ui/audit_screen.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuditRepository extends Mock implements AuditRepository {}

void main() {
  late MockAuditRepository repo;

  final created = AuditEntry(
    id: 1,
    timestamp: DateTime(2026, 9, 3, 14, 5),
    username: 'demo',
    entityType: 'Transaction',
    action: 'CREATE',
    details: 'Aldi 12,40',
  );

  AuditPage pageOf(List<AuditEntry> entries) => AuditPage(
    content: entries,
    totalElements: entries.length,
    totalPages: 1,
  );

  setUp(() {
    repo = MockAuditRepository();
    when(
      () => repo.getPage(
        page: any(named: 'page'),
        size: any(named: 'size'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => pageOf([created]));
  });

  Future<void> pumpScreen(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [auditRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(body: AuditScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists what the server returned', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Transaction'), findsOneWidget);
    expect(find.textContaining('demo'), findsOneWidget);
  });

  testWidgets('says so when the log is empty', (tester) async {
    when(
      () => repo.getPage(
        page: any(named: 'page'),
        size: any(named: 'size'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer((_) async => pageOf([]));

    await pumpScreen(tester);

    expect(find.text('No audit entries'), findsOneWidget);
  });

  testWidgets('typing asks the server for the matching entries', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'aldi');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(
      () => repo.getPage(
        page: any(named: 'page'),
        size: any(named: 'size'),
        filter: 'aldi',
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('a search matching nothing offers to clear it', (tester) async {
    when(
      () => repo.getPage(
        page: any(named: 'page'),
        size: any(named: 'size'),
        filter: 'zzz',
      ),
    ).thenAnswer((_) async => pageOf([]));

    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No audit entries match'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Transaction'), findsOneWidget);
  });

  testWidgets('an entry with no username still renders', (tester) async {
    when(
      () => repo.getPage(
        page: any(named: 'page'),
        size: any(named: 'size'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer(
      (_) async => pageOf([
        AuditEntry(id: 2, timestamp: DateTime(2026, 9, 3), action: 'DELETE'),
      ]),
    );

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('—'), findsOneWidget);
  });

  group('the timestamp follows the reader, not one country', () {
    testWidgets('an English reader gets month first', (tester) async {
      await pumpScreen(tester, locale: const Locale('en'));

      expect(find.textContaining('9/3/2026'), findsOneWidget);
    });

    testWidgets('a German reader gets day first', (tester) async {
      await pumpScreen(tester, locale: const Locale('de'));

      expect(find.textContaining('3.9.2026'), findsOneWidget);
    });
  });
}
