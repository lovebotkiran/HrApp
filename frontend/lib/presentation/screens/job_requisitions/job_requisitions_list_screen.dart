import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:dio/dio.dart';

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
  String? _selectedDepartment;

  @override
  Widget build(BuildContext context) {
    final requisitionsAsync = ref.watch(jobRequisitionsProvider(
        JobRequisitionFilter(
            status: _selectedStatus, department: _selectedDepartment)));
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
          title: const Text('Job Requisitions'),
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
            Expanded(
              child: requisitionsAsync.when(
                data: (requisitions) {
                  // Filter out rejected items unless explicitly selected
                  final displayRequisitions = _selectedStatus == null
                      ? requisitions
                          .where((r) => r.status.toLowerCase() != 'rejected')
                          .toList()
                      : requisitions;

                  if (displayRequisitions.isEmpty) {
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: displayRequisitions.length,
                    itemBuilder: (context, index) {
                      final req = displayRequisitions[index];
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
                                    '${req.department}${req.location != null ? " • ${req.location}" : ""}',
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
                                  if (req.status.toLowerCase() == 'draft')
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppTheme.errorColor),
                                      onPressed: () => _confirmDelete(req),
                                      tooltip: 'Delete Requisition',
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
                                  ).then((_) =>
                                      ref.invalidate(jobRequisitionsProvider));
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
                                department: _selectedDepartment))),
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
          onPressed: () async {
            await Navigator.pushNamed(context, '/job-requisitions/create');
            ref.invalidate(jobRequisitionsProvider);
          },
          icon: const Icon(Icons.add),
          label: const Text('New Requisition'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(JobRequisition req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Requisition'),
        content: Text(
            'Are you sure you want to delete "${req.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(jobRequisitionRepositoryProvider);
        await repo.deleteRequisition(req.id!);
        if (mounted) {
          ref.invalidate(jobRequisitionsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Requisition deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting requisition: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareToLinkedIn(JobRequisition req) async {
    try {
      final repo = ref.read(jobRequisitionRepositoryProvider);
      final result = await repo.shareOnLinkedIn(req.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Requisition shared to LinkedIn successfully'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Error sharing to LinkedIn: $e';
        if (e is DioException) {
          if (e.response?.data != null && e.response!.data is Map) {
            message = (e.response!.data as Map)['detail'] ?? message;
          }
        } else if (e.toString().contains('401')) {
          message =
              'LinkedIn Authentication Failed (401). Please check if your access token is valid and configured in the backend .env file.';
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
                      if (commentsController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please provide a reason for rejection')),
                        );
                        return;
                      }
                      setDialogState(() => isProcessing = true);
                      try {
                        final repo = ref.read(jobRequisitionRepositoryProvider);
                        await repo.approveRequisition(req.id!, {
                          'status': 'rejected',
                          'comments': commentsController.text,
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          ref.invalidate(jobRequisitionsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Requisition rejected')),
                          );
                        }
                      } catch (e) {
                        String message = 'Error: $e';
                        if (e is DioException) {
                          if (e.response?.data != null &&
                              e.response!.data is Map) {
                            message =
                                (e.response!.data as Map)['detail'] ?? message;
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
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
                          ref.invalidate(jobRequisitionsProvider);
                          ref.invalidate(jobPostingsProvider);
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
