import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class RankedCandidatesScreen extends ConsumerStatefulWidget {
  final String jobPostingId;
  final String jobTitle;

  const RankedCandidatesScreen({
    super.key,
    required this.jobPostingId,
    required this.jobTitle,
  });

  @override
  ConsumerState<RankedCandidatesScreen> createState() => _RankedCandidatesScreenState();
}

class _RankedCandidatesScreenState extends ConsumerState<RankedCandidatesScreen> {
  bool _isRanking = false;
  List<Map<String, dynamic>> _rankedApplications = [];
  bool _hasRanked = false;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/applications',
        queryParameters: {'job_posting_id': widget.jobPostingId},
      );

      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          _rankedApplications = List<Map<String, dynamic>>.from(response.data);
          // Sort by AI match score descending
          _rankedApplications.sort((a, b) {
            final scoreA = _parseScore(a['ai_match_score']);
            final scoreB = _parseScore(b['ai_match_score']);
            return scoreB.compareTo(scoreA);
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _rankCandidates() async {
    setState(() => _isRanking = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/applications/rank-by-job-posting/${widget.jobPostingId}',
      );

      if (response.statusCode == 200) {
        setState(() => _hasRanked = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Candidates ranked successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }

        // Reload applications to get updated scores
        await _loadApplications();
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Error ranking candidates';
        if (e.response?.data != null && e.response!.data['detail'] != null) {
          errorMessage = e.response!.data['detail'];
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRanking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ranked Candidates'),
            Text(
              widget.jobTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        actions: [
          if (!_isRanking)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadApplications,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          // Rank All Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI-Powered Candidate Ranking',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan resumes and rank candidates based on job requirements using AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isRanking ? null : _rankCandidates,
                  icon: _isRanking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isRanking ? 'Ranking...' : 'Rank All Candidates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Candidates List
          Expanded(
            child: _rankedApplications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No applications found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applications will appear here',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rankedApplications.length,
                    itemBuilder: (context, index) {
                      final app = _rankedApplications[index];
                      final score = _parseScore(app['ai_match_score']);
                      final matchScore = score;
                      final reasoning = app['ai_match_reasoning'] as String?;
                      final candidateId = app['candidate_id'] as String?;
                      final status = app['status'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: matchScore > 75 ? 4 : 1,
                        child: ExpansionTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: _getScoreColor(matchScore.toDouble()),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (matchScore > 75)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.star, size: 12, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            app['candidate_name'] ?? 'Candidate #$candidateId',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: matchScore > 75 ? FontWeight.bold : FontWeight.normal,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.analytics, size: 16, color: _getScoreColor(matchScore.toDouble())),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Match Score: ${matchScore.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: _getScoreColor(matchScore.toDouble()),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Status: ${status ?? "Unknown"}'),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            if (reasoning != null)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Analysis:',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      reasoning,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/candidates/detail',
                                              arguments: candidateId,
                                            );
                                          },
                                          icon: const Icon(Icons.person),
                                          label: const Text('View Profile'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            // TODO: Shortlist candidate
                                          },
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('Shortlist'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.successColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return AppTheme.successColor;
    if (score >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  double _parseScore(dynamic score) {
    if (score == null) return 0.0;
    if (score is num) return score.toDouble();
    if (score is String) return double.tryParse(score) ?? 0.0;
    return 0.0;
  }
}
