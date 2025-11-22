import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/profile_provider.dart'; // Required for Seller Info
import 'package:locally/features/consumer/view_product/pages/consumer_view_product.dart';

class ProductCard extends ConsumerStatefulWidget {
  final RetailProduct product;
  final bool isLarge; // Controls layout variation

  const ProductCard({
    super.key,
    required this.product,
    this.isLarge = false,
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
    final colors = context.colors;
    final text = context.text;

    // 1. Extract the image URL safely
    final String? imageUrl = widget.product.imageUrls.isNotEmpty
        ? widget.product.imageUrls.first
        : null;

    // 2. Fetch Seller Info (Only needed if isLarge)
    final sellerAsync = widget.isLarge
        ? ref.watch(getProfileByIdProvider(widget.product.sellerId))
        : null;

    return GestureDetector(
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
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          // Adjust height based on layout mode
          height: widget.isLarge ? 320 : null,
          decoration: BoxDecoration(
            // 3. Requested Color: surfaceDim
            color: colors.surfaceDim,
            borderRadius: BorderRadius.circular(24),
            // 4. Elevation via BoxShadow
            boxShadow: _isPressed
                ? [] // Remove shadow on press for depth effect
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------
              // IMAGE SECTION
              // -------------------------------------------------------
              Expanded(
                flex: widget.isLarge ? 3 : 2,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceDim,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                      bottom: Radius.circular(20),
                    ),
                    child: imageUrl != null
                        ? Hero(
                            tag: 'product_img_${widget.product.productId}',
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, color: Colors.white),
                          ),
                  ),
                ),
              ),

              // -------------------------------------------------------
              // DETAILS SECTION
              // -------------------------------------------------------
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isLarge) ...[
                        // === LARGE VARIATION ===
                        // Row: Name and Price in one line
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${widget.product.price.toStringAsFixed(0)}",
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row: Seller Info
                        sellerAsync!.when(
                          data: (seller) => Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  seller.shopName,
                                  style: text.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox(
                            height: 14,
                            width: 80,
                            child: LinearProgressIndicator(),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ] else ...[
                        // === SMALL VARIATION ===
                        // Column: Name then Price
                        Text(
                          widget.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${widget.product.price.toStringAsFixed(0)}",
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
