import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('EmptyState action fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        EmptyState(
          icon: Icons.inbox,
          message: 'Nothing here',
          actionLabel: 'Add',
          onAction: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('AsyncValueWidget loading shows skeleton', (tester) async {
    await tester.pumpWidget(
      host(
        const AsyncValueWidget<int>(
          value: AsyncLoading(),
          data: _dataText,
        ),
      ),
    );
    expect(find.byType(SkeletonLoader), findsOneWidget);
    await tester.pumpWidget(host(Container())); // dispose pulse timer
  });

  testWidgets('AsyncValueWidget error shows retry and fires callback', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      host(
        AsyncValueWidget<int>(
          value: AsyncError(Exception('boom'), StackTrace.empty),
          data: _dataText,
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  group('SkeletonLoader fits the space it is given', () {
    testWidgets('tiles taller than the space left do not overflow it', (
      tester,
    ) async {
      // Six 76px tiles want 528px; a screen with a search header above them
      // has far less to give.
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 200,
            child: SkeletonLoader.tiles(items: 6, height: 76),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(Container()));
    });

    testWidgets('a list skeleton in a short space does not overflow either', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(SizedBox(height: 120, child: SkeletonLoader.list(items: 8))),
      );

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(host(Container()));
    });

    testWidgets(
      'unbounded height still renders, as the dashboard stacks it inside a '
      'scroll view',
      (tester) async {
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: Column(
                children: [SkeletonLoader.tiles(items: 2, height: 120)],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SkeletonLoader), findsOneWidget);
        await tester.pumpWidget(host(Container()));
      },
    );
  });
}

Widget _dataText(int v) => Text('$v');
