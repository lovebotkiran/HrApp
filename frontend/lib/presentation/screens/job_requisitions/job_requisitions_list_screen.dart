import 'package:flutter/material.dart';
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, department, or ID...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              req.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  req.department,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                if (req.createdAt != null)
                                  Text(
                                    'Created: ${_formatDate(req.createdAt!)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary
                                              .withOpacity(0.7),
                                        ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (req.status.toLowerCase() == 'approved')
                                  IconButton(
                                    onPressed: () => _shareToLinkedIn(req),
                                    icon: const Icon(Icons.send,
                                        color: Color(0xFF0077B5)),
                                    tooltip: 'Share to LinkedIn',
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        _getStatusBackgroundColor(req.status),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: _getStatusColor(req.status)
                                          .withOpacity(0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    _formatStatus(req.status),
                                    style: TextStyle(
                                      color: _getStatusColor(req.status),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              final status = req.status.toLowerCase();
                              if (status == 'draft') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CreateJobRequisitionScreen(
                                            requisition: req),
                                  ),
                                );
                              } else if (status == 'pending_approval') {
                                _showApprovalDialog(req);
                              } else {
                                // TODO: Navigate to detail screen for non-draft items
                              }
                            },
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

  Future<void> _shareToLinkedIn(JobRequisition req) async {
    try {
      final repo = ref.read(jobRequisitionRepositoryProvider);
      await repo.shareOnLinkedIn(req.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Requisition shared to LinkedIn successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Error sharing to LinkedIn: $e';
        if (e.toString().contains('401')) {
          message =
              'LinkedIn Authentication Failed (401). Please check if your access token is valid and configured in the backend .env file.';
        } else if (e.toString().contains('400')) {
          message =
              'LinkedIn sharing is disabled or JD is missing. Please check requisition details and settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _showApprovalDialog(JobRequisition req) async {
    final commentsController = TextEditingController();
    bool isProcessing = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Approve Requisition: ${req.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Department: ${req.department}'),
              const SizedBox(height: 8),
              Text('Requested By: ${req.requestedBy ?? "Unknown"}'),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comments (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              if (isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setDialogState(() => isProcessing = true);
                      try {
                        final repo = ref.read(jobRequisitionRepositoryProvider);
                        await repo.approveRequisition(req.id!, {
                          'status': 'rejected',
                          'comments': commentsController.text,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          ref.refresh(
                              jobRequisitionsProvider(JobRequisitionFilter()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Requisition rejected')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      } finally {
                        setDialogState(() => isProcessing = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setDialogState(() => isProcessing = true);
                      try {
                        final repo = ref.read(jobRequisitionRepositoryProvider);
                        await repo.approveRequisition(req.id!, {
                          'status': 'approved',
                          'comments': commentsController.text,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          ref.refresh(
                              jobRequisitionsProvider(JobRequisitionFilter()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Requisition approved')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      } finally {
                        setDialogState(() => isProcessing = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
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
        return Colors.grey.shade600;
      case 'pending_approval':
        return const Color(0xFFD97706); // Amber 600
      case 'approved':
        return const Color(0xFF059669); // Emerald 600
      case 'rejected':
        return const Color(0xFFDC2626); // Red 600
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade50;
      case 'pending_approval':
        return const Color(0xFFFFFBEB); // Amber 50
      case 'approved':
        return const Color(0xFFECFDF5); // Emerald 50
      case 'rejected':
        return const Color(0xFFFEF2F2); // Red 50
      default:
        return AppTheme.primaryColor.withOpacity(0.1);
    }
  }
}
