import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class CreateCandidateScreen extends ConsumerStatefulWidget {
  const CreateCandidateScreen({super.key});

  @override
  ConsumerState<CreateCandidateScreen> createState() => _CreateCandidateScreenState();
}

class _CreateCandidateScreenState extends ConsumerState<CreateCandidateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _resumeUrlController = TextEditingController();
  final _linkedinUrlController = TextEditingController();
  final _portfolioUrlController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _resumeUrlController.dispose();
    _linkedinUrlController.dispose();
    _portfolioUrlController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(candidateRepositoryProvider);
        await repo.createCandidate({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'resume_url': _resumeUrlController.text.isEmpty ? null : _resumeUrlController.text,
          'linkedin_url': _linkedinUrlController.text.isEmpty ? null : _linkedinUrlController.text,
          'portfolio_url': _portfolioUrlController.text.isEmpty ? null : _portfolioUrlController.text,
          'skills': _skillsController.text.isEmpty ? null : _skillsController.text,
          'experience': _experienceController.text.isEmpty ? null : _experienceController.text,
          'education': _educationController.text.isEmpty ? null : _educationController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidate created successfully')),
          );
          Navigator.pop(context);
          ref.refresh(candidatesProvider(null));
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
        title: const Text('New Candidate'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resumeUrlController,
                decoration: const InputDecoration(
                  labelText: 'Resume URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkedinUrlController,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portfolioUrlController,
                decoration: const InputDecoration(
                  labelText: 'Portfolio URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills',
                  border: OutlineInputBorder(),
                  helperText: 'Comma separated',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experience',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Candidate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
