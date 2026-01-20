import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

import 'package:agentichr_frontend/data/models/job_requisition.dart';

class CreateJobRequisitionScreen extends ConsumerStatefulWidget {
  final JobRequisition? requisition;

  const CreateJobRequisitionScreen({super.key, this.requisition});

  @override
  ConsumerState<CreateJobRequisitionScreen> createState() =>
      _CreateJobRequisitionScreenState();
}

class _CreateJobRequisitionScreenState
    extends ConsumerState<CreateJobRequisitionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _selectedDepartment;
  String? _selectedEmploymentType;
  int? _selectedExperience;
  List<String> _selectedSkills = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  final List<String> _departmentOptions = [
    'Technology',
    'Sales',
    'Marketing',
    'HR',
    'Finance',
    'Operations',
  ];

  // Department-to-skills mapping
  final Map<String, List<String>> _departmentSkills = {
    'Technology': [
      'Python',
      'Java',
      'JavaScript',
      'MySQL',
      'MongoDB',
      'React',
      'Node.js',
      'AWS',
      'Docker',
      'Kubernetes'
    ],
    'Sales': [
      'Lead Generation',
      'Prospecting',
      'Cold Calling',
      'Negotiation',
      'CRM',
      'Sales Strategy',
      'Account Management'
    ],
    'Marketing': [
      'SEO',
      'Content Marketing',
      'Social Media',
      'Email Marketing',
      'Google Analytics',
      'PPC',
      'Brand Management'
    ],
    'HR': [
      'Recruitment',
      'Onboarding',
      'Performance Management',
      'Employee Relations',
      'HRIS',
      'Compliance'
    ],
    'Finance': [
      'Accounting',
      'Financial Analysis',
      'Budgeting',
      'Tax Planning',
      'QuickBooks',
      'Excel',
      'Financial Reporting'
    ],
    'Operations': [
      'Process Improvement',
      'Supply Chain',
      'Logistics',
      'Quality Control',
      'Project Management',
      'Lean Six Sigma'
    ],
  };

  List<String> get _availableSkills {
    if (_selectedDepartment == null) return [];
    return _departmentSkills[_selectedDepartment] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.requisition?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.requisition?.jobDescription ?? '');

    _selectedDepartment = widget.requisition?.department;
    if (_selectedDepartment != null &&
        !_departmentOptions.contains(_selectedDepartment)) {
      _departmentOptions.add(_selectedDepartment!);
    }

    _selectedEmploymentType = widget.requisition?.employmentType;

    _selectedExperience = widget.requisition?.experienceMin;
    if (_selectedExperience != null &&
        (_selectedExperience! < 0 || _selectedExperience! > 25)) {
      if (_selectedExperience! > 25) {
        _selectedExperience = null;
      }
    }

    _selectedSkills = widget.requisition?.requiredSkills ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateJobDescription() async {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select skills first')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final dio = ref.read(dioProvider);

      final response = await dio.post(
        '/ai/generate-job-description',
        data: {
          'title': _titleController.text.isNotEmpty
              ? _titleController.text
              : 'Position',
          'department': _selectedDepartment ?? 'Department',
          'skills': _selectedSkills,
          'experience': _selectedExperience ?? 0,
          'employment_type': _selectedEmploymentType ?? 'Full-time',
        },
      );

      if (response.statusCode == 200) {
        final description = response.data['description'] ?? '';
        if (description.isNotEmpty) {
          setState(() {
            _descriptionController.text = description;
          });
        } else {
          throw Exception('No description generated');
        }
      } else {
        throw Exception('Failed to generate: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Error generating description';
        if (e.response?.statusCode == 503) {
          errorMessage =
              'AI model is loading. Please try again in a few seconds.';
        } else if (e.response?.data != null &&
            e.response!.data['detail'] != null) {
          errorMessage = e.response!.data['detail'];
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Connection error. Please check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _submit(String status) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(jobRequisitionRepositoryProvider);
        final data = {
          'title': _titleController.text,
          'department': _selectedDepartment,
          'employment_type': _selectedEmploymentType,
          'experience_min': _selectedExperience,
          'required_skills': _selectedSkills,
          'job_description': _descriptionController.text,
          'status': status,
        };

        if (widget.requisition != null) {
          await repo.updateRequisition(widget.requisition!.id!, data);
        } else {
          await repo.createRequisition(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Job Requisition ${widget.requisition != null ? 'updated' : 'created'} successfully')),
          );
          Navigator.pop(context);
          ref.refresh(jobRequisitionsProvider(JobRequisitionFilter()));
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

  void _showSkillsDialog() async {
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department first')),
      );
      return;
    }

    final List<String> tempSelected = List.from(_selectedSkills);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Skills'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _availableSkills.map((skill) {
                return CheckboxListTile(
                  title: Text(skill),
                  value: tempSelected.contains(skill),
                  onChanged: (bool? checked) {
                    setDialogState(() {
                      if (checked == true) {
                        tempSelected.add(skill);
                      } else {
                        tempSelected.remove(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSkills = tempSelected;
                });
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.requisition != null
            ? 'Edit Job Requisition'
            : 'New Job Requisition'),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: _departmentOptions
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                    // Clear skills when department changes
                    _selectedSkills = [];
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a department';
                  }
                  return null;
                },
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
                onChanged: (value) {
                  setState(() {
                    _selectedEmploymentType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an employment type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedExperience,
                decoration: const InputDecoration(
                  labelText: 'Experience (yrs)',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                    26,
                    (index) => DropdownMenuItem(
                          value: index,
                          child: Text(index.toString()),
                        )),
                onChanged: (value) {
                  setState(() {
                    _selectedExperience = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Skills multiselect
              InkWell(
                onTap: _showSkillsDialog,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Required Skills',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: _selectedSkills.isEmpty
                      ? const Text('Select skills',
                          style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _selectedSkills
                              .map((skill) => Chip(
                                    label: Text(skill,
                                        style: const TextStyle(fontSize: 12)),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedSkills.remove(skill);
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Write with AI button
              OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateJobDescription,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Generating...' : 'Write with AI'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _submit('draft'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(widget.requisition != null
                            ? 'Update Draft'
                            : 'Save as Draft'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _submit('pending_approval'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit for Approval'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
