import 'package:flutter/material.dart';
import 'package:agentichr_frontend/core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final bool? isPositive;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                  if (change != null && isPositive != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositive!
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive! ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: isPositive! ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            change!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPositive! ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
