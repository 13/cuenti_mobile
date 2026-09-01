import 'package:cuentimobile/features/audit/data/audit_repository.dart';
import 'package:cuentimobile/features/audit/domain/audit_entry.dart';
import 'package:cuentimobile/features/audit/domain/audit_page.dart';
import 'package:cuentimobile/features/audit/ui/audit_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuditRepository extends Mock implements AuditRepository {}

void main() {
  late MockAuditRepository repo;
  late ProviderContainer container;

  AuditEntry entry(int id) => AuditEntry(
    id: id,
    userId: 1,
    username: 'admin',
    timestamp: DateTime(2026, 1, id),
    entityType: 'Transaction',
    entityId: 10,
    action: 'CREATE',
    details: 'Created transaction',
  );

  setUp(() {
    repo = MockAuditRepository();
    container = ProviderContainer(
      overrides: [
        auditRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'build loads page 0 and flags hasMore when more than one page',
    () async {
      when(() => repo.getPage()).thenAnswer(
        (_) async => AuditPage(
          content: [entry(1), entry(2)],
          totalElements: 60,
          totalPages: 2,
        ),
      );

      final state = await container.read(auditControllerProvider().future);

      expect(state.items, [entry(1), entry(2)]);
      expect(state.nextPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test('build flags hasMore false for a single page', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(1)], totalElements: 1, totalPages: 1),
    );

    final state = await container.read(auditControllerProvider().future);

    expect(state.hasMore, isFalse);
  });

  test('loadMore appends items and flips hasMore false on last page', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(1)], totalElements: 2, totalPages: 2),
    );
    when(() => repo.getPage(page: 1)).thenAnswer(
      (_) async => AuditPage(
        content: [entry(2)],
        page: 1,
        totalElements: 2,
        totalPages: 2,
      ),
    );

    await container.read(auditControllerProvider().future);
    await container.read(auditControllerProvider().notifier).loadMore();

    final state = container.read(auditControllerProvider()).value!;
    expect(state.items, [entry(1), entry(2)]);
    expect(state.hasMore, isFalse);
    expect(state.loadingMore, isFalse);
  });

  test(
    'loadMore dedupes ids when the backend repeats rows across pages',
    () async {
      // Backends without a stable total order (pre-v2.10.1) can hand back
      // rows from the previous page — loadMore must not duplicate them.
      when(() => repo.getPage()).thenAnswer(
        (_) async => AuditPage(
          content: [entry(1), entry(2)],
          totalElements: 3,
          totalPages: 2,
        ),
      );
      when(() => repo.getPage(page: 1)).thenAnswer(
        (_) async => AuditPage(
          content: [entry(2), entry(3)],
          page: 1,
          totalElements: 3,
          totalPages: 2,
        ),
      );

      await container.read(auditControllerProvider().future);
      await container.read(auditControllerProvider().notifier).loadMore();

      final state = container.read(auditControllerProvider()).value!;
      expect(state.items, [entry(1), entry(2), entry(3)]);
      expect(state.items.map((e) => e.id).toSet().length, state.items.length);
    },
  );

  test(
    'dedupes ids repeated WITHIN a single page (build and loadMore)',
    () async {
      // A single page can also repeat a row internally — both the initial
      // build (page 0) and loadMore must collapse it to one item.
      when(() => repo.getPage()).thenAnswer(
        (_) async => AuditPage(
          content: [entry(1), entry(1), entry(2)],
          totalElements: 4,
          totalPages: 2,
        ),
      );
      when(() => repo.getPage(page: 1)).thenAnswer(
        (_) async => AuditPage(
          content: [entry(3), entry(3)],
          page: 1,
          totalElements: 4,
          totalPages: 2,
        ),
      );

      final built = await container.read(auditControllerProvider().future);
      expect(built.items, [entry(1), entry(2)]);

      await container.read(auditControllerProvider().notifier).loadMore();

      final state = container.read(auditControllerProvider()).value!;
      expect(state.items, [entry(1), entry(2), entry(3)]);
      expect(state.items.map((e) => e.id).toSet().length, state.items.length);
    },
  );

  test('loadMore no-ops when hasMore is false', () async {
    when(() => repo.getPage()).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(1)], totalElements: 1, totalPages: 1),
    );

    await container.read(auditControllerProvider().future);
    await container.read(auditControllerProvider().notifier).loadMore();

    verifyNever(() => repo.getPage(page: 1));
  });

  test('controller is keyed by filter family', () async {
    when(() => repo.getPage(filter: 'admin')).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(1)], totalElements: 1, totalPages: 1),
    );
    when(() => repo.getPage()).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(2)], totalElements: 1, totalPages: 1),
    );

    final withFilter = await container.read(
      auditControllerProvider(filter: 'admin').future,
    );
    final noFilter = await container.read(auditControllerProvider().future);

    expect(withFilter.items, [entry(1)]);
    expect(noFilter.items, [entry(2)]);
  });

  test('filter change creates a distinct family instance', () async {
    const filterA = 'user:1';
    const filterB = 'user:2';
    when(() => repo.getPage(filter: filterA)).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(1)], totalElements: 1, totalPages: 1),
    );
    when(() => repo.getPage(filter: filterB)).thenAnswer(
      (_) async =>
          AuditPage(content: [entry(2)], totalElements: 1, totalPages: 1),
    );

    final stateA = await container.read(
      auditControllerProvider(filter: filterA).future,
    );
    final stateB = await container.read(
      auditControllerProvider(filter: filterB).future,
    );

    expect(stateA.items, [entry(1)]);
    expect(stateB.items, [entry(2)]);
    verify(() => repo.getPage(filter: filterA)).called(1);
    verify(() => repo.getPage(filter: filterB)).called(1);
  });
}
