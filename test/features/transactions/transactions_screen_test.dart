import 'dart:io';

import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/features/accounts/data/accounts_repository.dart';
import 'package:cuentimobile/features/accounts/domain/account.dart';
import 'package:cuentimobile/features/categories/data/categories_repository.dart';
import 'package:cuentimobile/features/categories/domain/category.dart';
import 'package:cuentimobile/features/categories/ui/category_picker_field.dart';
import 'package:cuentimobile/features/payees/data/payees_repository.dart';
import 'package:cuentimobile/features/transactions/data/transaction_outbox.dart';
import 'package:cuentimobile/features/transactions/data/transactions_repository.dart';
import 'package:cuentimobile/features/transactions/domain/pending_transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_filter.dart';
import 'package:cuentimobile/features/transactions/domain/transaction_page.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_controller.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_screen.dart';
import 'package:cuentimobile/features/transactions/ui/widgets/transaction_list_parts.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockAccountsRepository extends Mock implements AccountsRepository {}

class MockCategoriesRepository extends Mock implements CategoriesRepository {}

class MockPayeesRepository extends Mock implements PayeesRepository {}

/// PrivacyMode reads this on every screen build; without an override it
/// hits the real flutter_secure_storage plugin channel, which throws
/// MissingPluginException the moment anything (runAsync, in the group
/// below) actually lets that pending real call run.
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

