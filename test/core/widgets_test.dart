import 'package:cuentimobile/core/theme/app_theme.dart';
import 'package:cuentimobile/core/widgets/async_value_widget.dart';
import 'package:cuentimobile/core/widgets/empty_state.dart';
import 'package:cuentimobile/core/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
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
}

Widget _dataText(int v) => Text('$v');
