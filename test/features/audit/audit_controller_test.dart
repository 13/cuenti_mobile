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
    container = ProviderContainer(overrides: [
      auditRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('build loads page 0 and flags hasMore when more than one page', () async {
    when(() => repo.getPage(filter: null, page: 0, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(1), entry(2)], page: 0, size: 50, totalElements: 60, totalPages: 2));

    final state = await container
        .read(auditControllerProvider(filter: null).future);

    expect(state.items, [entry(1), entry(2)]);
    expect(state.nextPage, 1);
    expect(state.hasMore, isTrue);
  });

  test('build flags hasMore false for a single page', () async {
    when(() => repo.getPage(filter: null, page: 0, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    final state = await container
        .read(auditControllerProvider(filter: null).future);

    expect(state.hasMore, isFalse);
  });

  test('loadMore appends items and flips hasMore false on last page', () async {
    when(() => repo.getPage(filter: null, page: 0, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(1)], page: 0, size: 50, totalElements: 2, totalPages: 2));
    when(() => repo.getPage(filter: null, page: 1, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(2)], page: 1, size: 50, totalElements: 2, totalPages: 2));

    await container
        .read(auditControllerProvider(filter: null).future);
    await container
        .read(auditControllerProvider(filter: null).notifier)
        .loadMore();

    final state = container
        .read(auditControllerProvider(filter: null))
        .value!;
    expect(state.items, [entry(1), entry(2)]);
    expect(state.hasMore, isFalse);
    expect(state.loadingMore, isFalse);
  });

  test('loadMore no-ops when hasMore is false', () async {
    when(() => repo.getPage(filter: null, page: 0, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    await container
        .read(auditControllerProvider(filter: null).future);
    await container
        .read(auditControllerProvider(filter: null).notifier)
        .loadMore();

    verifyNever(
        () => repo.getPage(filter: null, page: 1, size: 50));
  });

  test('controller is keyed by filter family', () async {
    when(() => repo.getPage(filter: 'admin', page: 0, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));
    when(() => repo.getPage(filter: null, page: 0, size: 50))
        .thenAnswer((_) async => AuditPage(
            content: [entry(2)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    final withFilter = await container.read(
        auditControllerProvider(filter: 'admin')
            .future);
    final noFilter = await container
        .read(auditControllerProvider(filter: null).future);

    expect(withFilter.items, [entry(1)]);
    expect(noFilter.items, [entry(2)]);
  });

  test('filter change creates a distinct family instance', () async {
    const filterA = 'user:1';
    const filterB = 'user:2';
    when(() => repo.getPage(filter: filterA, page: 0, size: 50)).thenAnswer(
        (_) async => AuditPage(
            content: [entry(1)], page: 0, size: 50, totalElements: 1, totalPages: 1));
    when(() => repo.getPage(filter: filterB, page: 0, size: 50)).thenAnswer(
        (_) async => AuditPage(
            content: [entry(2)], page: 0, size: 50, totalElements: 1, totalPages: 1));

    final stateA =
        await container.read(auditControllerProvider(filter: filterA).future);
    final stateB =
        await container.read(auditControllerProvider(filter: filterB).future);

    expect(stateA.items, [entry(1)]);
    expect(stateB.items, [entry(2)]);
    verify(() => repo.getPage(filter: filterA, page: 0, size: 50)).called(1);
    verify(() => repo.getPage(filter: filterB, page: 0, size: 50)).called(1);
  });
}
