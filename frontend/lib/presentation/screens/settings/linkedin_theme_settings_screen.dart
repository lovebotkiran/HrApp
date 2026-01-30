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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save Changes'),
                onPressed: _saveTheme,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Professional Branding',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              )),
                      const SizedBox(height: 8),
                      Text(
                        'Configure how your job postings appear on LinkedIn. Consistent brand identity increases candidate engagement.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // SECTION 1: Identity
                  _buildSectionCard(
                    title: 'Company Identity',
                    icon: Icons.business_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Business Name',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                )),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Acme Corporation',
                            prefixIcon: Icon(Icons.business_center_outlined),
                          ),
                          onChanged: (v) => setState(() {}),
                        ),
                        const SizedBox(height: 32),
                        Text('Brand Assets',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                )),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAssetPicker(
                              label: 'Logo',
                              icon: Icons.add_photo_alternate_outlined,
                              imageUrl: logoUrl,
                              onPick: () => _pickAndUploadAsset('logo'),
                              onRemove: () => setState(() => logoUrl = ""),
                            ),
                            _buildAssetPicker(
                              label: 'Background',
                              icon: Icons.wallpaper_outlined,
                              imageUrl: backgroundUrl,
                              onPick: () => _pickAndUploadAsset('background'),
                              onRemove: () =>
                                  setState(() => backgroundUrl = ""),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECTION 2: Design System
                  _buildSectionCard(
                    title: 'Visual Style',
                    icon: Icons.color_lens_outlined,
                    child: Column(
                      children: [
                        _buildColorSection(
                          title: 'Primary Brand Color',
                          subtitle: 'Used for main banners and headings',
                          color: primaryColor,
                          onChanged: (c) => setState(() => primaryColor = c),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(),
                        ),
                        _buildColorSection(
                          title: 'Accent Highlight',
                          subtitle: 'Used for buttons and highlight text',
                          color: accentColor,
                          onChanged: (c) => setState(() => accentColor = c),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECTION 3: Preview
                  _buildSectionCard(
                    title: 'Live Post Preview',
                    icon: Icons.remove_red_eye_outlined,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'This is exactly how your LinkedIn post will look',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 24),
                          _buildLivePreview(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetPicker({
    required String label,
    required IconData icon,
    String? imageUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            if (hasImage) {
              _showAssetActionSheet(label, onPick, onRemove);
            } else {
              onPick();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : AppTheme.borderColor,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      '$serverBase$imageUrl',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red),
                    ),
                  )
                else
                  Icon(icon, color: Colors.grey.shade400, size: 32),
                if (hasImage)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: const Text(
                        'Manage Asset',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAssetActionSheet(
      String label, VoidCallback onPick, VoidCallback onRemove) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              title: const Text('Change Image'),
              onTap: () {
                Navigator.pop(context);
                onPick();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Image',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Brand Color Palette'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: initialColor,
                onColorChanged: onColorChanged,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Select Color',
                  style: TextStyle(fontWeight: FontWeight.bold))),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 15)),
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
                  opacity: 0.5, // Subtle for better readability
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
