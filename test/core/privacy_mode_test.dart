import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/amount_text.dart';
import 'package:cuentimobile/core/widgets/privacy_blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('AmountText shows the amount normally when privacy mode is off',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [privacyModeProvider.overrideWith(() => _FalsePrivacyMode())],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AmountText(1234.5, currency: 'EUR')),
        ),
      ),
    );

    expect(find.textContaining('1.234,50'), findsOneWidget);
    expect(find.text('•••••'), findsNothing);
  });

  testWidgets('AmountText masks the amount when privacy mode is on',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [privacyModeProvider.overrideWith(() => _TruePrivacyMode())],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AmountText(1234.5, currency: 'EUR')),
        ),
      ),
    );

    // The real amount stays in the tree, wrapped in PrivacyBlur — it's
    // blurred visually and excluded from semantics, not text-substituted.
    expect(find.text('•••••'), findsNothing);
    expect(find.textContaining('1.234,50'), findsOneWidget);
    expect(find.byType(PrivacyBlur), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    // Excluded from semantics so screen readers don't read the number out.
    final excludeSemantics = tester.widgetList<ExcludeSemantics>(
      find.ancestor(
        of: find.byType(PrivacyBlur),
        matching: find.byType(ExcludeSemantics),
      ),
    );
    expect(excludeSemantics, hasLength(1));
    expect(excludeSemantics.single.excluding, isTrue);
  });

  test('toggle flips state and persists to secure storage', () async {
    final storage = MemoryStorage();
    final container = ProviderContainer(overrides: [
      secureStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);

    // Reading builds the notifier and schedules its async initial load
    // (no persisted value yet); let that microtask settle before toggling
    // so the toggle isn't racing the initial load.
    container.read(privacyModeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(privacyModeProvider), isFalse);

    await container.read(privacyModeProvider.notifier).toggle();
    expect(container.read(privacyModeProvider), isTrue);
    expect(await storage.read('privacy_mode'), 'true');

    await container.read(privacyModeProvider.notifier).toggle();
    expect(container.read(privacyModeProvider), isFalse);
    expect(await storage.read('privacy_mode'), 'false');
  });
}

class _FalsePrivacyMode extends PrivacyMode {
  @override
  bool build() => false;
}

class _TruePrivacyMode extends PrivacyMode {
  @override
  bool build() => true;
}
