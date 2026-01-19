import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

import 'package:agentichr_frontend/data/models/job_requisition.dart';
import 'package:agentichr_frontend/presentation/screens/job_requisitions/create_job_requisition_screen.dart';

class JobRequisitionsListScreen extends ConsumerStatefulWidget {
  const JobRequisitionsListScreen({super.key});

  @override
  ConsumerState<JobRequisitionsListScreen> createState() =>
      _JobRequisitionsListScreenState();
}

class _JobRequisitionsListScreenState
    extends ConsumerState<JobRequisitionsListScreen> {
  String? _selectedStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requisitionsAsync = ref.watch(jobRequisitionsProvider(
        JobRequisitionFilter(
            status: _selectedStatus,
            search: _searchQuery.isEmpty ? null : _searchQuery)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Requisitions'),
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
              const PopupMenuItem(value: 'draft', child: Text('Draft')),
              const PopupMenuItem(
                  value: 'pending_approval', child: Text('Pending Approval')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by title, department, or ID...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: requisitionsAsync.when(
              data: (requisitions) {
                if (requisitions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline,
                            size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No requisitions found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first job requisition',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: requisitions.length,
                  itemBuilder: (context, index) {
                    final req = requisitions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          req.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(req.department),
                            const SizedBox(height: 4),
                            if (req.createdAt != null)
                              Text(
                                'Created: ${_formatDate(req.createdAt!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.send_rounded,
                                  color: Color(0xFF0077B5)), // LinkedIn Blue
                              tooltip: 'Share to LinkedIn',
                              onPressed: req.id != null
                                  ? () => _shareToLinkedIn(
                                      context, req.id!, req.title)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(_formatStatus(req.status)),
                              backgroundColor: _getStatusColor(req.status),
                            ),
                          ],
                        ),
                        onTap: () {
                          final status = req.status.toLowerCase();
                          if (status == 'draft' ||
                              status == 'pending_approval') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateJobRequisitionScreen(
                                        requisition: req),
                              ),
                            );
                          } else {
                            // TODO: Navigate to detail screen for non-draft items
                          }
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
                    Icon(Icons.error_outline,
                        size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading requisitions',
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
                      onPressed: () => ref.refresh(jobRequisitionsProvider(
                          JobRequisitionFilter(
                              status: _selectedStatus,
                              search:
                                  _searchQuery.isEmpty ? null : _searchQuery))),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/job-requisitions/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Requisition'),
      ),
    );
  }

  Future<void> _shareToLinkedIn(
      BuildContext context, String requisitionId, String title) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing to LinkedIn...')),
      );

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.shareRequisitionLinkedIn(requisitionId);

      if (mounted) {
        if (response.response.statusCode == 200 ||
            response.response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully shared "$title" to LinkedIn!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to share to LinkedIn: ${response.response.statusMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Error sharing to LinkedIn: $e';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['detail'] != null) {
          errorMessage = 'LinkedIn Error: ${e.response?.data['detail']}';
        } else if (e.response?.statusMessage != null) {
          errorMessage = 'Error: ${e.response?.statusMessage}';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'pending_approval':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppTheme.textSecondary.withValues(alpha: 0.2);
      case 'pending_approval':
        return AppTheme.warningColor.withValues(alpha: 0.2);
      case 'approved':
        return AppTheme.successColor.withValues(alpha: 0.2);
      case 'rejected':
        return AppTheme.errorColor.withValues(alpha: 0.2);
      default:
        return AppTheme.primaryColor.withValues(alpha: 0.2);
    }
  }
}
