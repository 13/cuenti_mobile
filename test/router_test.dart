import 'package:cuentimobile/router.dart';
import 'package:flutter_test/flutter_test.dart';

/// The redirect is the whole client-side access boundary: it is what keeps a
/// signed-out session off every screen that shows money. It had no test.
void main() {
  String? redirect({required bool loggedIn, required String location}) =>
      AppRouter.redirectFor(loggedIn: loggedIn, location: location);

  group('signed out', () {
    test('any screen that shows data sends you to the login page', () {
      for (final location in [
        '/dashboard',
        '/transactions',
        '/accounts',
        '/statistics',
        '/settings',
        '/audit',
        '/budgets',
      ]) {
        expect(
          redirect(loggedIn: false, location: location),
          '/login',
          reason: '$location must not open without a session',
        );
      }
    });

    test('the login page itself is left alone', () {
      expect(redirect(loggedIn: false, location: '/login'), isNull);
    });

    test('registering is reachable, or a new user could never start', () {
      expect(redirect(loggedIn: false, location: '/register'), isNull);
    });

    test('server setup is reachable, since the app cannot sign in before it '
        'knows which server to ask', () {
      expect(redirect(loggedIn: false, location: '/server-setup'), isNull);
    });

    test('an unknown path is still sent to login rather than allowed '
        'through by default', () {
      expect(redirect(loggedIn: false, location: '/nope'), '/login');
    });
  });

  group('signed in', () {
    test('the login page hands you on to the dashboard', () {
      expect(redirect(loggedIn: true, location: '/login'), '/dashboard');
    });

    test('so does the registration page', () {
      expect(redirect(loggedIn: true, location: '/register'), '/dashboard');
    });

    test(
      'server setup stays reachable, because Settings offers a button to '
      'it and bouncing to the dashboard would make that button do nothing',
      () {
        expect(redirect(loggedIn: true, location: '/server-setup'), isNull);
      },
    );

    test('every other screen is left alone', () {
      for (final location in [
        '/dashboard',
        '/transactions',
        '/accounts',
        '/settings',
      ]) {
        expect(redirect(loggedIn: true, location: location), isNull);
      }
    });
  });
}
