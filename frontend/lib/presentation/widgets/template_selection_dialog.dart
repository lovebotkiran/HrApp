import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class TemplateSelectionDialog extends ConsumerStatefulWidget {
  final String templateType; // 'HIRING' or 'WELCOME'
  final String title;
  final List<String> highlights;

  final String? candidateName;

  const TemplateSelectionDialog({
    super.key,
    required this.templateType,
    required this.title,
    this.highlights = const [],
    this.candidateName,
  });

  @override
  ConsumerState<TemplateSelectionDialog> createState() =>
      _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState
    extends ConsumerState<TemplateSelectionDialog> {
  String? _selectedTemplateId;
  String? _previewUrl;
  bool _isGeneratingPreview = false;

  Future<void> _generatePreview(String templateId) async {
    setState(() {
      _isGeneratingPreview = true;
      _selectedTemplateId = templateId;
      _previewUrl = null;
    });

    try {
      final repository = ref.read(brandingRepositoryProvider);
      final previewUrl = await repository.getPreview(templateId, {
        'title': widget.title,
        'highlights': widget.highlights,
        if (widget.candidateName != null)
          'candidate_name': widget.candidateName,
      });

      if (mounted) {
        setState(() {
          _previewUrl = previewUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate preview: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPreview = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync =
        ref.watch(brandingTemplatesProvider(widget.templateType));

    return AlertDialog(
      title: Text(
          'Select Template for ${widget.templateType == "HIRING" ? "Job Post" : "Welcome Post"}'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template List
            const Text('Choose a template:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return const Center(
                        child: Text(
                            'No custom templates found. Default design will be used.'));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final t = templates[index];
                      final isSelected = _selectedTemplateId == t['id'];
                      return GestureDetector(
                        onTap: () => _generatePreview(t['id']),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.05)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image_outlined, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                t['name'],
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 24),

            // Live Preview Section
            const Text('Check Sample (Live Preview):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _isGeneratingPreview
                  ? const Center(child: CircularProgressIndicator())
                  : _previewUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: 'http://localhost:8000$_previewUrl',
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Center(child: Icon(Icons.error)),
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Select a template to see a live sample of your content',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
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
            Navigator.pop(context, _selectedTemplateId);
          },
          child: const Text('Use Selected Template'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, "DEFAULT");
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          child: const Text('Use Default Design'),
        ),
      ],
    );
  }
}
