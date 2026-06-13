import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/delivery_row.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../providers/earnings_summary_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  static const _periods = [
    ('day', 'Today'),
    ('week', 'This Week'),
    ('month', 'This Month'),
    ('all', 'All Time'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsSummaryProvider);
    final selectedPeriod = ref.watch(earningsPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.transparent,
      ),
      body: earningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.read(earningsSummaryProvider.notifier).refresh(),
        ),
        data: (summary) {
          final history = summary.recentDeliveries;

          return CustomScrollView(
            slivers: [
              // --- Period selector chips ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _periods.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final (value, label) = _periods[index];
                        final isSelected = value == selectedPeriod;
                        return GestureDetector(
                          onTap: () {
                            ref.read(earningsPeriodProvider.notifier).setPeriod(value);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceElevated,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // --- Gradient balance header ---
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl,
                      AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryBright, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: AppShadows.glow(AppColors.primary, strength: 0.35),
                  ),
                  child: Column(
                    children: [
                      Text(
                        selectedPeriod == 'day'
                            ? "Today's Balance"
                            : selectedPeriod == 'week'
                                ? "This Week's Earnings"
                                : selectedPeriod == 'month'
                                    ? "This Month's Earnings"
                                    : 'Total Lifetime Earnings',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        formatCurrency(summary.todayTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              tone: StatTone.onAccent,
                              icon: LucideIcons.bike,
                              value: '${summary.tripCount}',
                              label: 'Trips',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatTile(
                              tone: StatTone.onAccent,
                              icon: LucideIcons.clock,
                              value: summary.hoursOnline,
                              label: 'Time Online',
                            ),
                          ),
                          if (summary.acceptanceRate != null) ...[
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatTile(
                                tone: StatTone.onAccent,
                                icon: LucideIcons.checkCircle,
                                value: '${summary.acceptanceRate!.round()}%',
                                label: 'Acceptance',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
              ),

              // --- Recent history heading ---
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg,
                    AppSpacing.xxl, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recent History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              if (history.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateView(
                    icon: LucideIcons.packageOpen,
                    title: 'No earnings yet',
                    message: 'Completed deliveries will show up here.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = history[index];
                        return DeliveryRow(
                          title: item.type,
                          subtitle: item.time,
                          amount: formatCurrency(item.amount),
                          icon: LucideIcons.arrowDownLeft,
                          signed: true,
                        );
                      },
                      childCount: history.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxl),
              ),
            ],
          );
        },
      ),
    );
  }
}

