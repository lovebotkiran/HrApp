import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';
import 'package:agentichr_frontend/domain/providers/providers.dart';
import 'package:agentichr_frontend/data/models/candidate.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidateDetailScreen extends ConsumerWidget {
  final String candidateId;

  const CandidateDetailScreen({super.key, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidateAsync = ref.watch(candidateDetailProvider(candidateId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              candidateAsync.whenData((candidate) {
                Navigator.pushNamed(
                  context,
                  '/candidates/edit',
                  arguments: candidate,
                );
              });
            },
            tooltip: 'Edit Candidate',
          ),
        ],
      ),
      body: candidateAsync.when(
        data: (candidate) => _buildContent(context, candidate),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Error loading candidate details',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(candidateDetailProvider(candidateId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Candidate candidate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  candidate.firstName.isNotEmpty &&
                          candidate.lastName.isNotEmpty
                      ? '${candidate.firstName[0]}${candidate.lastName[0]}'
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${candidate.firstName} ${candidate.lastName}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      candidate.email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (candidate.phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        candidate.phone!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildInfoSection(
            context,
            title: 'Professional Details',
            icon: Icons.work_outline,
            children: [
              _buildInfoRow(
                  context,
                  'Experience',
                  candidate.totalExperienceYears != null
                      ? '${candidate.totalExperienceYears} years'
                      : 'Not specified'),
              _buildInfoRow(context, 'Education',
                  candidate.highestEducation ?? 'Not specified'),
              _buildInfoRow(
                  context,
                  'Current Role',
                  candidate.currentDesignation != null &&
                          candidate.currentCompany != null
                      ? '${candidate.currentDesignation} at ${candidate.currentCompany}'
                      : candidate.currentDesignation ??
                          candidate.currentCompany ??
                          'Not specified'),
              if (candidate.linkedinUrl != null &&
                  candidate.linkedinUrl!.isNotEmpty)
                _buildInfoRow(context, 'LinkedIn', candidate.linkedinUrl!),
              if (candidate.currentLocation != null)
                _buildInfoRow(context, 'Location', candidate.currentLocation!),
              if (candidate.expectedCTC != null)
                _buildInfoRow(
                    context, 'Expected CTC', '${candidate.expectedCTC}'),
              if (candidate.portfolioUrl != null &&
                  candidate.portfolioUrl!.isNotEmpty)
                _buildInfoRow(context, 'Portfolio', candidate.portfolioUrl!),
            ],
          ),
          const SizedBox(height: 24),

          // Skills Section
          if (candidate.skills != null && candidate.skills!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Skills', Icons.psychology_outlined),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: candidate.skills!.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                  side:
                      BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Certifications
          if (candidate.certifications != null &&
              candidate.certifications!.isNotEmpty) ...[
            _buildSectionTitle(
                context, 'Certifications', Icons.verified_outlined),
            const SizedBox(height: 12),
            Column(
              children: candidate.certifications!.map((cert) {
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(cert),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Languages
          if (candidate.languages != null &&
              candidate.languages!.isNotEmpty) ...[
            _buildSectionTitle(context, 'Languages', Icons.translate_outlined),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: candidate.languages!.map((lang) {
                return Chip(
                  label: Text(lang),
                  avatar: const Icon(Icons.language, size: 16),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 40),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (candidate.resumeUrl != null) {
                      String url = candidate.resumeUrl!;
                      if (url.startsWith('uploads/')) {
                        url = 'http://localhost:8000/$url';
                      }
                      launchUrl(Uri.parse(url));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No resume uploaded')),
                      );
                    }
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Resume'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse('mailto:${candidate.email}'));
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, title, icon),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
