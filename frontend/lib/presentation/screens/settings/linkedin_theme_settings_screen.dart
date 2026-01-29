import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';

class LinkedInThemeSettingsScreen extends ConsumerStatefulWidget {
  const LinkedInThemeSettingsScreen({super.key});

  @override
  ConsumerState<LinkedInThemeSettingsScreen> createState() =>
      _LinkedInThemeSettingsScreenState();
}

class _LinkedInThemeSettingsScreenState
    extends ConsumerState<LinkedInThemeSettingsScreen> {
  Color primaryColor = const Color(0xFF0F172A);
  Color accentColor = const Color(0xFFFF6B00);
  String? logoUrl;
  String? backgroundUrl;
  final TextEditingController _companyNameController =
      TextEditingController(text: 'AGENTIC HR');
  bool isLoading = true;
  bool isUploading = false;

  final String serverBase = 'http://localhost:8000';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final repo = ref.read(brandingRepositoryProvider);
      final theme = await repo.getLinkedInTheme();

      setState(() {
        primaryColor = _parseColor(theme['primary_color'] ?? '#0F172A');
        accentColor = _parseColor(theme['accent_color'] ?? '#FF6B00');
        logoUrl = theme['logo_url'];
        backgroundUrl = theme['background_url'];
        _companyNameController.text = theme['company_name'] ?? 'AGENTIC HR';
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading theme: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<void> _pickAndUploadAsset(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final multipartFile =
          MultipartFile.fromBytes(bytes, filename: image.name);

      final repo = ref.read(brandingRepositoryProvider);
      final url = await repo.uploadAsset(type, multipartFile);

      setState(() {
        if (type == 'logo') {
          logoUrl = url;
        } else {
          backgroundUrl = url;
        }
        isUploading = false;
      });
    } catch (e) {
      setState(() => isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _saveTheme() async {
    setState(() => isLoading = true);
    try {
      final repo = ref.read(brandingRepositoryProvider);
      await repo.updateLinkedInTheme({
        'primary_color':
            '#${primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'accent_color':
            '#${accentColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'logo_url': logoUrl,
        'background_url': backgroundUrl,
        'company_name': _companyNameController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('LinkedIn branding saved successfully'),
              backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving theme: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn Branding'),
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTheme,
              tooltip: 'Save All Changes',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Identity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Company Name Input
                  const Text('Company Name',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _companyNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your company name',
                      prefixIcon: const Icon(Icons.business_center),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() {}), // Trigger preview update
                  ),
                  const SizedBox(height: 24),

                  // Image Assets Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildAssetPicker(
                          label: 'Company Logo',
                          icon: Icons.business,
                          imageUrl: logoUrl,
                          onTap: () => _pickAndUploadAsset('logo'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildAssetPicker(
                          label: 'Post Background',
                          icon: Icons.image_outlined,
                          imageUrl: backgroundUrl,
                          onTap: () => _pickAndUploadAsset('background'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text('Brand Colors',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _buildColorSection(
                    title: 'Primary Color',
                    subtitle: 'Used for banners and main headings',
                    color: primaryColor,
                    onChanged: (c) => setState(() => primaryColor = c),
                  ),
                  const SizedBox(height: 20),
                  _buildColorSection(
                    title: 'Accent Color',
                    subtitle: 'Used for highlights and action buttons',
                    color: accentColor,
                    onChanged: (c) => setState(() => accentColor = c),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      const Text('Design Preview',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (isUploading)
                        const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(child: _buildLivePreview()),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildAssetPicker({
    required String label,
    required IconData icon,
    String? imageUrl,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '$serverBase$imageUrl',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Icon(Icons.error, color: Colors.red)),
                    ),
                  )
                : Center(
                    child: Icon(icon, color: Colors.grey.shade400, size: 30)),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection({
    required String title,
    required String subtitle,
    required Color color,
    required ValueChanged<Color> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        InkWell(
          onTap: () => _pickColor(color, onChanged),
          child: Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Text(
                '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  color: _getTextColor(color),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _pickColor(Color initialColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Brand Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: onColorChanged,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    // 1:1 Aspect Ratio Preview
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background Image
            if (backgroundUrl != null && backgroundUrl!.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3, // Slightly higher for better visibility
                  child: Image.network('$serverBase$backgroundUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const SizedBox.shrink()),
                ),
              ),

            Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(width: 3, height: 40, color: accentColor),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WE ARE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor)),
                          Text('HIRING!',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor)),
                        ],
                      ),
                      const Spacer(),
                      // Logo & Name Centered
                      SizedBox(
                        width: 100, // Fixed width for centering alignment
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (logoUrl != null && logoUrl!.isNotEmpty)
                              Image.network('$serverBase$logoUrl',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.business,
                                      color: Colors.grey))
                            else
                              const Icon(Icons.business,
                                  color: Colors.grey, size: 30),
                            const SizedBox(height: 4),
                            Text(
                              _companyNameController.text.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: primaryColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Job Title Banner
                Container(
                  color: primaryColor,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'SOFTWARE ENGINEER',
                      style: TextStyle(
                          color: _getTextColor(primaryColor),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                          3,
                          (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 10, color: accentColor),
                                    const SizedBox(width: 6),
                                    Container(
                                        height: 6,
                                        width: 120,
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                  ],
                                ),
                              )),
                    ),
                  ),
                ),

                // Footer
                Container(
                  height: 45,
                  color: accentColor,
                  child: Center(
                    child: Text(
                      'APPLY NOW',
                      style: TextStyle(
                          color: _getTextColor(accentColor),
                          fontWeight: FontWeight.w900,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }
}
