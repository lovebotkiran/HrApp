import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:agentichr_frontend/data/models/application.dart';

class AIRankingsScreen extends ConsumerStatefulWidget {
  const AIRankingsScreen({super.key});

  @override
  ConsumerState<AIRankingsScreen> createState() => _AIRankingsScreenState();
}

class _AIRankingsScreenState extends ConsumerState<AIRankingsScreen> {
  bool _isBulkRanking = false;
  String? _selectedDepartment;
  String? _selectedJobTitle;

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
        ref.invalidate(applicationsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkRanking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch departments for tabs
    final departmentsAsync = ref.watch(departmentsProvider);
    final departments = departmentsAsync.value ?? [];
    if (_selectedDepartment == null && departments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedDepartment = departments.first;
        });
      });
    }

    // Fetch applications filtered by department
    final applicationsAsync = ref.watch(applicationsProvider(
        ApplicationFilter(department: _selectedDepartment)));

    return DefaultTabController(
      length: departments.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Candidate Rankings'),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) {
              setState(() {
                _selectedDepartment = departments[index];
                _selectedJobTitle = null;
              });
            },
            tabs: departments.map((d) => Tab(text: d)).toList(),
          ),
          actions: [
            _isBulkRanking
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))))
                : TextButton.icon(
                    onPressed: _runBulkRank,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Bulk Rank All'),
                  ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(applicationsProvider);
              },
            ),
          ],
        ),
        body: applicationsAsync.when(
          data: (applications) {
            // Filter applications that have a match score and are not yet advanced
            final advancedStatuses = [
              'shortlisted',
              'interview',
              'selected',
              'offered',
              'rejected'
            ];
            final rankedApps = applications.where((app) {
              final hasScore = app['ai_match_score'] != null;
              final status = (app['status'] as String? ?? '').toLowerCase();
              return hasScore && !advancedStatuses.contains(status);
            }).toList();

            if (rankedApps.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined,
                        size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No AI rankings available yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Rankings will appear once candidates are processed by AI.'),
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

            if (_selectedJobTitle == null ||
                !jobTitles.contains(_selectedJobTitle)) {
              _selectedJobTitle = jobTitles.isNotEmpty ? jobTitles.first : null;
            }

            final currentJobTitle = _selectedJobTitle;
            final apps = currentJobTitle != null
                ? (groupedApps[currentJobTitle]!
                  ..sort((a, b) => _parseScore(b['ai_match_score'])
                      .compareTo(_parseScore(a['ai_match_score']))))
                : <Map<String, dynamic>>[];

            return Column(
              children: [
                if (jobTitles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedJobTitle,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppTheme.primaryColor),
                          style: Theme.of(context).textTheme.bodyLarge,
                          items: jobTitles.map((title) {
                            return DropdownMenuItem(
                              value: title,
                              child: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedJobTitle = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: currentJobTitle == null
                      ? const Center(child: Text('Please select a position'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rankings for $currentJobTitle',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    '${apps.length} Candidates',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: AppTheme.textSecondary),
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
                                    headingRowColor: WidgetStateProperty.all(
                                        AppTheme.primaryColor
                                            .withOpacity(0.05)),
                                    columns: const [
                                      DataColumn(
                                          label: Text('Candidate',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Status',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('AI Score',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Actions',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    rows: apps.map((app) {
                                      final score =
                                          _parseScore(app['ai_match_score']);
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: AppTheme
                                                      .primaryColor
                                                      .withOpacity(0.1),
                                                  child: Text(
                                                    (app['candidate_name']
                                                            as String? ??
                                                        'U')[0],
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: AppTheme
                                                            .primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(app['candidate_name'] ??
                                                    'Unknown'),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Chip(
                                              label: Text(
                                                app['status'] ?? 'Applied',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              backgroundColor:
                                                  _getStatusColor(app['status'])
                                                      .withOpacity(0.1),
                                              side: BorderSide.none,
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getScoreColor(score)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                                  icon: const Icon(
                                                      Icons.person_outline,
                                                      size: 20),
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/candidates/detail',
                                                      arguments:
                                                          app['candidate_id'],
                                                    );
                                                  },
                                                  tooltip: 'View Profile',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.info_outline,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _showReasoning(
                                                          context, app),
                                                  tooltip: 'AI Reasoning',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .thumb_up_alt_outlined,
                                                      size: 20,
                                                      color: AppTheme
                                                          .successColor),
                                                  onPressed: () =>
                                                      _shortlistCandidate(
                                                          context, app),
                                                  tooltip:
                                                      'Shortlist Candidate',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                      app['status'] ==
                                                              'rejected'
                                                          ? Icons.block
                                                          : Icons
                                                              .thumb_down_off_alt,
                                                      size: 20,
                                                      color: app['status'] ==
                                                              'rejected'
                                                          ? Colors.grey
                                                          : AppTheme
                                                              .errorColor),
                                                  onPressed: app['status'] ==
                                                          'rejected'
                                                      ? null
                                                      : () => _rejectCandidate(
                                                          context, app),
                                                  tooltip:
                                                      'Reject & Manage Pool',
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
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  double _parseScore(dynamic score) {
    if (score == null) return 0.0;
    if (score is num) return score.toDouble();
    if (score is String) return double.tryParse(score) ?? 0.0;
    return 0.0;
  }

  Future<void> _shortlistCandidate(
      BuildContext context, Map<String, dynamic> app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shortlist Candidate'),
        content: Text(
            'Move ${app['candidate_name']} to the shortlisted stage for this position?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Shortlist'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(applicationRepositoryProvider);
        await repo.shortlistApplication(app['id'] as String);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidate shortlisted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          ref.invalidate(applicationsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectCandidate(
      BuildContext context, Map<String, dynamic> app) async {
    bool removeFromPool = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Reject Candidate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Are you sure you want to reject ${app['candidate_name']} for this position?'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Remove from local candidate pool?'),
                subtitle: const Text(
                    'This candidate will not be suggested for future job postings.'),
                value: removeFromPool,
                onChanged: (value) {
                  setDialogState(() {
                    removeFromPool = value ?? false;
                  });
                },
                activeColor: AppTheme.errorColor,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white),
              child: const Text('Confirm Rejection'),
            ),
          ],
        );
      }),
    );

    if (result == true) {
      try {
        final repo = ref.read(applicationRepositoryProvider);
        await repo.rejectApplication(
          app['id'] as String,
          reason: 'Rejected from AI Rankings screen',
          removeFromPool: removeFromPool,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(removeFromPool
                  ? 'Candidate rejected and removed from pool'
                  : 'Candidate rejected'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          ref.invalidate(applicationsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
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
              Text('Job: ${app['job_title']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(app['ai_match_reasoning'] ??
                  'No detailed reasoning provided.'),
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
