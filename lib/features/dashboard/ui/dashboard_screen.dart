import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/cuenti_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/hero_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/stat_chip.dart';
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
        skeleton: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonLoader.card(height: 160),
            const SizedBox(height: 24),
            SkeletonLoader.tiles(items: 3, height: 120),
            const SizedBox(height: 24),
            SkeletonLoader.tiles(items: 2, height: 72),
          ],
        ),
        data: (dashboard) {
          final accounts = dashboard.accounts
              .where((a) => !a.excludeFromSummary && !a.excludeFromReports)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero net-worth card
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net worth',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AmountText(
                        dashboard.netWorth,
                        currency: dashboard.defaultCurrency,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: StatChip(
                              icon: Icons.account_balance_wallet,
                              label: 'Cash',
                              value:
                                  '${formatNumber(dashboard.availableCash)} ${dashboard.defaultCurrency}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: StatChip(
                              icon: Icons.trending_up,
                              label: 'Portfolio',
                              value:
                                  '${formatNumber(dashboard.portfolioValue)} ${dashboard.defaultCurrency}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Accounts section
              const SectionHeader('Accounts'),
              const SizedBox(height: 12),
              if (accounts.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) =>
                        _AccountCard(account: accounts[idx]),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: EmptyState(
                    icon: Icons.account_balance_wallet,
                    message: 'No accounts',
                  ),
                ),
              const SizedBox(height: 24),

              // Asset performance section
              if (dashboard.assetPerformance.isNotEmpty) ...[
                const SectionHeader('Assets'),
                const SizedBox(height: 12),
                Column(
                  children: dashboard.assetPerformance
                      .map(
                        (a) => _AssetTile(
                          asset: a,
                          currency: dashboard.defaultCurrency,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          );
        },
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 160,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.accountName,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                account.displayType,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AmountText(
                  account.balance,
                  currency: account.currency,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
    final gainLossColor = isPositive
        ? context.cuentiColors.income
        : context.cuentiColors.expense;
    final arrow = isPositive ? '▲' : '▼';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.assetName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${formatNumber(asset.totalUnits, decimals: 4)} units • ${asset.assetSymbol}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  asset.currentValue,
                  currency: currency,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$arrow ${formatNumber(asset.gainLossPercent.abs())}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: gainLossColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
