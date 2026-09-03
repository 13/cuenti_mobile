import 'package:cuentimobile/core/router/transitions.dart';
import 'package:cuentimobile/features/accounts/ui/accounts_screen.dart';
import 'package:cuentimobile/features/assets/ui/assets_screen.dart';
import 'package:cuentimobile/features/audit/ui/audit_screen.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/auth/ui/login_screen.dart';
import 'package:cuentimobile/features/auth/ui/register_screen.dart';
import 'package:cuentimobile/features/auth/ui/server_setup_screen.dart';
import 'package:cuentimobile/features/budgets/ui/budgets_screen.dart';
import 'package:cuentimobile/features/categories/ui/categories_screen.dart';
import 'package:cuentimobile/features/currencies/ui/currencies_screen.dart';
import 'package:cuentimobile/features/dashboard/ui/dashboard_screen.dart';
import 'package:cuentimobile/features/forecasts/ui/forecasts_screen.dart';
import 'package:cuentimobile/features/payees/ui/payees_screen.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_screen.dart';
import 'package:cuentimobile/features/statistics/ui/statistics_screen.dart';
import 'package:cuentimobile/features/tags/ui/tags_screen.dart';
import 'package:cuentimobile/features/transactions/ui/transactions_screen.dart';
import 'package:cuentimobile/features/user/ui/about_screen.dart';
import 'package:cuentimobile/features/user/ui/settings_screen.dart';
import 'package:cuentimobile/features/vehicles/ui/vehicles_screen.dart';
import 'package:cuentimobile/screens/shell_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Bridges Riverpod's `ref.listen` callback (imperative) into a
/// `Listenable` that `GoRouter.refreshListenable` can consume.
class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class AppRouter {
  /// Reachable without a session: signing in, signing up, and pointing the
  /// app at a server -- which has to come first, since there is nothing to
  /// sign in to until it does.
  static const _openToStrangers = {'/login', '/register', '/server-setup'};

  /// Reachable only without a session: once signed in, these are behind you.
  ///
  /// Server setup is deliberately not here. It is the one page that makes
  /// sense on both sides of signing in -- Settings offers a "change server"
  /// button that goes straight to it -- and while it was treated as a
  /// sign-in page, that button bounced the user to the dashboard and did
  /// nothing else.
  static const _doneWithOnceSignedIn = {'/login', '/register'};

  /// Where a request for [location] should actually go, or null to let it
  /// through. Split out from the router so the rule that guards every screen
  /// can be read and tested on its own.
  static String? redirectFor({
    required bool loggedIn,
    required String location,
  }) {
    if (!loggedIn && !_openToStrangers.contains(location)) return '/login';
    if (loggedIn && _doneWithOnceSignedIn.contains(location)) {
      return '/dashboard';
    }
    return null;
  }

  /// Create the router once and keep it alive for the lifetime of the app.
  /// [refresh] ensures redirects re-evaluate when auth state changes,
  /// without rebuilding the entire GoRouter (which would freeze the UI).
  /// [readAuth] returns the current [AuthState] synchronously for the
  /// redirect closure below.
  static GoRouter router(Listenable refresh, AuthState Function() readAuth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: refresh,
      redirect: (context, state) => redirectFor(
        loggedIn: readAuth().isLoggedIn,
        location: state.matchedLocation,
      ),
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (_, s) =>
              fadeThroughPage(child: const LoginScreen(), state: s),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (_, s) =>
              fadeThroughPage(child: const RegisterScreen(), state: s),
        ),
        GoRoute(
          path: '/server-setup',
          pageBuilder: (_, s) =>
              fadeThroughPage(child: const ServerSetupScreen(), state: s),
        ),
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const DashboardScreen(), state: s),
            ),
            GoRoute(
              path: '/transactions',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const TransactionsScreen(), state: s),
            ),
            GoRoute(
              path: '/budgets',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const BudgetsScreen(), state: s),
            ),
            GoRoute(
              path: '/scheduled',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const ScheduledScreen(), state: s),
            ),
            GoRoute(
              path: '/statistics',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const StatisticsScreen(), state: s),
            ),
            GoRoute(
              path: '/forecasts',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const ForecastsScreen(), state: s),
            ),
            GoRoute(
              path: '/accounts',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const AccountsScreen(), state: s),
            ),
            GoRoute(
              path: '/payees',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const PayeesScreen(), state: s),
            ),
            GoRoute(
              path: '/categories',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const CategoriesScreen(), state: s),
            ),
            GoRoute(
              path: '/tags',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const TagsScreen(), state: s),
            ),
            GoRoute(
              path: '/currencies',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const CurrenciesScreen(), state: s),
            ),
            GoRoute(
              path: '/assets',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const AssetsScreen(), state: s),
            ),
            GoRoute(
              path: '/vehicles',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const VehiclesScreen(), state: s),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const SettingsScreen(), state: s),
            ),
            GoRoute(
              path: '/about',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const AboutScreen(), state: s),
            ),
            GoRoute(
              path: '/audit',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const AuditScreen(), state: s),
            ),
          ],
        ),
      ],
    );
  }
}
