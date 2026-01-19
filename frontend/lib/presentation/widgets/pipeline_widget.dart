import 'package:flutter/material.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';

class PipelineWidget extends StatelessWidget {
  final Map<String, int> stages;

  const PipelineWidget({
    super.key,
    required this.stages,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty stages
    if (stages.isEmpty) {
      return const Center(
        child: Text('No pipeline data available'),
      );
    }

    final maxValue = stages.values.reduce((a, b) => a > b ? a : b);
    
    // Handle all zero values
    if (maxValue == 0) {
      return const Center(
        child: Text('No candidates in pipeline'),
      );
    }
    
    return Column(
      children: stages.entries.map((entry) {
        final percentage = ((entry.value / maxValue) * 100).round();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: entry.value / maxValue,
                  minHeight: 12,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStageColor(entry.key),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'applied':
        return AppTheme.infoColor;
      case 'screening':
        return AppTheme.primaryColor;
      case 'shortlisted':
        return const Color(0xFF8B5CF6);
      case 'interview':
        return AppTheme.warningColor;
      case 'selected':
        return const Color(0xFF10B981);
      case 'offered':
        return AppTheme.successColor;
      case 'onboarded':
        return const Color(0xFF059669);
      default:
        return AppTheme.primaryColor;
    }
  }
}
