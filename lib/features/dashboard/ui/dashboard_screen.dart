import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../utils/number_format.dart';
import '../../accounts/domain/account.dart';
import '../domain/asset_performance.dart';
import '../domain/dashboard_data.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(dashboardProvider);
        return ref.read(dashboardProvider.future);
      },
      child: AsyncValueWidget<DashboardData>(
        value: dashboardAsync,
        data: (dashboard) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Metric cards
            _MetricCard(
              title: 'Available Cash',
              value: dashboard.availableCash,
              currency: dashboard.defaultCurrency,
              color: Colors.green,
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Portfolio Value',
              value: dashboard.portfolioValue,
              currency: dashboard.defaultCurrency,
              color: Colors.blue,
              icon: Icons.show_chart,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Net Worth',
              value: dashboard.netWorth,
              currency: dashboard.defaultCurrency,
              color: Colors.purple,
              icon: Icons.savings,
            ),
            const SizedBox(height: 24),

            // Asset Performance
            if (dashboard.assetPerformance.isNotEmpty) ...[
              Text('Asset Performance',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: dashboard.assetPerformance
                      .map((a) => _AssetTile(asset: a, currency: dashboard.defaultCurrency))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Accounts
            Text('Accounts Overview',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...dashboard.accounts
                .where((a) => !a.excludeFromSummary && !a.excludeFromReports)
                .map((a) => _AccountTile(account: a)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double value;
  final String currency;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(50),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '${formatNumber(value)} $currency',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final AssetPerformance asset;
  final String currency;

  const _AssetTile({required this.asset, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPositive = asset.gainLoss >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return ListTile(
      title: Text(asset.assetName),
      subtitle: Text('${formatNumber(asset.totalUnits, decimals: 4)} units • ${asset.assetSymbol}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${formatNumber(asset.currentValue)} $currency',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '${isPositive ? '+' : ''}${formatNumber(asset.gainLoss)} (${formatNumber(asset.gainLossPercent)}%)',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(account.accountName[0].toUpperCase()),
        ),
        title: Text(account.accountName),
        subtitle: Text('${account.displayType} • ${account.currency}'),
        trailing: Text(
          '${formatNumber(account.balance)} ${account.currency}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: account.balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
