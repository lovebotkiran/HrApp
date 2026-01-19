import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../widgets/stat_card.dart';
import '../../../domain/providers/providers.dart';

class CandidatePortalScreen extends ConsumerWidget {
  const CandidatePortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: const Text(
              'C',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your applications and interviews',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Stats Cards
            // Stats Cards
            Consumer(
              builder: (context, ref, child) {
                final applicationsAsync = ref.watch(myApplicationsProvider);
                final interviewsAsync = ref.watch(myInterviewsProvider);
                final offersAsync = ref.watch(myOffersProvider);

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
                        title: 'Active Applications',
                        value: applicationsAsync.when(
                          data: (data) => data.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '-',
                        ),
                        icon: Icons.assignment_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: StatCard(
                        title: 'Upcoming Interviews',
                        value: interviewsAsync.when(
                          data: (data) => data.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '-',
                        ),
                        icon: Icons.calendar_today_outlined,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: StatCard(
                        title: 'Offers Received',
                        value: offersAsync.when(
                          data: (data) => data.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '-',
                        ),
                        icon: Icons.description_outlined,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isDesktop ? 4 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildQuickActionCard(
                          context,
                          Icons.assignment,
                          'My Applications',
                          () {
                            // TODO: Navigate to my applications
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          Icons.calendar_today,
                          'My Interviews',
                          () {
                            // TODO: Navigate to my interviews
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          Icons.description,
                          'My Offers',
                          () {
                            // TODO: Navigate to my offers
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          Icons.upload_file,
                          'Upload Documents',
                          () {
                            // TODO: Navigate to document upload
                          },
                        ),
                      ],
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

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
