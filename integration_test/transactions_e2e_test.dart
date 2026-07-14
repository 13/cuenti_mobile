import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cuentimobile/main.dart' as app;

/// On-device E2E: real app, real network (expects `adb reverse tcp:8081`
/// tunneling to a host backend in the `test` profile with demo/demo123,
/// and the app's stored server URL already pointing at
/// http://localhost:8081). Drives: login -> transactions -> load-more.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login and browse transactions end-to-end', (tester) async {
    // Point the app at the tunneled host backend before boot.
    await const SecureStorage().write('server_url', 'http://localhost:8081');

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    if (find.text('Sign in').evaluate().isNotEmpty) {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'demo');
      await tester.enterText(fields.at(1), 'demo123');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 6));
    }

    expect(find.text('Dashboard'), findsWidgets,
        reason: 'should be logged in and on the dashboard');

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Transactions'),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sparrate'), findsWidgets,
        reason: 'first page of transactions should render');

    final scrollable = find.byType(CustomScrollView).first;
    for (var i = 0; i < 15; i++) {
      await tester.drag(scrollable, const Offset(0, -800));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull,
          reason: 'scrolling/load-more must not crash (iteration $i)');
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