/// Hands TransactionTile a fixed TransactionsState without going through
/// getPage/outbox at all -- used only to construct a pending entry whose
/// Transaction object is NOT the exact instance the row is built with (the
/// case pendingFor's value-equality fallback exists for; the ordinary
/// merge path can't produce it, since mergePending always places the
/// pending entry's own object into items for a create).
class _FixedTransactionsController extends TransactionsController {
  _FixedTransactionsController(this._state);
  final TransactionsState _state;
  @override
  Future<TransactionsState> build({
    TransactionFilter filter = TransactionsController.defaultFilter,
  }) async => _state;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const TransactionFilter());
    registerFallbackValue(
      Transaction(amount: 0, transactionDate: DateTime(2026)),
    );
  });

  late MockTransactionsRepository txRepo;
  late MockAccountsRepository accountsRepo;
  late MockCategoriesRepository categoriesRepo;
  late MockPayeesRepository payeesRepo;

  Transaction tx(int id, {DateTime? date}) => Transaction(
    id: id,
    payee: 'Payee $id',
    amount: 10,
    transactionDate: date ?? DateTime(2026),
  );

  late Directory defaultOutboxDir;

  setUp(() {
    txRepo = MockTransactionsRepository();
    accountsRepo = MockAccountsRepository();
    categoriesRepo = MockCategoriesRepository();
    payeesRepo = MockPayeesRepository();
    defaultOutboxDir = Directory.systemTemp.createTempSync(
      'transactions_screen_outbox',
    );
    addTearDown(() => defaultOutboxDir.deleteSync(recursive: true));

    when(
      () => accountsRepo.getAll(),
    ).thenAnswer((_) async => [const Account(id: 1, accountName: 'Giro')]);
    when(
      () => categoriesRepo.getAll(type: any(named: 'type')),
    ).thenAnswer((_) async => []);
    when(() => payeesRepo.getAll()).thenAnswer((_) async => []);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Directory? outboxDir,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsRepositoryProvider.overrideWithValue(txRepo),
          accountsRepositoryProvider.overrideWithValue(accountsRepo),
          categoriesRepositoryProvider.overrideWithValue(categoriesRepo),
          payeesRepositoryProvider.overrideWithValue(payeesRepo),
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
          transactionOutboxProvider.overrideWithValue(
            TransactionOutbox(outboxDir ?? defaultOutboxDir),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          theme: AppTheme.light(),
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders first page and loads more on scroll to bottom', (
    tester,
  ) async {
    // mergePending sorts the whole page by date, newest first -- give each
    // row a distinct date, newer for the lower id, so id 1 stays on top
    // instead of landing wherever an unstable sort of 60 equal dates
    // happens to put it.
    DateTime dateFor(int id) => DateTime(2026).add(Duration(days: 1000 - id));
    when(
      () => txRepo.getPage(),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: List.generate(
          50,
          (i) => tx(i + 1, date: dateFor(i + 1)),
        ),
        page: 0,
        size: 50,
        totalElements: 60,
        totalPages: 2,
      ),
    );
    when(
      () => txRepo.getPage(page: 1),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: List.generate(
          10,
          (i) => tx(51 + i, date: dateFor(51 + i)),
        ),
        page: 1,
        size: 50,
        totalElements: 60,
        totalPages: 2,
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Payee 1'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100000));
    await tester.pumpAndSettle();

    verify(
      () => txRepo.getPage(page: 1),
    ).called(1);
  });

  testWidgets('shows a sticky day header per distinct day', (tester) async {
    final dayOne = DateTime(2020, 3, 5);
    final dayTwo = DateTime(2020, 3, 6);
    when(
      () => txRepo.getPage(),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [
          tx(1, date: dayTwo),
          tx(2, date: dayOne),
        ],
        page: 0,
        size: 50,
        totalElements: 2,
        totalPages: 1,
      ),
    );

    await pumpScreen(tester);

    final labelOne = DateFormat('EEE, d MMM yyyy').format(dayOne);
    final labelTwo = DateFormat('EEE, d MMM yyyy').format(dayTwo);

    expect(find.text(labelOne), findsOneWidget);
    expect(find.text(labelTwo), findsOneWidget);
  });

  testWidgets('debounces search input and requeries the repository with the '
      'search filter', (tester) async {
    when(
      () => txRepo.getPage(),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(1)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );
    when(
      () => txRepo.getPage(
        filter: const TransactionFilter(search: 'coffee'),
      ),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: [tx(2)],
        page: 0,
        size: 50,
        totalElements: 1,
        totalPages: 1,
      ),
    );

    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 200));
    verifyNever(
      () => txRepo.getPage(
        filter: const TransactionFilter(search: 'coffee'),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(
      () => txRepo.getPage(
        filter: const TransactionFilter(search: 'coffee'),
      ),
    ).called(1);
  });

  testWidgets('swipe endToStart shows the delete confirm sheet and confirming '
      'removes the row', (tester) async {
    var content = [tx(1)];
    when(
      () => txRepo.getPage(),
    ).thenAnswer(
      (_) async => TransactionPage(
        content: content,
        page: 0,
        size: 50,
        totalElements: content.length,
        totalPages: content.isEmpty ? 0 : 1,
      ),
    );
    when(() => txRepo.delete(1)).thenAnswer((_) async => content = []);

    await pumpScreen(tester);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete transaction?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => txRepo.delete(1)).called(1);
    expect(find.text('Payee 1'), findsNothing);
  });

  testWidgets(
    'shows the no-transactions-yet empty state when no filters are active',
    (tester) async {
      when(
        () => txRepo.getPage(),
      ).thenAnswer(
        (_) async => const TransactionPage(
          content: [],
          page: 0,
          size: 50,
          totalElements: 0,
          totalPages: 0,
        ),
      );

      await pumpScreen(tester);

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Add transaction'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows empty state with clear-filters action when filters yield no '
    'results',
    (tester) async {
      when(
        () => txRepo.getPage(),
      ).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(1)],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );
      when(
        () => txRepo.getPage(
          filter: const TransactionFilter(search: 'coffee'),
        ),
      ).thenAnswer(
        (_) async => const TransactionPage(
          content: [],
          page: 0,
          size: 50,
          totalElements: 0,
          totalPages: 0,
        ),
      );

      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), 'coffee');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No transactions match'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Clear filters'),
        findsOneWidget,
      );
    },
  );

  testWidgets('the category chip filters by a searched category', (
    tester,
  ) async {
    when(() => categoriesRepo.getAll(type: any(named: 'type'))).thenAnswer(
      (_) async => const [
        Category(id: 7, name: 'Groceries', fullName: 'Food:Groceries'),
        Category(id: 8, name: 'Fuel', fullName: 'Transport:Fuel'),
      ],
    );
    when(
      () => txRepo.getPage(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const TransactionPage(
        content: [],
        page: 0,
        size: 50,
        totalElements: 0,
        totalPages: 0,
      ),
    );

    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(InputChip, 'Category'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(CategorySearchSheet),
        matching: find.byType(TextField),
      ),
      'transport',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(CategorySearchSheet),
        matching: find.text('Food:Groceries'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(CategorySearchSheet),
        matching: find.text('Transport:Fuel'),
      ),
    );
    await tester.pumpAndSettle();

    final filters = verify(
      () => txRepo.getPage(
        filter: captureAny(named: 'filter'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).captured.cast<TransactionFilter>();
    expect(filters.last.categoryId, 8);
  });

  group('what has not been sent', () {
    late Directory outboxDir;

    setUp(() {
      outboxDir = Directory.systemTemp.createTempSync('screen_ob');
      when(
        () => txRepo.getPage(),
      ).thenAnswer(
        (_) async => const TransactionPage(
          content: [],
          page: 0,
          size: 50,
          totalElements: 0,
          totalPages: 1,
        ),
      );
    });
    tearDown(() => outboxDir.deleteSync(recursive: true));

    // TransactionOutbox does real disk I/O, which the widget-test clock
    // (AutomatedTestWidgetsFlutterBinding runs the body inside FakeAsync)
    // never lets complete on its own -- awaiting it directly here, or from
    // inside a tapped button's handler, hangs forever. runAsync steps
    // outside that fake clock for the real operation.
    Future<void> queue(WidgetTester tester, {String? rejection}) =>
        tester.runAsync(
          () => TransactionOutbox(outboxDir).add(
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 12.34,
                transactionDate: DateTime(2026, 9, 4),
                payee: 'Aldi',
              ),
              queuedAt: DateTime(2026, 9, 4, 10),
              rejection: rejection,
            ),
          ),
        );

    testWidgets('a transaction that has not been sent says so', (
      tester,
    ) async {
      await queue(tester);

      await pumpScreen(tester, outboxDir: outboxDir);

      expect(find.text('Aldi'), findsOneWidget);
      expect(find.text('Not sent yet'), findsOneWidget);
    });

    testWidgets('a sent transaction carries no pending mark', (tester) async {
      when(
        () => txRepo.getPage(),
      ).thenAnswer(
        (_) async => TransactionPage(
          content: [tx(1)],
          page: 0,
          size: 50,
          totalElements: 1,
          totalPages: 1,
        ),
      );

      await pumpScreen(tester, outboxDir: outboxDir);

      expect(find.text('Payee 1'), findsOneWidget);
      expect(find.text('Not sent yet'), findsNothing);
    });

    testWidgets('a refused one shows the reason, and offers to try again or '
        'discard it', (tester) async {
      await queue(tester, rejection: 'Account is closed');

      await pumpScreen(tester, outboxDir: outboxDir);

      expect(find.textContaining('Account is closed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('discarding removes it from the queue and the list', (
      tester,
    ) async {
      await queue(tester, rejection: 'Account is closed');
      await pumpScreen(tester, outboxDir: outboxDir);

      // The tap's onPressed awaits the outbox's real (disk-backed) remove.
      // A real await started outside runAsync never completes at all --
      // not just "not yet settled" -- because AutomatedTestWidgetsFlutterBinding
      // runs the test body in a FakeAsync zone that real dart:io callbacks
      // never get a turn in. The tap (which synchronously starts that
      // await) and the wait for its effect both have to happen inside
      // runAsync; pumpAndSettle only tracks scheduled frames, not this
      // unrelated real I/O, so the wait is a poll of the real outbox
      // rather than a pump.
      await tester.runAsync(() async {
        await tester.tap(find.text('Discard'));
        // Bounded: a real regression that stops removing the entry must
        // fail this test, not hang the suite.
        for (
          var i = 0;
          i < 200 && (await TransactionOutbox(outboxDir).all()).isNotEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        for (
          var i = 0;
          i < 100 && find.text('Aldi').evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 10));
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Aldi'), findsNothing);
      expect(await TransactionOutbox(outboxDir).all(), isEmpty);
    });

    testWidgets(
      'swiping away an unsent create takes it out of the queue, so the next '
      'drain does not send what the user just deleted',
      (tester) async {
        await queue(tester);
        await pumpScreen(tester, outboxDir: outboxDir);

        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();
        expect(find.text('Delete transaction?'), findsOneWidget);

        // Confirming runs the outbox's real (disk-backed) remove from
        // inside the sheet's handler, so the tap and the wait for its
        // effect both happen inside runAsync -- see the discard test above.
        await tester.runAsync(() async {
          await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
          for (
            var i = 0;
            i < 200 && (await TransactionOutbox(outboxDir).all()).isNotEmpty;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          for (
            var i = 0;
            i < 100 && find.text('Aldi').evaluate().isNotEmpty;
            i++
          ) {
            await tester.pump(const Duration(milliseconds: 10));
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        });
        await tester.pumpAndSettle();

        expect(find.text('Aldi'), findsNothing);
        expect(
          await TransactionOutbox(outboxDir).all(),
          isEmpty,
          reason:
              'the row vanished, but the entry would still have been POSTed '
              'on the next drain',
        );
        verifyNever(() => txRepo.delete(any()));
        verifyNever(
          () => txRepo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        );
      },
    );

    testWidgets(
      'editing an unsent entry replaces its outbox entry instead of '
      'queuing a second one',
      (tester) async {
        // fromAccountId set, or the EXPENSE dialog's "from account" picker
        // fails its own validator and Save never gets past _formKey.validate.
        await tester.runAsync(
          () => TransactionOutbox(outboxDir).add(
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.create,
              transaction: Transaction(
                amount: 12.34,
                transactionDate: DateTime(2026, 9, 4),
                payee: 'Aldi',
                fromAccountId: 1,
              ),
              queuedAt: DateTime(2026, 9, 4, 10),
            ),
          ),
        );
        // Still offline for the resave, or a successful save would remove
        // the entry outright rather than replace it -- either way tells
        // us nothing about whether localId made it through.
        when(
          () => txRepo.save(any(), splitsTouched: any(named: 'splitsTouched')),
        ).thenThrow(const NetworkException('Cannot connect to server'));

        await pumpScreen(tester, outboxDir: outboxDir);

        await tester.tap(find.text('Aldi'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, '99,99');

        final saveButton = find.widgetWithText(FilledButton, 'Save');
        await tester.ensureVisible(saveButton);

        // The Save button's onPressed awaits the outbox's real write, same
        // reason queue() and the Discard flow above need runAsync.
        await tester.runAsync(() async {
          await tester.tap(saveButton);
          for (
            var i = 0;
            i < 200 &&
                !(await TransactionOutbox(
                  outboxDir,
                ).all()).any((e) => e.transaction.amount == 99.99);
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        });
        await tester.pumpAndSettle();

        final entries = await TransactionOutbox(outboxDir).all();
        // The bug this guards: passing no localId through the row and the
        // dialog queues a SECOND entry beside the first instead of
        // replacing it. Assert the count, not just that an edited entry
        // exists.
        expect(entries, hasLength(1));
        expect(entries.single.localId, 'local-1');
        expect(entries.single.transaction.amount, 99.99);
      },
    );

    testWidgets(
      'a pending transaction is still marked as not sent even when the '
      'row is built with a value-equal but not identical instance',
      (tester) async {
        final queuedTransaction = Transaction(
          amount: 12.34,
          transactionDate: DateTime(2026, 9, 4),
          payee: 'Aldi',
        );
        // Field-for-field equal to queuedTransaction, but a different
        // object -- what a future .map() or copyWith() over items would
        // hand the row instead of the pending entry's own instance.
        final rowTransaction = Transaction.fromJson(queuedTransaction.toJson());
        expect(identical(rowTransaction, queuedTransaction), isFalse);
        expect(rowTransaction, queuedTransaction);

        final state = TransactionsState(
          items: [rowTransaction],
          pending: [
            PendingTransaction(
              localId: 'local-1',
              operation: PendingOperation.create,
              transaction: queuedTransaction,
              queuedAt: DateTime(2026, 9, 4, 10),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              transactionsControllerProvider().overrideWith(
                () => _FixedTransactionsController(state),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: L.localizationsDelegates,
              supportedLocales: L.supportedLocales,
              theme: AppTheme.light(),
              home: Scaffold(
                body: TransactionTile(
                  transaction: rowTransaction,
                  filter: TransactionsController.defaultFilter,
                  onDelete: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not sent yet'), findsOneWidget);
      },
    );
  });
}
