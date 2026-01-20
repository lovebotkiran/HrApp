import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? jobPosting;
  final String? jobPostingId;

  const ApplicationFormScreen({
    super.key,
    this.jobPosting,
    this.jobPostingId,
  }) : assert(jobPosting != null || jobPostingId != null,
            'Either jobPosting or jobPostingId must be provided');

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _jobPosting;
  bool _isLoading = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();

  PlatformFile? _resumeFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.jobPosting != null) {
      _jobPosting = widget.jobPosting;
    } else if (widget.jobPostingId != null) {
      _fetchJobPosting();
    }
  }

  Future<void> _fetchJobPosting() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(jobPostingRepositoryProvider);
      final posting = await repo.getJobPosting(widget.jobPostingId!);
      if (mounted) {
        setState(() {
          _jobPosting = posting;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job details: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = result.files.single;
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jobPosting == null) return;

    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a resume')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final applicationRepo = ref.read(applicationRepositoryProvider);
      final candidateRepo = ref.read(candidateRepositoryProvider);

      final candidateData = {
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      };

      final applicationData = {
        "job_posting_id": _jobPosting!['id'],
        "candidate_data": candidateData,
        "source": "Career Page",
        "cover_letter": _coverLetterController.text.trim()
      };

      final response = await applicationRepo.submitApplication(applicationData);
      final candidateId = response['candidate_id'] as String;

      // Upload Resume if selected
      if (_resumeFile != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _resumeFile!.bytes!,
            filename: _resumeFile!.name,
          ),
        });
        await candidateRepo.uploadResume(candidateId, formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = 'Error submitting application';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail')) {
          errorMessage = data['detail'];
        } else if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_jobPosting == null) {
      return const Scaffold(
        body: Center(child: Text('Job details not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for ${_jobPosting!['title']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name *'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration:
                          const InputDecoration(labelText: 'Last Name *'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              Text(
                'Resume / CV',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (_resumeFile != null) ...[
                      Icon(Icons.description,
                          size: 48, color: AppTheme.primaryColor),
                      const SizedBox(height: 8),
                      Text(_resumeFile!.name),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _pickResume,
                        child: const Text('Change Resume'),
                      )
                    ] else ...[
                      const Icon(Icons.cloud_upload_outlined,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Upload your resume (PDF, DOC, DOCX)'),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _pickResume,
                        child: const Text('Select File'),
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Cover Letter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coverLetterController,
                decoration: const InputDecoration(
                  labelText: 'Why are you a good fit for this role?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
