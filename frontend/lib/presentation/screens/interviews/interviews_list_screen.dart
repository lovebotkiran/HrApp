import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class InterviewsListScreen extends ConsumerStatefulWidget {
  const InterviewsListScreen({super.key});

  @override
  ConsumerState<InterviewsListScreen> createState() => _InterviewsListScreenState();
}

class _InterviewsListScreenState extends ConsumerState<InterviewsListScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final interviewsAsync = ref.watch(interviewsProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interviews'),
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
              const PopupMenuItem(value: 'Scheduled', child: Text('Scheduled')),
              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
              const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: interviewsAsync.when(
        data: (interviews) {
          if (interviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text('No interviews found', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interviews.length,
            itemBuilder: (context, index) {
              final interview = interviews[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getStatusColor(interview.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getInterviewIcon(interview.interviewType),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(interview.interviewType),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text(_formatDateTime(interview.scheduledTime)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 16),
                          const SizedBox(width: 4),
                          Text('${interview.duration} minutes'),
                        ],
                      ),
                      if (interview.rating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: AppTheme.warningColor),
                            const SizedBox(width: 4),
                            Text('${interview.rating}/5'),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Chip(
                    label: Text(interview.status),
                    backgroundColor: _getStatusColor(interview.status),
                  ),
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
              Text('Error loading interviews', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(interviewsProvider(_selectedStatus)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/interviews/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Schedule Interview'),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getInterviewIcon(String type) {
    switch (type.toLowerCase()) {
      case 'technical':
        return Icons.code;
      case 'hr':
        return Icons.people;
      case 'behavioral':
        return Icons.psychology;
      default:
        return Icons.event;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return AppTheme.infoColor.withOpacity(0.2);
      case 'Completed':
        return AppTheme.successColor.withOpacity(0.2);
      case 'Cancelled':
        return AppTheme.errorColor.withOpacity(0.2);
      default:
        return AppTheme.primaryColor.withOpacity(0.2);
    }
  }
}
