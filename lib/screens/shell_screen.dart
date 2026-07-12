import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/privacy/privacy_mode.dart';
import '../core/widgets/refresh_all.dart';
import '../features/auth/ui/auth_controller.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _navItems = [
    (icon: Icons.dashboard, label: 'Dashboard', path: '/dashboard'),
    (icon: Icons.receipt_long, label: 'Transactions', path: '/transactions'),
    (icon: Icons.pie_chart, label: 'Budgets', path: '/budgets'),
    (icon: Icons.bar_chart, label: 'Statistics', path: '/statistics'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].path) return i;
    }
    return 0;
  }

  String _getTitle(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/dashboard': return 'Dashboard';
      case '/transactions': return 'Transactions';
      case '/budgets': return 'Budgets';
      case '/scheduled': return 'Scheduled';
      case '/statistics': return 'Statistics';
      case '/forecasts': return 'Forecasts';
      case '/accounts': return 'Accounts';
      case '/payees': return 'Payees';
      case '/categories': return 'Categories';
      case '/tags': return 'Tags';
      case '/currencies': return 'Currencies';
      case '/assets': return 'Assets';
      case '/vehicles': return 'Vehicles';
      case '/settings': return 'Settings';
      case '/about': return 'About';
      case '/audit': return 'Audit Log';
      default: return 'Cuenti';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (auth.user?.firstName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${auth.user?.firstName ?? ''} ${auth.user?.lastName ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    auth.user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildSection(context, 'General'),
            _buildNavItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
            _buildNavItem(context, Icons.receipt_long, 'Transactions', '/transactions'),
            _buildNavItem(context, Icons.pie_chart, 'Budgets', '/budgets'),
            _buildNavItem(context, Icons.schedule, 'Scheduled', '/scheduled'),
            _buildNavItem(context, Icons.bar_chart, 'Statistics', '/statistics'),
            _buildNavItem(context, Icons.query_stats, 'Forecasts', '/forecasts'),
            const Divider(),
            _buildSection(context, 'Management'),
            _buildNavItem(context, Icons.account_balance_wallet, 'Accounts', '/accounts'),
            _buildNavItem(context, Icons.people, 'Payees', '/payees'),
            _buildNavItem(context, Icons.category, 'Categories', '/categories'),
            _buildNavItem(context, Icons.label, 'Tags', '/tags'),
            _buildNavItem(context, Icons.currency_exchange, 'Currencies', '/currencies'),
            _buildNavItem(context, Icons.show_chart, 'Assets', '/assets'),
            _buildNavItem(context, Icons.directions_car, 'Vehicles', '/vehicles'),
            const Divider(),
            _buildSection(context, 'Settings'),
            if (auth.user?.isAdmin == true)
              _buildNavItem(context, Icons.history, 'Audit Log', '/audit'),
            _buildNavItem(context, Icons.settings, 'Settings', '/settings'),
            _buildNavItem(context, Icons.info_outline, 'About', '/about'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          _getTitle(context),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              privacyMode
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            tooltip: privacyMode ? 'Show amounts' : 'Hide amounts',
            onPressed: () {
              ref.read(privacyModeProvider.notifier).toggle();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(authControllerProvider.notifier).refreshProfile();
              invalidateAllData(ref);
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) {
          context.go(_navItems[index].path);
        },
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, String path) {
    final current = GoRouterState.of(context).matchedLocation == path;
    return ListTile(
      leading: Icon(icon, color: current ? Theme.of(context).colorScheme.primary : null),
      title: Text(label,
          style: current ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold) : null),
      selected: current,
      onTap: () {
        Navigator.pop(context);
        context.go(path);
      },
    );
  }
}
