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
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/server-setup', builder: (_, __) => const ServerSetupScreen()),
        ShellRoute(
          builder: (context, state, child) => ShellScreen(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
            GoRoute(path: '/scheduled', builder: (_, __) => const ScheduledScreen()),
            GoRoute(path: '/statistics', builder: (_, __) => const StatisticsScreen()),
            GoRoute(path: '/accounts', builder: (_, __) => const AccountsScreen()),
            GoRoute(path: '/payees', builder: (_, __) => const PayeesScreen()),
            GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
            GoRoute(path: '/tags', builder: (_, __) => const TagsScreen()),
            GoRoute(path: '/currencies', builder: (_, __) => const CurrenciesScreen()),
            GoRoute(path: '/assets', builder: (_, __) => const AssetsScreen()),
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ],
        ),
      ],
    );
  }
}
