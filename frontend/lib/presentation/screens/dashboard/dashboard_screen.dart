import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:agentichr_frontend/data/models/application.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/pipeline_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final pipelineAsync = ref.watch(pipelineStatsProvider);
    final recentAppsAsync =
        ref.watch(applicationsProvider(ApplicationFilter()));
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              userAsync.when(
                data: (user) =>
                    (user['name'] as String? ?? 'A')[0].toUpperCase(),
                loading: () => '',
                error: (_, __) => '?',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSideNav(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Welcome back, ${userAsync.when(data: (u) => u['name'] ?? 'Admin', loading: () => '...', error: (_, __) => 'Admin')}!',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s what\'s happening with your recruitment today.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Cards
                  metricsAsync.when(
                    data: (metrics) {
                      // Helper function to safely get metric value
                      String getMetricValue(dynamic value) {
                        if (value == null) return '0';
                        if (value is num) {
                          if (value.isNaN || value.isInfinite) return '0';
                          return value.toInt().toString();
                        }
                        return value.toString();
                      }

                      return ResponsiveRowColumn(
                        layout: ResponsiveBreakpoints.of(context)
                                .smallerThan(DESKTOP)
                            ? ResponsiveRowColumnType.COLUMN
                            : ResponsiveRowColumnType.ROW,
                        rowSpacing: 16,
                        columnSpacing: 16,
                        children: [
                          ResponsiveRowColumnItem(
                            rowFlex: 1,
                            child: StatCard(
                              title: 'Total Applications',
                              value:
                                  getMetricValue(metrics['total_applications']),
                              change: '+12%',
                              isPositive: true,
                              icon: Icons.assignment_outlined,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          ResponsiveRowColumnItem(
                            rowFlex: 1,
                            child: StatCard(
                              title: 'Active Jobs',
                              value: getMetricValue(metrics['active_jobs']),
                              change: '+5%',
                              isPositive: true,
                              icon: Icons.work_outline,
                              color: AppTheme.successColor,
                            ),
                          ),
                          ResponsiveRowColumnItem(
                            rowFlex: 1,
                            child: StatCard(
                              title: 'Interviews Scheduled',
                              value: getMetricValue(
                                  metrics['interviews_scheduled']),
                              change: '-3%',
                              isPositive: false,
                              icon: Icons.calendar_today_outlined,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          ResponsiveRowColumnItem(
                            rowFlex: 1,
                            child: StatCard(
                              title: 'Offers Sent',
                              value: getMetricValue(metrics['offers_sent']),
                              change: '+8%',
                              isPositive: true,
                              icon: Icons.description_outlined,
                              color: AppTheme.infoColor,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: LinearProgressIndicator()),
                    error: (_, __) => const Text('Failed to load metrics'),
                  ),
                  const SizedBox(height: 32),

                  // Recruitment Pipeline
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recruitment Pipeline',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          pipelineAsync.when(
                            data: (stats) => PipelineWidget(
                              stages: Map<String, int>.from(stats),
                            ),
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (_, __) =>
                                const Text('Failed to load pipeline'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Applications',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/candidates');
                                },
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          recentAppsAsync.when(
                            data: (apps) {
                              if (apps.isEmpty) {
                                return const Text('No recent applications');
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: apps.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final app = apps[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryColor
                                          .withOpacity(0.1),
                                      child: Text(
                                        (app['candidate_name'] as String? ??
                                            'U')[0],
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                        app['candidate_name'] as String? ??
                                            'Unknown'),
                                    subtitle: Text(
                                        app['job_title'] as String? ??
                                            'Unknown Position'),
                                    trailing: Chip(
                                      label: Text(
                                          app['status'] as String? ?? 'New'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (_, __) => const Text(
                                'Failed to load recent applications'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'AgenticHR',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard', 0),
          _buildNavItem(Icons.work_outline, 'Job Requisitions', 1),
          _buildNavItem(Icons.post_add_outlined, 'Job Postings', 2),
          _buildNavItem(Icons.people_outline, 'Candidates', 3),
          _buildNavItem(Icons.assignment_outlined, 'Applications', 4),
          _buildNavItem(Icons.calendar_today_outlined, 'Interviews', 5),
          _buildNavItem(Icons.description_outlined, 'Offers', 6),
          _buildNavItem(Icons.person_add_outlined, 'Onboarding', 7),
          _buildNavItem(Icons.group_outlined, 'Referrals', 8),
          const Divider(height: 32),
          _buildNavItem(Icons.analytics_outlined, 'Analytics', 9),
          _buildNavItem(Icons.settings_outlined, 'Settings', 10),
          _buildNavItem(Icons.auto_awesome, 'AI Rankings', 11),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        _navigateToScreen(index);
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  'admin@agentichr.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard', 0),
          _buildNavItem(Icons.work_outline, 'Job Requisitions', 1),
          _buildNavItem(Icons.people_outline, 'Candidates', 3),
          _buildNavItem(Icons.calendar_today_outlined, 'Interviews', 5),
          _buildNavItem(Icons.description_outlined, 'Offers', 6),
        ],
      ),
    );
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/job-requisitions');
        break;
      case 2:
        Navigator.pushNamed(context, '/job-postings');
        break;
      case 3:
        Navigator.pushNamed(context, '/candidates');
        break;
      case 4:
        Navigator.pushNamed(context, '/applications');
        break;
      case 5:
        Navigator.pushNamed(context, '/interviews');
        break;
      case 6:
        Navigator.pushNamed(context, '/offers');
        break;
      case 7:
        Navigator.pushNamed(context, '/onboarding');
        break;
      case 8:
        Navigator.pushNamed(context, '/referrals');
        break;
      case 9:
        Navigator.pushNamed(context, '/analytics');
        break;
      case 10:
        Navigator.pushNamed(context, '/settings');
        break;
      case 11:
        Navigator.pushNamed(context, '/ai-rankings');
        break;
    }
  }
}
