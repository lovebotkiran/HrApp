import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:agentichr_frontend/data/models/candidate.dart';

class CreateCandidateScreen extends ConsumerStatefulWidget {
  final Candidate? candidate;
  const CreateCandidateScreen({super.key, this.candidate});

  @override
  ConsumerState<CreateCandidateScreen> createState() =>
      _CreateCandidateScreenState();
}

class _CreateCandidateScreenState extends ConsumerState<CreateCandidateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinUrlController = TextEditingController();
  final _portfolioUrlController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _educationController = TextEditingController();
  final _currentCompanyController = TextEditingController();
  final _currentDesignationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.candidate != null) {
      _firstNameController.text = widget.candidate!.firstName;
      _lastNameController.text = widget.candidate!.lastName;
      _emailController.text = widget.candidate!.email;
      _phoneController.text = widget.candidate!.phone ?? '';
      _linkedinUrlController.text = widget.candidate!.linkedinUrl ?? '';
      _portfolioUrlController.text = widget.candidate!.portfolioUrl ?? '';
      _skillsController.text = widget.candidate!.skills?.join(', ') ?? '';
      _experienceYearsController.text =
          widget.candidate!.totalExperienceYears?.toString() ?? '';
      _educationController.text = widget.candidate!.highestEducation ?? '';
      _currentCompanyController.text = widget.candidate!.currentCompany ?? '';
      _currentDesignationController.text =
          widget.candidate!.currentDesignation ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinUrlController.dispose();
    _portfolioUrlController.dispose();
    _skillsController.dispose();
    _experienceYearsController.dispose();
    _educationController.dispose();
    _currentCompanyController.dispose();
    _currentDesignationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(candidateRepositoryProvider);

        final skills = _skillsController.text.isNotEmpty
            ? _skillsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : [];

        final data = {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'linkedin_url': _linkedinUrlController.text.isEmpty
              ? null
              : _linkedinUrlController.text,
          'portfolio_url': _portfolioUrlController.text.isEmpty
              ? null
              : _portfolioUrlController.text,
          'skills': skills,
          'total_experience_years': _experienceYearsController.text.isEmpty
              ? null
              : double.tryParse(_experienceYearsController.text),
          'highest_education': _educationController.text.isEmpty
              ? null
              : _educationController.text,
          'current_company': _currentCompanyController.text.isEmpty
              ? null
              : _currentCompanyController.text,
          'current_designation': _currentDesignationController.text.isEmpty
              ? null
              : _currentDesignationController.text,
        };

        if (widget.candidate != null) {
          await repo.updateCandidate(widget.candidate!.id!, data);
        } else {
          await repo.createCandidate(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Candidate ${widget.candidate != null ? 'updated' : 'created'} successfully')),
          );
          Navigator.pop(context);
          ref.invalidate(candidatesProvider(null));
          if (widget.candidate != null) {
            ref.invalidate(candidateDetailProvider(widget.candidate!.id!));
          }
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
        title:
            Text(widget.candidate != null ? 'Edit Candidate' : 'New Candidate'),
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
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
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
                      validator: (value) =>
                          value?.isEmpty == true ? 'Required' : null,
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentCompanyController,
                      decoration: const InputDecoration(
                        labelText: 'Current Company',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _currentDesignationController,
                      decoration: const InputDecoration(
                        labelText: 'Current Designation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _experienceYearsController,
                      decoration: const InputDecoration(
                        labelText: 'Experience (Years)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Highest Education',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
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
                    : Text(widget.candidate != null
                        ? 'Update Candidate'
                        : 'Create Candidate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
