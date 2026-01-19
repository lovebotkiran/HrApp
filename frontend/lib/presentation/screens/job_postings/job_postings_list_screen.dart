import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'application_form_screen.dart';
<<<<<<< HEAD
=======
import '../applications/ranked_candidates_screen.dart';
>>>>>>> origin/main

class JobPostingsListScreen extends ConsumerStatefulWidget {
  const JobPostingsListScreen({super.key});

  @override
  ConsumerState<JobPostingsListScreen> createState() => _JobPostingsListScreenState();
}

class _JobPostingsListScreenState extends ConsumerState<JobPostingsListScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final postingsAsync = ref.watch(jobPostingsProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Postings'),
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
              const PopupMenuItem(value: 'Active', child: Text('Active')),
              const PopupMenuItem(value: 'Expired', child: Text('Expired')),
              const PopupMenuItem(value: 'Draft', child: Text('Draft')),
            ],
          ),
        ],
      ),
      body: postingsAsync.when(
        data: (postings) {
          if (postings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add_outlined, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No job postings found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first job posting',
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
            itemCount: postings.length,
            itemBuilder: (context, index) {
              final posting = postings[index];
<<<<<<< HEAD
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    posting['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(posting['location'] ?? 'Location not specified'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.visibility, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('${posting['views_count'] ?? 0} views'),
                          const SizedBox(width: 16),
                          Icon(Icons.assignment, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('${posting['applications_count'] ?? 0} applications'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(posting['status'] ?? 'Unknown'),
                    backgroundColor: _getStatusColor(posting['status']),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplicationFormScreen(jobPosting: posting),
                      ),
                    );
                  },
=======
              final applicationsCount = posting['applications_count'] ?? 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        posting['title'] ?? 'Untitled',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(posting['location'] ?? 'Location not specified'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('${posting['views_count'] ?? 0} views'),
                              const SizedBox(width: 16),
                              Icon(Icons.assignment, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('$applicationsCount applications'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(posting['status'] ?? 'Unknown'),
                        backgroundColor: _getStatusColor(posting['status']),
                      ),
                    ),
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ApplicationFormScreen(jobPosting: posting),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.work_outline),
                              label: const Text('Apply'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                              ),
                            ),
                          ),
                          if (applicationsCount > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RankedCandidatesScreen(
                                        jobPostingId: posting['id'] ?? '',
                                        jobTitle: posting['title'] ?? 'Job Posting',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.analytics),
                                label: Text('Rank ($applicationsCount)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
>>>>>>> origin/main
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
                'Error loading job postings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(jobPostingsProvider(_selectedStatus)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create posting screen
        },
        icon: const Icon(Icons.add),
        label: const Text('New Posting'),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Active':
        return AppTheme.successColor.withOpacity(0.2);
      case 'Expired':
        return AppTheme.errorColor.withOpacity(0.2);
      case 'Draft':
        return AppTheme.textSecondary.withOpacity(0.2);
      default:
        return AppTheme.primaryColor.withOpacity(0.2);
    }
  }
}
