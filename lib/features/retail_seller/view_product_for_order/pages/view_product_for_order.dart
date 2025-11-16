import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/expanded_product_map_sheet.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/order_bottom_sheet.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/product_map.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/product_ratings_section.dart';
import 'package:locally/common/widgets/products/image_gallary.dart';

class ViewProduct extends ConsumerWidget {
  final String productId;
  const ViewProduct({super.key, required this.productId});

  /// Extracted method to show the bottom sheet
  void _showExpandedMap(BuildContext context, WholesaleProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to be taller
      backgroundColor: Colors.transparent, // For rounded corners
      builder: (context) {
        return ExpandedProductMapSheet(product: product);
      },
    );
  }

  /// Method to show the order bottom sheet
  void _showOrderSheet(BuildContext context, WholesaleProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // So keyboard (if any) doesn't hide it
      backgroundColor: Colors.transparent, // For rounded corners
      builder: (context) {
        return Padding(
          // Handle the system's bottom safe area (like the gesture bar)
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: OrderBottomSheet(product: product),
        );
      },
    );
  }

  /// --- WIDGET WITH FIX ---
  Widget _buildBottomBar(BuildContext context, WholesaleProduct product) {
    final colors = context.colors;

    return BottomAppBar(
      color: colors.surfaceDim,
      elevation: 10,
      height: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            // Reduced padding from 14 to 12
            padding: const EdgeInsets.symmetric(vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100), // Fully rounded
            ),
          ),
          onPressed: () => _showOrderSheet(context, product),
          child: Center(
            child: const Text(
              "Order Now",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// --- END FIX ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.text;

    // Watch product stream (real-time updates)
    final productAsync = ref.watch(wholesaleProductByIdProvider(productId));

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHighest,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) =>
            product != null ? _buildBottomBar(context, product) : null,
        loading: () => null, // No bar while loading
        error: (_, __) => null, // No bar on error
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text("Product not found."));
          }

          return SingleChildScrollView(
            // Added padding to ensure content clears the bottom bar
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼️ Image gallery (Assumed to exist)
                ProductImageGallery(imageUrls: product.imageUrls),
                const SizedBox(height: 16),

                /// 🧾 Bottom details
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surfaceDim,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: text.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Category: ${product.category}",
                        style: text.bodyMedium!.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Price: ", style: text.bodyMedium),
                          Text(
                            "₹${product.price.toStringAsFixed(2)}",
                            style: text.bodyLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Stock: ${product.stock}",
                            style: text.bodyMedium,
                          ),
                          Text(
                            "Min Order: ${product.minOrderQuantity}",
                            style: text.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Divider(color: colors.outline.withOpacity(0.5)),
                      const SizedBox(height: 12),

                      Text(
                        "Description",
                        style: text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : "No description provided.",
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      /// 🌟 Ratings Section
                      if (product.ratings.isNotEmpty)
                        ProductRatingsSection(
                          ratings: product.ratings,
                          averageRating: product.averageRating,
                        ),

                      /// 🗺️ Product location map
                      if (product.latitude != 0.0 && product.longitude != 0.0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: colors.outline.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              "Product Location",
                              style: text.titleMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Wrapped ProductMap in a GestureDetector
                            GestureDetector(
                              onTap: () => _showExpandedMap(context, product),
                              child: AbsorbPointer(
                                // Prevents map from capturing tap
                                child: ProductMap(
                                  latitude: product.latitude,
                                  longitude: product.longitude,
                                ),
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
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
