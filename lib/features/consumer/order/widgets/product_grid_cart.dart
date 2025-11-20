import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/utilities/location_utils.dart';

/// Helper provider to fetch Seller Name just for the UI card
/// In a production app at scale, you should JOIN this in SQL instead of N+1 fetches.
final sellerNameProvider = FutureProvider.family<String, String>((
  ref,
  sellerId,
) async {
  // Re-using your existing profile service logic if available,
  // or assuming a method exists.
  // For now, using a placeholder fetch logic based on your context.
  final service = ref.watch(profileServiceProvider);
  final result = await service.getProfile(sellerId);
  return result.fold(
    (l) => "Unknown Seller",
    (r) => r.shopName,
  );
});

class RetailProductGridCard extends ConsumerWidget {
  final RetailProduct product;

  const RetailProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentConsumerProfileProvider).value;

    // Calculate Distance
    String distanceString = "";
    if (userProfile?.latitude != null && userProfile?.longitude != null) {
      final distKm = LocationUtils.calculateDistance(
        userProfile!.latitude!,
        userProfile.longitude!,
        product.latitude,
        product.longitude,
      );
      distanceString = LocationUtils.formatDistance(distKm);
    }

    // Fetch Seller Name
    final sellerNameAsync = ref.watch(sellerNameProvider(product.sellerId));

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Section (Expanded to look big)
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: context.colors.surfaceContainerHigh,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          color: context.colors.surfaceContainerHigh,
                        ),
                ),
                // Distance Badge
                if (distanceString.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distanceString,
                            style: context.text.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Details Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.name,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Seller Name (Async)
                sellerNameAsync.when(
                  data: (name) => Text(
                    name,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => SizedBox(
                    height: 14,
                    width: 60,
                    child: LinearProgressIndicator(
                      color: context.colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // Price and Rating Row
                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.isDiscounted) ...[
                      const SizedBox(width: 6),
                      Text(
                        product.discountPercentage,
                        style: context.text.labelSmall?.copyWith(
                          color: context.colors.error,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.averageRating > 0
                          ? product.averageRating.toStringAsFixed(1)
                          : '-',
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
