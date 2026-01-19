import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class OnboardingListScreen extends ConsumerWidget {
  const OnboardingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch offers with 'Accepted' status which implies they are in onboarding
    final onboardingOffersAsync = ref.watch(offersProvider('Accepted'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: onboardingOffersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No candidates in onboarding',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Candidates who accept offers will appear here',
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
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              // We can fetch detailed status for each item if needed, 
              // but for list view we might just show basic info or fetch status asynchronously
              return _OnboardingCard(
                offerId: offer.id!,
                applicationId: offer.applicationId,
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
                'Error loading onboarding list',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(offersProvider('Accepted')),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends ConsumerWidget {
  final int offerId;
  final int applicationId;

  const _OnboardingCard({
    required this.offerId,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(onboardingStatusProvider(offerId));
    final applicationAsync = ref.watch(applicationDetailProvider(applicationId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statusAsync.when(
          data: (status) {
            final progress = (status['progress'] as num?)?.toDouble() ?? 0.0;
            final pendingTasks = (status['pending_tasks'] as num?)?.toInt() ?? 0;
            final statusText = status['status'] as String? ?? 'In Progress';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                applicationAsync.when(
                  data: (application) {
                    final candidateName = application['candidate_name'] as String? ?? 'Unknown Candidate';
                    final position = application['job_title'] as String? ?? 'Unknown Position';
                    
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            candidateName.isNotEmpty ? candidateName[0] : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidateName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                position,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(statusText),
                          backgroundColor: AppTheme.warningColor.withOpacity(0.2),
                        ),
                      ],
                    );
                  },
                  loading: () => const Row(
                    children: [
                      CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loading...'),
                          Text('...'),
                        ],
                      ),
                    ],
                  ),
                  error: (_, __) => const Text('Failed to load candidate info'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          '$pendingTasks',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        Text(
                          'Pending',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: LinearProgressIndicator()),
          error: (_, __) => const Text('Failed to load status'),
        ),
      ),
    );
  }
}
