import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../data/datasources/api_client.dart';
import '../../../core/services/token_storage.dart';

class ShortlistedCandidatesScreen extends StatefulWidget {
  const ShortlistedCandidatesScreen({Key? key}) : super(key: key);

  @override
  State<ShortlistedCandidatesScreen> createState() => _ShortlistedCandidatesScreenState();
}

class _ShortlistedCandidatesScreenState extends State<ShortlistedCandidatesScreen> {
  late final Dio _dio;
  List<dynamic> _candidates = [];
  List<String> _departments = [];
  List<dynamic> _jobPostings = [];
  
  String? _selectedDepartment;
  String? _selectedJobPostingId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _loadDepartments();
    _loadCandidates();
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await _dio.get('/shortlisted-candidates/departments');
      setState(() {
        _departments = List<String>.from(response.data);
      });
    } catch (e) {
      _showError('Failed to load departments: $e');
    }
  }

  Future<void> _loadJobPostings({String? department}) async {
    try {
      String url = '/shortlisted-candidates/job-postings';
      if (department != null) {
        url += '?department=$department';
      }
      final response = await _dio.get(url);
      setState(() {
        _jobPostings = response.data;
      });
    } catch (e) {
      _showError('Failed to load job postings: $e');
    }
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String url = '/shortlisted-candidates/';
      List<String> params = [];
      
      if (_selectedDepartment != null) {
        params.add('department=$_selectedDepartment');
      }
      if (_selectedJobPostingId != null) {
        params.add('job_posting_id=$_selectedJobPostingId');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await _dio.get(url);
      setState(() {
        _candidates = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load candidates: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _createInterview(String applicationId, String candidateName) async {
    // Show dialog to select meeting platform and schedule
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateInterviewDialog(candidateName: candidateName),
    );

    if (result == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _dio.post(
        '/shortlisted-candidates/$applicationId/create-interview',
        data: result,
      );

      setState(() {
        _isLoading = false;
      });

      _showSuccess('Interview scheduled successfully!');
      _loadCandidates(); // Reload to update status
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to create interview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shortlisted Candidates'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedDepartment,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Departments')),
                          ..._departments.map((dept) => DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _selectedJobPostingId = null;
                          });
                          _loadJobPostings(department: value);
                          _loadCandidates();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Job Posting',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedJobPostingId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Positions')),
                          ..._jobPostings.map((jp) => DropdownMenuItem(
                            value: jp['id'],
                            child: Text('${jp['title']} (${jp['job_code']})'),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedJobPostingId = value;
                          });
                          _loadCandidates();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Candidates List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _candidates.isEmpty
                    ? const Center(
                        child: Text(
                          'No shortlisted candidates found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _candidates.length,
                        itemBuilder: (context, index) {
                          final candidate = _candidates[index];
                          return _buildCandidateCard(candidate);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(dynamic candidate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate['candidate_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        candidate['job_title'] ?? 'Unknown Position',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    candidate['status']?.toUpperCase() ?? 'SHORTLISTED',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Applied: ${_formatDate(candidate['applied_at'])}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 24),
                if (candidate['ai_match_score'] != null) ...[
                  Icon(Icons.stars, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'AI Score: ${candidate['ai_match_score']}%',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _createInterview(
                    candidate['id'],
                    candidate['candidate_name'] ?? 'Candidate',
                  ),
                  icon: const Icon(Icons.video_call),
                  label: const Text('Create Interview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
}

class _CreateInterviewDialog extends StatefulWidget {
  final String candidateName;

  const _CreateInterviewDialog({required this.candidateName});

  @override
  State<_CreateInterviewDialog> createState() => _CreateInterviewDialogState();
}

class _CreateInterviewDialogState extends State<_CreateInterviewDialog> {
  late final Dio _dio;
  List<dynamic> _users = [];
  bool _isLoadingUsers = true;
  List<String> _selectedInterviewerIds = [];

  String _selectedPlatform = 'zoom';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 60;
  String _roundName = 'Technical Interview';

  @override
  void initState() {
    super.initState();
    _dio = createDio();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _dio.get('/auth/users');
      setState(() {
        _users = response.data;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      // Silently fail or show error? Better to just show empty list
      debugPrint('Failed to load users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Schedule Interview - ${widget.candidateName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Interviewers', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isLoadingUsers)
              const LinearProgressIndicator()
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final String name = '${user['first_name']} ${user['last_name']}';
                    final String id = user['id'];
                    final bool isSelected = _selectedInterviewerIds.contains(id);

                    return CheckboxListTile(
                      title: Text(name),
                      subtitle: Text(user['designation'] ?? user['department'] ?? ''),
                      value: isSelected,
                      dense: true,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedInterviewerIds.add(id);
                          } else {
                            _selectedInterviewerIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text('Meeting Platform', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
              items: const [
                DropdownMenuItem(value: 'zoom', child: Text('Zoom')),
                DropdownMenuItem(value: 'teams', child: Text('Microsoft Teams')),
                DropdownMenuItem(value: 'both', child: Text('Both')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPlatform = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Interview Round', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _roundName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
              onChanged: (value) {
                _roundName = value;
              },
            ),
            const SizedBox(height: 16),
            const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Duration (minutes)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _duration,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 45, child: Text('45 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
                DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
              ],
              onChanged: (value) {
                setState(() {
                  _duration = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final scheduledDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            Navigator.pop(context, {
              'meeting_platform': _selectedPlatform,
              'scheduled_date': scheduledDateTime.toIso8601String(),
              'duration_minutes': _duration,
              'round_number': 1,
              'round_name': _roundName,
              'interviewer_ids': _selectedInterviewerIds,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text('Schedule Interview'),
        ),
      ],
    );
  }
}
