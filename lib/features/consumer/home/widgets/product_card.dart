import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/utilities/location_utils.dart';
import 'package:locally/features/consumer/view_product/pages/consumer_view_product.dart';

/// Helper provider to fetch Seller Name efficiently
final sellerNameProvider = FutureProvider.family<String, String>((
  ref,
  sellerId,
) async {
  final service = ref.watch(profileServiceProvider);
  final result = await service.getProfile(sellerId);
  return result.fold((l) => "Unknown Seller", (r) => r.shopName);
});

class ProductCard extends ConsumerStatefulWidget {
  final RetailProduct product;

  const ProductCard({
    super.key,
    required this.product,
    // isLarge is removed
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) =>
      setState(() => _isPressed = true);
  void _handleTapUp(TapUpDetails details) => setState(() => _isPressed = false);
  void _handleTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    // 1. Data Preparation
    final userProfile = ref.watch(currentConsumerProfileProvider).value;
    final isOOS = widget.product.isOutOfStock; 

    // 2. Calculate Distance
    String distanceString = "";
    if (userProfile?.latitude != null && userProfile?.longitude != null) {
      final distKm = LocationUtils.calculateDistance(
        userProfile!.latitude!,
        userProfile.longitude!,
        widget.product.latitude,
        widget.product.longitude,
      );
      distanceString = LocationUtils.formatDistance(distKm);
    }

    // 3. Fetch Seller Name
    final sellerNameAsync = ref.watch(
      sellerNameProvider(widget.product.sellerId),
    );

    // 4. Extract image safely
    final String? imageUrl = widget.product.imageUrls.isNotEmpty
        ? widget.product.imageUrls.first
        : null;

    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsumerViewProduct(
                productId: widget.product.productId,
                placeholderImage: imageUrl,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceDim,
            borderRadius: BorderRadius.circular(16),
            // Distinct shadow from your example
            boxShadow: !_isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // IMAGE SECTION (Stack for Overlay & Badges)
                // -------------------------------------------------------------
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Hero Image
                      Hero(
                        tag: 'product_img_${widget.product.productId}',
                        child: imageUrl != null
                            ? _buildImage(imageUrl, isOOS)
                            : Container(
                                color: context.colors.surfaceContainerHigh,
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),

                      // 2. Out of Stock Overlay
                      if (isOOS)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.black54,
                              ),
                              child: Text(
                                "OUT OF STOCK",
                                style: context.text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 3. Distance Badge (Only show if In Stock)
                      if (distanceString.isNotEmpty && !isOOS)
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

                // -------------------------------------------------------------
                // DETAILS SECTION
                // -------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.product.name,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOOS
                              ? context.colors.onSurface.withOpacity(0.5)
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Seller Name
                      sellerNameAsync.when(
                        data: (name) => Text(
                          name,
                          style: context.text.bodySmall?.copyWith(
                            color: isOOS
                                ? context.colors.onSurface.withOpacity(0.4)
                                : context.colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        loading: () => const SizedBox(
                          height: 14,
                          width: 80,
                          child: LinearProgressIndicator(),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 8),

                      // Price and Rating Row
                      Row(
                        children: [
                          Text(
                            '₹${widget.product.price.toStringAsFixed(0)}',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              decoration:
                                  isOOS ? TextDecoration.lineThrough : null,
                              color: isOOS
                                  ? context.colors.onSurface.withOpacity(0.5)
                                  : null,
                            ),
                          ),
                          
                          // Discount Badge
                          if (widget.product.isDiscounted && !isOOS) ...[
                            const SizedBox(width: 6),
                            Text(
                              widget.product.discountPercentage,
                              style: context.text.labelSmall?.copyWith(
                                color: context.colors.error,
                                fontSize: 10,
                              ),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Rating Star
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: isOOS ? Colors.grey : Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.product.averageRating > 0
                                ? widget.product.averageRating
                                    .toStringAsFixed(1)
                                : '-',
                            style: context.text.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOOS ? Colors.grey : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: Applies Grayscale filter if OOS
  Widget _buildImage(String url, bool isOOS) {
    Widget image = Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Icon(Icons.image_not_supported),
      ),
    );

    if (isOOS) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation, // Desaturate
        ),
        child: image,
      );
    }
    return image;
  }
}