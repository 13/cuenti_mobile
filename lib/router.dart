import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/server_setup_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/scheduled/scheduled_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/accounts/accounts_screen.dart';
import 'screens/payees/payees_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/tags/tags_screen.dart';
import 'screens/currencies/currencies_screen.dart';
import 'screens/assets/assets_screen.dart';
import 'screens/settings/settings_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
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
          ],
        ),
      ],
    );
  }
}
