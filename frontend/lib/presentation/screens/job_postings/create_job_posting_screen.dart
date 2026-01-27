import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class CreateJobPostingScreen extends ConsumerStatefulWidget {
  const CreateJobPostingScreen({super.key});

  @override
  ConsumerState<CreateJobPostingScreen> createState() =>
      _CreateJobPostingScreenState();
}

class _CreateJobPostingScreenState
    extends ConsumerState<CreateJobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();

  String? _selectedEmploymentType;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(jobPostingRepositoryProvider);
        final data = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'requirements': _requirementsController.text,
          'location': _locationController.text,
          'employment_type': _selectedEmploymentType,
          'salary_min': _salaryMinController.text.isNotEmpty
              ? double.parse(_salaryMinController.text)
              : null,
          'salary_max': _salaryMaxController.text.isNotEmpty
              ? double.parse(_salaryMaxController.text)
              : null,
          'is_active': true,
        };

        await repo.createJobPosting(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job Posting created successfully')),
          );
          Navigator.pop(context);
          ref.invalidate(jobPostingsProvider(null));
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
        title: const Text('New Job Posting'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedEmploymentType,
                decoration: const InputDecoration(
                  labelText: 'Employment Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Full-time', child: Text('Full-time')),
                  DropdownMenuItem(
                      value: 'Part-time', child: Text('Part-time')),
                  DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                  DropdownMenuItem(
                      value: 'Internship', child: Text('Internship')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedEmploymentType = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select type'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter location'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMinController,
                      decoration: const InputDecoration(
                        labelText: 'Min Salary',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Max Salary',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter description'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Requirements',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Posting'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
