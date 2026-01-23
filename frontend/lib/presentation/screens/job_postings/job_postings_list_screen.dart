import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:agentichr_frontend/data/models/job_posting.dart';
import '../applications/ranked_candidates_screen.dart';

class JobPostingsListScreen extends ConsumerStatefulWidget {
  const JobPostingsListScreen({super.key});

  @override
  ConsumerState<JobPostingsListScreen> createState() =>
      _JobPostingsListScreenState();
}

class _JobPostingsListScreenState extends ConsumerState<JobPostingsListScreen> {
  String? _selectedStatus;
  String? _selectedDepartment;

  @override
  Widget build(BuildContext context) {
    final postingsAsync = ref.watch(jobPostingsProvider(JobPostingFilter(
      status: _selectedStatus,
      department: _selectedDepartment,
    )));
    final departmentsAsync = ref.watch(departmentsProvider);

    final departments = departmentsAsync.value ?? [];
    if (_selectedDepartment == null && departments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedDepartment = departments.first;
        });
      });
    }

    return DefaultTabController(
      length: departments.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Postings'),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) {
              setState(() {
                _selectedDepartment = departments[index];
              });
            },
            tabs: departments.map((d) => Tab(text: d)).toList(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by Status',
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
                const PopupMenuItem(
                    value: 'Cancelled', child: Text('Cancelled')),
                const PopupMenuItem(value: 'Rejected', child: Text('Rejected')),
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
                    Icon(Icons.post_add_outlined,
                        size: 64, color: AppTheme.textSecondary),
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
                final applicationsCount = posting['applications_count'] ?? 0;
                final currentStatus = posting['status'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          posting['title'] ?? 'Untitled',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(posting['location'] ??
                                'Location not specified'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.visibility,
                                    size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text('${posting['views_count'] ?? 0} views'),
                                const SizedBox(width: 16),
                                Icon(Icons.assignment,
                                    size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text('$applicationsCount applications'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _showStatusActions(posting),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(currentStatus),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(currentStatus)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  currentStatus,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Action Buttons & Status Selector
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RankedCandidatesScreen(
                                      jobPostingId: posting['id'] ?? '',
                                      jobTitle:
                                          posting['title'] ?? 'Job Posting',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.analytics, size: 18),
                              label: Text(applicationsCount > 0
                                  ? 'Rank ($applicationsCount)'
                                  : 'Rank Pool'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: currentStatus == 'Expired'
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        '/apply/${posting['id']}',
                                      );
                                    },
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text('Apply'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  onPressed: () => ref.invalidate(jobPostingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        // FloatingActionButton removed as per requirement
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
      case 'Cancelled':
        return Colors.orange.withOpacity(0.2);
      case 'Rejected':
        return AppTheme.errorColor.withOpacity(0.2);
      default:
        return AppTheme.primaryColor.withOpacity(0.2);
    }
  }

  void _showStatusActions(Map<String, dynamic> posting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status: ${posting['title']}'),
        content: const Text('Change the current status of this job posting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePostingStatus(posting['id'], 'Expired');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Expired'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePostingStatus(posting['id'], 'Active');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Move to Active'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePostingStatus(String id, String status) async {
    try {
      final repo = ref.read(jobPostingRepositoryProvider);
      await repo.updateJobPostingStatus(id, status);
      if (mounted) {
        ref.invalidate(jobPostingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
