import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:agentichr_frontend/data/models/application.dart';

class ApplicationsListScreen extends ConsumerStatefulWidget {
  const ApplicationsListScreen({super.key});

  @override
  ConsumerState<ApplicationsListScreen> createState() =>
      _ApplicationsListScreenState();
}

class _ApplicationsListScreenState
    extends ConsumerState<ApplicationsListScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(
        applicationsProvider(ApplicationFilter(status: _selectedStatus)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'All' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'New', child: Text('New')),
              const PopupMenuItem(value: 'Screening', child: Text('Screening')),
              const PopupMenuItem(
                  value: 'Shortlisted', child: Text('Shortlisted')),
              const PopupMenuItem(value: 'Rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No applications found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applications will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final matchScore = app['match_score'] as double?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      (app['candidate_name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    app['candidate_name'] ?? 'Unknown Candidate',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(app['job_title'] ?? 'Position not specified'),
                      const SizedBox(height: 4),
                      if (matchScore != null)
                        Row(
                          children: [
                            Icon(Icons.analytics,
                                size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('Match: ${matchScore.toStringAsFixed(0)}%'),
                          ],
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(app['status'] ?? 'Unknown'),
                        backgroundColor: _getStatusColor(app['status']),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to detail screen
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Error loading applications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(applicationsProvider(
                    ApplicationFilter(status: _selectedStatus))),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'New':
        return AppTheme.infoColor.withOpacity(0.2);
      case 'Screening':
        return AppTheme.warningColor.withOpacity(0.2);
      case 'Shortlisted':
        return AppTheme.successColor.withOpacity(0.2);
      case 'Rejected':
        return AppTheme.errorColor.withOpacity(0.2);
      default:
        return AppTheme.primaryColor.withOpacity(0.2);
    }
  }
}
