import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'core/router/transitions.dart';
import 'features/auth/ui/auth_controller.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/auth/ui/server_setup_screen.dart';
import 'screens/shell_screen.dart';
import 'features/dashboard/ui/dashboard_screen.dart';
import 'features/transactions/ui/transactions_screen.dart';
import 'features/budgets/ui/budgets_screen.dart';
import 'features/scheduled/ui/scheduled_screen.dart';
import 'features/statistics/ui/statistics_screen.dart';
import 'features/accounts/ui/accounts_screen.dart';
import 'features/payees/ui/payees_screen.dart';
import 'features/categories/ui/categories_screen.dart';
import 'features/tags/ui/tags_screen.dart';
import 'features/currencies/ui/currencies_screen.dart';
import 'features/assets/ui/assets_screen.dart';
import 'features/user/ui/settings_screen.dart';
import 'features/user/ui/about_screen.dart';

/// Bridges Riverpod's `ref.listen` callback (imperative) into a
/// `Listenable` that `GoRouter.refreshListenable` can consume.
class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class AppRouter {
  /// Create the router once and keep it alive for the lifetime of the app.
  /// [refresh] ensures redirects re-evaluate when auth state changes,
  /// without rebuilding the entire GoRouter (which would freeze the UI).
  /// [readAuth] returns the current [AuthState] synchronously for the
  /// redirect closure below.
  static GoRouter router(Listenable refresh, AuthState Function() readAuth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: refresh,
      redirect: (context, state) {
        final loggedIn = readAuth().isLoggedIn;
        final loggingIn =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/server-setup';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return '/dashboard';
        return null;
      },
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
              path: '/settings',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const SettingsScreen(), state: s),
            ),
            GoRoute(
              path: '/about',
              pageBuilder: (_, s) =>
                  fadeThroughPage(child: const AboutScreen(), state: s),
            ),
          ],
        ),
      ],
    );
  }
}
