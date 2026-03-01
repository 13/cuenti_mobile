import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  static const _navItems = [
    (icon: Icons.dashboard, label: 'Dashboard', path: '/dashboard'),
    (icon: Icons.receipt_long, label: 'Transactions', path: '/transactions'),
    (icon: Icons.bar_chart, label: 'Statistics', path: '/statistics'),
    (icon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dp = context.watch<DataProvider>();

    // Show error snackbar when DataProvider has an error
    if (dp.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && dp.lastError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dp.lastError!),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () {},
              ),
            ),
          );
          dp.clearError();
        }
      });
    }

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
            _buildNavItem(context, Icons.schedule, 'Scheduled', '/scheduled'),
            _buildNavItem(context, Icons.bar_chart, 'Statistics', '/statistics'),
            const Divider(),
            _buildSection(context, 'Management'),
            _buildNavItem(context, Icons.account_balance_wallet, 'Accounts', '/accounts'),
            _buildNavItem(context, Icons.people, 'Payees', '/payees'),
            _buildNavItem(context, Icons.category, 'Categories', '/categories'),
            _buildNavItem(context, Icons.label, 'Tags', '/tags'),
            _buildNavItem(context, Icons.currency_exchange, 'Currencies', '/currencies'),
            _buildNavItem(context, Icons.show_chart, 'Assets', '/assets'),
            const Divider(),
            _buildSection(context, 'Settings'),
            _buildNavItem(context, Icons.settings, 'Settings', '/settings'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                context.read<DataProvider>().clearAll();
                auth.logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Cuenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AuthProvider>().refreshProfile();
              context.read<DataProvider>().loadAll();
            },
          ),
        ],
      ),
      body: widget.child,
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
