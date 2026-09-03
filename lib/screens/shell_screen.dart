import 'dart:async';

import 'package:cuentimobile/core/api/dio_provider.dart';
import 'package:cuentimobile/core/privacy/privacy_mode.dart';
import 'package:cuentimobile/core/widgets/offline_banner.dart';
import 'package:cuentimobile/core/widgets/refresh_all.dart';
import 'package:cuentimobile/features/auth/ui/auth_controller.dart';
import 'package:cuentimobile/features/scheduled/ui/scheduled_controller.dart';
import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({required this.child, super.key});
  final Widget child;

  /// Built per call rather than held as a const: the labels are localised,
  /// so they depend on the context they are shown in.
  static List<({IconData icon, String label, String path})> _navItems(
    BuildContext context,
  ) => [
    (
      icon: Icons.dashboard,
      label: L.of(context).navDashboard,
      path: '/dashboard',
    ),
    (
      icon: Icons.receipt_long,
      label: L.of(context).navTransactions,
      path: '/transactions',
    ),
    (icon: Icons.pie_chart, label: L.of(context).navBudgets, path: '/budgets'),
    (
      icon: Icons.bar_chart,
      label: L.of(context).navStatistics,
      path: '/statistics',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Built once. It used to sit in the loop condition as well as the body,
    // so a four-item bar was rebuilt up to ten times a frame, each rebuild
    // doing four localisation lookups.
    final items = _navItems(context);
    for (var i = 0; i < items.length; i++) {
      if (location == items[i].path) return i;
    }
    return 0;
  }

  String _getTitle(BuildContext context) {
    final l = L.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/dashboard':
        return l.navDashboard;
      case '/transactions':
        return l.navTransactions;
      case '/budgets':
        return l.navBudgets;
      case '/scheduled':
        return l.navScheduled;
      case '/statistics':
        return l.navStatistics;
      case '/forecasts':
        return l.navForecasts;
      case '/accounts':
        return l.navAccounts;
      case '/payees':
        return l.navPayees;
      case '/categories':
        return l.navCategories;
      case '/tags':
        return l.navTags;
      case '/currencies':
        return l.navCurrencies;
      case '/assets':
        return l.navAssets;
      case '/vehicles':
        return l.navVehicles;
      case '/settings':
        return l.navSettings;
      case '/about':
        return l.navAbout;
      case '/audit':
        return l.navAuditLog;
      default:
        return 'Cuenti';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineCache = ref.watch(apiClientProvider).offlineCache;
    final l = L.of(context);
    final auth = ref.watch(authControllerProvider);
    final privacyMode = ref.watch(privacyModeProvider);
    // Watched here rather than on the scheduled screen: the point of the
    // badge is to say something is overdue before the user goes looking.
    final overdue = ref.watch(overdueScheduledCountProvider);
    final navItems = _navItems(context);

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
                      // `??` only guards null, and firstName defaults to the
                      // empty string -- so a profile without one indexed
                      // into '' and took the whole shell down with it.
                      _avatarInitial(auth.user?.firstName),
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
            _buildSection(context, l.navGeneral),
            _buildNavItem(
              context,
              Icons.dashboard,
              l.navDashboard,
              '/dashboard',
            ),
            _buildNavItem(
              context,
              Icons.receipt_long,
              l.navTransactions,
              '/transactions',
            ),
            _buildNavItem(context, Icons.pie_chart, l.navBudgets, '/budgets'),
            _buildNavItem(
              context,
              Icons.schedule,
              l.navScheduled,
              '/scheduled',
              badgeCount: overdue,
            ),
            _buildNavItem(
              context,
              Icons.bar_chart,
              l.navStatistics,
              '/statistics',
            ),
            _buildNavItem(
              context,
              Icons.query_stats,
              l.navForecasts,
              '/forecasts',
            ),
            _buildNavItem(
              context,
              Icons.directions_car,
              l.navVehicles,
              '/vehicles',
            ),
            const Divider(),
            _buildSection(context, l.navManagement),
            _buildNavItem(
              context,
              Icons.account_balance_wallet,
              l.navAccounts,
              '/accounts',
            ),
            _buildNavItem(context, Icons.people, l.navPayees, '/payees'),
            _buildNavItem(
              context,
              Icons.category,
              l.navCategories,
              '/categories',
            ),
            _buildNavItem(context, Icons.label, l.navTags, '/tags'),
            _buildNavItem(
              context,
              Icons.currency_exchange,
              l.navCurrencies,
              '/currencies',
            ),
            _buildNavItem(context, Icons.show_chart, l.navAssets, '/assets'),
            const Divider(),
            _buildSection(context, l.navSettingsSection),
            if (auth.user?.isAdmin == true)
              _buildNavItem(context, Icons.history, l.navAuditLog, '/audit'),
            _buildNavItem(context, Icons.settings, l.navSettings, '/settings'),
            _buildNavItem(context, Icons.info_outline, l.navAbout, '/about'),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(L.of(context).actionLogout),
              onTap: () async {
                // Capture the router before the gap: popping the drawer
                // tears this ListTile's context down, so it cannot route
                // once the sign-out completes.
                final router = GoRouter.of(context);
                Navigator.pop(context);
                await ref.read(authControllerProvider.notifier).logout();
                router.go('/login');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        // Spelled out rather than left to Scaffold, so the badge can ride
        // on it: the drawer item alerts nobody while the drawer is shut.
        leading: Builder(
          builder: (context) {
            const menu = Icon(Icons.menu);
            return IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: overdue > 0
                  ? Semantics(
                      label: l.scheduledOverdue(overdue),
                      child: const Badge(child: menu),
                    )
                  : menu,
              onPressed: Scaffold.of(context).openDrawer,
            );
          },
        ),
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
            tooltip: privacyMode ? l.privacyShow : l.privacyHide,
            onPressed: () {
              unawaited(ref.read(privacyModeProvider.notifier).toggle());
            },
          ),
          IconButton(
            tooltip: L.of(context).actionRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              unawaited(
                ref.read(authControllerProvider.notifier).refreshProfile(),
              );
              invalidateAllData(ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // In the shell so every screen inherits it: any of them can be
          // showing replayed figures.
          if (offlineCache != null)
            OfflineBanner(
              stale: offlineCache.stale,
              since: offlineCache.staleSince,
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => context.go(navItems[index].path),
        destinations: [
          for (final item in navItems)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
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

  /// The letter on the drawer avatar: the first of [firstName], or 'U' when
  /// there is nothing to take one from.
  static String _avatarInitial(String? firstName) {
    final trimmed = firstName?.trim() ?? '';
    return trimmed.isEmpty ? 'U' : trimmed[0].toUpperCase();
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String path, {
    int badgeCount = 0,
  }) {
    final current = GoRouterState.of(context).matchedLocation == path;
    final leading = Icon(
      icon,
      color: current ? Theme.of(context).colorScheme.primary : null,
    );
    return ListTile(
      // The count is spelled out for a screen reader, which would otherwise
      // announce a bare "3" beside the label and leave it at that.
      leading: badgeCount > 0
          ? Semantics(
              label: L.of(context).scheduledOverdue(badgeCount),
              child: ExcludeSemantics(
                child: Badge.count(count: badgeCount, child: leading),
              ),
            )
          : leading,
      title: Text(
        label,
        style: current
            ? TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
      selected: current,
      onTap: () {
        Navigator.pop(context);
        context.go(path);
      },
    );
  }
}
