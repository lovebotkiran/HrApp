import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class ApplicationFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> jobPosting;

  const ApplicationFormScreen({super.key, required this.jobPosting});

  @override
  ConsumerState<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();
  
  File? _resumeFile;
  bool _isSubmitting = false;

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
        _resumeFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resumeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a resume')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final candidateRepo = ref.read(candidateRepositoryProvider);
      final applicationRepo = ref.read(applicationRepositoryProvider);

      // 1. Create Candidate (or check existing - API handles check)
      final candidateData = {
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        // Default values for required fields
        "status": "active",
        "source": "Career Page"
      };
      
      final candidate = await candidateRepo.createCandidate(candidateData);

      // 2. Upload Resume
      await candidateRepo.uploadResume(candidate.id.toString(), _resumeFile!);

      // 3. Trigger Resume Parsing (Background or Explicit)
      try {
          await candidateRepo.parseResume(candidate.id.toString());
      } catch (e) {
          // Ignore parsing errors, it shouldn't block application
          print("Resume parsing failed: $e");
      }

      // 4. Submit Application
      final applicationData = {
        "job_posting_id": widget.jobPosting['id'],
        "candidate_data": candidateData, // Schema might need this or just ID
        "source": "Career Page",
        "cover_letter": _coverLetterController.text
      };
      
      // Since my backend schema for ApplicationCreate expects 'candidate_data', 
      // I am passing it. But ideally we should just pass candidate_id if it exists.
      // Retrying logic: app router submit_application handles 'create or get candidate'.
      
      await applicationRepo.submitApplication(applicationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        Navigator.pop(context); // Go back to detail or list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for ${widget.jobPosting['title']}'),
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
                      decoration: const InputDecoration(labelText: 'First Name *'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name *'),
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
                        Icon(Icons.description, size: 48, color: AppTheme.primaryColor),
                        const SizedBox(height: 8),
                        Text(_resumeFile!.path.split(Platform.pathSeparator).last),
                        const SizedBox(height: 8),
                        TextButton(
                            onPressed: _pickResume,
                            child: const Text('Change Resume'),
                        )
                    ] else ...[
                        const Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey),
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
                     ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
