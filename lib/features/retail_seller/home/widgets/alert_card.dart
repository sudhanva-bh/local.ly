import 'package:flutter/material.dart';

class AlertCard extends StatefulWidget {
  const AlertCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap, // Added callback
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      // Handle the press state for the animation
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0, // The "Bounce" effect
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.8 : 1.0, // Slight fade on press
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(widget.icon, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                // Optional: Add a subtle arrow to indicate it's clickable
                if (widget.onTap != null)
                  Icon(
                    Icons.chevron_right_rounded, 
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}