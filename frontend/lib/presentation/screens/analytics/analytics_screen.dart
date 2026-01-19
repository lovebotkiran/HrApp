import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../widgets/stat_card.dart';
import '../../../domain/providers/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final pipelineStatsAsync = ref.watch(pipelineStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // TODO: Export reports
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            Text(
              'Key Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            metricsAsync.when(
              data: (metrics) {
                final timeToHire = metrics['avg_time_to_hire'] as String? ?? '28 days';
                final offerAcceptance = metrics['offer_acceptance_rate'] as String? ?? '85%';
                final costPerHire = metrics['cost_per_hire'] as String? ?? '\$3,200';

                return ResponsiveRowColumn(
                  layout: ResponsiveBreakpoints.of(context).smallerThan(DESKTOP)
                      ? ResponsiveRowColumnType.COLUMN
                      : ResponsiveRowColumnType.ROW,
                  rowSpacing: 16,
                  columnSpacing: 16,
                  children: [
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: StatCard(
                        title: 'Avg. Time to Hire',
                        value: timeToHire,
                        change: '-5%', // TODO: Calculate change
                        isPositive: true,
                        icon: Icons.timer_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: StatCard(
                        title: 'Offer Acceptance Rate',
                        value: offerAcceptance,
                        change: '+10%', // TODO: Calculate change
                        isPositive: true,
                        icon: Icons.check_circle_outline,
                        color: AppTheme.successColor,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: StatCard(
                        title: 'Cost per Hire',
                        value: costPerHire,
                        change: '-8%', // TODO: Calculate change
                        isPositive: true,
                        icon: Icons.attach_money,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load metrics'),
            ),
            const SizedBox(height: 32),

            // Charts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applications Trend',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                const FlSpot(0, 30),
                                const FlSpot(1, 45),
                                const FlSpot(2, 40),
                                const FlSpot(3, 55),
                                const FlSpot(4, 50),
                                const FlSpot(5, 65),
                              ],
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Source Effectiveness
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source Effectiveness',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: pipelineStatsAsync.when(
                        data: (stats) {
                          // Mock data extraction from stats if structure differs
                          // Assuming stats contains source breakdown
                          return PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: 35,
                                  title: 'LinkedIn\n35%',
                                  color: AppTheme.primaryColor,
                                  radius: 100,
                                ),
                                PieChartSectionData(
                                  value: 25,
                                  title: 'Referrals\n25%',
                                  color: AppTheme.successColor,
                                  radius: 100,
                                ),
                                PieChartSectionData(
                                  value: 20,
                                  title: 'Career Page\n20%',
                                  color: AppTheme.warningColor,
                                  radius: 100,
                                ),
                                PieChartSectionData(
                                  value: 20,
                                  title: 'Others\n20%',
                                  color: AppTheme.infoColor,
                                  radius: 100,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 0,
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(child: Text('Failed to load chart')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
