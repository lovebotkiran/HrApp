import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class ReferralsListScreen extends ConsumerStatefulWidget {
  const ReferralsListScreen({super.key});

  @override
  ConsumerState<ReferralsListScreen> createState() => _ReferralsListScreenState();
}

class _ReferralsListScreenState extends ConsumerState<ReferralsListScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final referralsAsync = ref.watch(referralsProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Referrals'),
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
              const PopupMenuItem(value: 'Pending', child: Text('Pending')),
              const PopupMenuItem(value: 'Screening', child: Text('Screening')),
              const PopupMenuItem(value: 'Hired', child: Text('Hired')),
              const PopupMenuItem(value: 'Rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: referralsAsync.when(
        data: (referrals) {
          if (referrals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No referrals found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Employee referrals will appear here',
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
            itemCount: referrals.length,
            itemBuilder: (context, index) {
              final referral = referrals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                    child: const Icon(Icons.person_add, color: AppTheme.successColor),
                  ),
                  title: Text(
                    referral['candidate_name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Position: ${referral['position'] ?? 'Not specified'}'),
                      const SizedBox(height: 4),
                      Text(
                        'Referred by: ${referral['referrer_name'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (referral['bonus_amount'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: AppTheme.successColor),
                            Text(
                              'Bonus: \$${referral['bonus_amount']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Chip(
                    label: Text(referral['status'] ?? 'Unknown'),
                    backgroundColor: _getStatusColor(referral['status']),
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
                'Error loading referrals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(referralsProvider(_selectedStatus)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create referral screen
        },
        icon: const Icon(Icons.add),
        label: const Text('New Referral'),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return AppTheme.warningColor.withOpacity(0.2);
      case 'Screening':
        return AppTheme.infoColor.withOpacity(0.2);
      case 'Hired':
        return AppTheme.successColor.withOpacity(0.2);
      case 'Rejected':
        return AppTheme.errorColor.withOpacity(0.2);
      default:
        return AppTheme.primaryColor.withOpacity(0.2);
    }
  }
}
