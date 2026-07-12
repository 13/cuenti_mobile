import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/ui/auth_controller.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/auth/ui/server_setup_screen.dart';
import 'screens/shell_screen.dart';
import 'features/dashboard/ui/dashboard_screen.dart';
import 'features/transactions/ui/transactions_screen.dart';
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
        final loggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/server-setup';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, s) => const RegisterScreen()),
        GoRoute(path: '/server-setup', builder: (_, s) => const ServerSetupScreen()),
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, s) => const DashboardScreen()),
            GoRoute(path: '/transactions', builder: (_, s) => const TransactionsScreen()),
            GoRoute(path: '/scheduled', builder: (_, s) => const ScheduledScreen()),
            GoRoute(path: '/statistics', builder: (_, s) => const StatisticsScreen()),
            GoRoute(path: '/accounts', builder: (_, s) => const AccountsScreen()),
            GoRoute(path: '/payees', builder: (_, s) => const PayeesScreen()),
            GoRoute(path: '/categories', builder: (_, s) => const CategoriesScreen()),
            GoRoute(path: '/tags', builder: (_, s) => const TagsScreen()),
            GoRoute(path: '/currencies', builder: (_, s) => const CurrenciesScreen()),
            GoRoute(path: '/assets', builder: (_, s) => const AssetsScreen()),
            GoRoute(path: '/settings', builder: (_, s) => const SettingsScreen()),
            GoRoute(path: '/about', builder: (_, s) => const AboutScreen()),
          ],
        ),
      ],
    );
  }
}
