import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:intl/intl.dart';

class CreateInterviewScreen extends ConsumerStatefulWidget {
  const CreateInterviewScreen({super.key});

  @override
  ConsumerState<CreateInterviewScreen> createState() =>
      _CreateInterviewScreenState();
}

class _CreateInterviewScreenState extends ConsumerState<CreateInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applicationIdController = TextEditingController();
  final _interviewerIdController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _meetingLinkController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _interviewType = 'Technical';
  bool _isLoading = false;

  final List<String> _interviewTypes = [
    'Technical',
    'HR',
    'Managerial',
    'Behavioral'
  ];

  @override
  void dispose() {
    _applicationIdController.dispose();
    _interviewerIdController.dispose();
    _durationController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final scheduledTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        final repo = ref.read(interviewRepositoryProvider);
        await repo.scheduleInterview({
          'application_id': int.parse(_applicationIdController.text),
          'interviewer_id': int.parse(_interviewerIdController.text),
          'scheduled_time': scheduledTime.toIso8601String(),
          'duration': int.parse(_durationController.text),
          'interview_type': _interviewType,
          'meeting_link': _meetingLinkController.text.isEmpty
              ? null
              : _meetingLinkController.text,
          'status': 'Scheduled',
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interview scheduled successfully')),
          );
          Navigator.pop(context);
          ref.invalidate(interviewsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Interview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _applicationIdController,
                decoration: const InputDecoration(
                  labelText: 'Application ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interviewerIdController,
                decoration: const InputDecoration(
                  labelText: 'Interviewer ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _interviewType,
                decoration: const InputDecoration(
                  labelText: 'Interview Type',
                  border: OutlineInputBorder(),
                ),
                items: _interviewTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _interviewType = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Schedule Interview'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
