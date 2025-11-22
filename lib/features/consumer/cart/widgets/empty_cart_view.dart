import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: colors.outline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your cart is empty",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Looks like you haven't added anything yet.",
            style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 168),
        ],
      ),
    );
  }
}