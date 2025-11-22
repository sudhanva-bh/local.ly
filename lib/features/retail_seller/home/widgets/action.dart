import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.height = 110, // Added default height to mimic grid tile size
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceDim, // slightly distinct background
      borderRadius: BorderRadius.circular(20),
      shadowColor: context.colors.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: height, // Enforce consistent height
          width: double.infinity, // Fill the Expanded widget width
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.primary, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
