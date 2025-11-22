import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // Keep your extensions

class ProductCardSkeleton extends StatelessWidget {
  final bool isLarge;

  const ProductCardSkeleton({super.key, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive shimmer colors based on theme
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: isLarge ? 320 : null,
        decoration: BoxDecoration(
          // Use the same background color/radius as your real card
          color: context.colors.surfaceDim, 
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -------------------------------------------------------
            // IMAGE SKELETON
            // -------------------------------------------------------
            Expanded(
              flex: isLarge ? 3 : 2,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white, // Color doesn't matter inside shimmer
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // -------------------------------------------------------
            // DETAILS SKELETON
            // -------------------------------------------------------
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Line
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price / Subtitle Line
                    Row(
                      children: [
                        Container(
                          height: 14,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (isLarge) ...[
                          const SizedBox(width: 8),
                          // Extra box for seller info in Large mode
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}