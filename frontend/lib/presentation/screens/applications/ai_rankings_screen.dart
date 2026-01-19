import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class AIRankingsScreen extends ConsumerStatefulWidget {
  const AIRankingsScreen({super.key});

  @override
  ConsumerState<AIRankingsScreen> createState() => _AIRankingsScreenState();
}

class _AIRankingsScreenState extends ConsumerState<AIRankingsScreen> {
  bool _isBulkRanking = false;

  Future<void> _runBulkRank() async {
    setState(() => _isBulkRanking = true);
    try {
      final repo = ref.read(applicationRepositoryProvider);
      final result = await repo.rankAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ranking completed'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        ref.refresh(applicationsProvider(null));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkRanking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch all applications
    final applicationsAsync = ref.watch(applicationsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Candidate Rankings'),
        actions: [
          _isBulkRanking 
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton.icon(
                onPressed: _runBulkRank,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Bulk Rank All'),
              ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(applicationsProvider(null)),
          ),
        ],
      ),
      body: applicationsAsync.when(
        data: (applications) {
          // Filter applications that have a match score
          final rankedApps = applications
              .where((app) => app['ai_match_score'] != null)
              .toList();

          if (rankedApps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No AI rankings available yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Rankings will appear once candidates are processed by AI.'),
                ],
              ),
            );
          }

          // Group by job title
          final Map<String, List<Map<String, dynamic>>> groupedApps = {};
          for (var app in rankedApps) {
            final jobTitle = app['job_title'] ?? 'Unknown Position';
            if (!groupedApps.containsKey(jobTitle)) {
              groupedApps[jobTitle] = [];
            }
            groupedApps[jobTitle]!.add(app);
          }

          final jobTitles = groupedApps.keys.toList()..sort();

          return DefaultTabController(
            length: jobTitles.length,
            child: Column(
              children: [
                Material(
                  color: Theme.of(context).cardColor,
                  elevation: 1,
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondary,
                    tabs: jobTitles.map((title) => Tab(text: title)).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: jobTitles.map((jobTitle) {
                      final apps = groupedApps[jobTitle]!
                        ..sort((a, b) => _parseScore(b['ai_match_score']).compareTo(_parseScore(a['ai_match_score'])));
                      
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rankings for $jobTitle',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${apps.length} Candidates',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 24,
                                  headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.05)),
                                  columns: const [
                                    DataColumn(label: Text('Candidate', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('AI Score', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: apps.map((app) {
                                    final score = _parseScore(app['ai_match_score']);
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                                child: Text(
                                                  (app['candidate_name'] as String? ?? 'U')[0],
                                                  style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(app['candidate_name'] ?? 'Unknown'),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Chip(
                                            label: Text(
                                              app['status'] ?? 'Applied',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor: _getStatusColor(app['status']).withOpacity(0.1),
                                            side: BorderSide.none,
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getScoreColor(score).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${score.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                color: _getScoreColor(score),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.person_outline, size: 20),
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/candidates/detail',
                                                    arguments: app['candidate_id'],
                                                  );
                                                },
                                                tooltip: 'View Profile',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.info_outline, size: 20),
                                                onPressed: () => _showReasoning(context, app),
                                                tooltip: 'AI Reasoning',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  double _parseScore(dynamic score) {
    if (score == null) return 0.0;
    if (score is num) return score.toDouble();
    if (score is String) return double.tryParse(score) ?? 0.0;
    return 0.0;
  }

  void _showReasoning(BuildContext context, Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Match Reasoning: ${app['candidate_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Job: ${app['job_title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(app['ai_match_reasoning'] ?? 'No detailed reasoning provided.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'shortlisted':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      case 'interview':
        return AppTheme.infoColor;
      default:
        return AppTheme.warningColor;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
