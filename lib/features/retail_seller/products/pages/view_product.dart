// lib/features/wholesale_seller/products/pages/view_product.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/features/retail_seller/products/pages/edit_product.dart';
import 'package:locally/common/widgets/products/image_gallary.dart';

class ViewProduct extends ConsumerWidget {
  final String productId;
  const ViewProduct({super.key, required this.productId});

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
      floatingActionButton: productAsync.hasValue && productAsync.value != null
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProduct(
                    productId: productId,
                  ),
                ),
              ),
              child: const Icon(Icons.edit),
            )
          : null,
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text("Product not found."));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼️ Image gallery
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

                      if (product.ratings.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${product.averageRating.toStringAsFixed(1)} "
                              "(${product.ratingCount} ratings)",
                              style: text.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

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
                            _buildMap(context, product),
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

  /// 🗺️ Extracted Map Widget
  Widget _buildMap(BuildContext context, product) {
    final colors = context.colors;
    final text = context.text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 180,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: colors.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(product.latitude, product.longitude),
              initialZoom: 14,
              interactionOptions: const InteractionOptions(flags: 0),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${dotenv.env["MAPTILER_API_KEY"]}",
                userAgentPackageName: "com.locally.app",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(product.latitude, product.longitude),
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: colors.primary,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Lat: ${product.latitude.toStringAsFixed(5)}, "
                      "Lng: ${product.longitude.toStringAsFixed(5)}",
                      style: text.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
