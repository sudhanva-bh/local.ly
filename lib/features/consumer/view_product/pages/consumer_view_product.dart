import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/providers/profile_provider.dart'; // Ensure this is imported
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';
import 'package:locally/features/consumer/view_product/widgets/rating_section.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/product_map.dart';
import 'package:locally/common/widgets/products/image_gallary.dart';
import 'package:locally/features/view_seller/pages/view_seller_page.dart';

class ConsumerViewProduct extends ConsumerStatefulWidget {
  final String productId;
  const ConsumerViewProduct({super.key, required this.productId});

  @override
  ConsumerState<ConsumerViewProduct> createState() =>
      _ConsumerViewProductState();
}

class _ConsumerViewProductState extends ConsumerState<ConsumerViewProduct> {
  int _quantity = 1;

  /// Increment quantity logic with stock check
  void _increment(int maxStock) {
    if (_quantity >= maxStock) return;
    setState(() {
      _quantity++;
    });
  }

  /// Decrement quantity logic
  void _decrement() {
    if (_quantity <= 1) return;
    setState(() {
      _quantity--;
    });
  }

  /// Add the selected quantity to the cart
  Future<void> _addToCart(RetailProduct product) async {
    try {
      // Trigger the CartController to add the item
      await ref
          .read(cartControllerProvider.notifier)
          .addItem(
            productId: product.productId,
            quantity: _quantity,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Item added to cart (x$_quantity)",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                // Optimistic undo logic
                ref
                    .read(cartControllerProvider.notifier)
                    .removeItem(product.productId);
              },
            ),
          ),
        );
        // Reset quantity to 1 after successful add
        setState(() {
          _quantity = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding to cart: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show the map bottom sheet
  /// We use a local adapter because existing sheets are typed for WholesaleProduct
  void _showExpandedMap(BuildContext context, RetailProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RetailExpandedMapSheet(product: product);
      },
    );
  }

  /// Builds the Bottom Bar with Quantity Selector and Add to Cart button
  Widget _buildBottomBar(BuildContext context, RetailProduct product) {
    final colors = context.colors;
    final text = context.text;
    final isOutOfStock = product.isOutOfStock;

    return BottomAppBar(
      color: colors.surfaceContainer,
      elevation: 3,
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // --- Quantity Selector ---
          if (!isOutOfStock) ...[
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: _decrement,
                    color: _quantity > 1 ? colors.onSurface : colors.outline,
                  ),
                  Text(
                    "$_quantity",
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _increment(product.stock),
                    color: _quantity < product.stock
                        ? colors.onSurface
                        : colors.outline,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],

          // --- Add to Cart Button ---
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfStock ? colors.outline : colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 0,
              ),
              onPressed: isOutOfStock ? null : () => _addToCart(product),
              child: Text(
                isOutOfStock ? "Out of Stock" : "Add to Cart",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    // Fetch the retail product stream
    final productAsync = ref.watch(retailProductByIdProvider(widget.productId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) =>
            product != null ? _buildBottomBar(context, product) : null,
        loading: () => null,
        error: (_, __) => null,
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text("Product not found."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼️ Image gallery
                Hero(
                  tag: 'product_img_${widget.productId}',
                  child: ProductImageGallery(imageUrls: product.imageUrls),
                ),
                const SizedBox(height: 16),

                /// 🧾 Bottom details
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name, //
                              style: text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${product.price.toStringAsFixed(2)}",
                                style: text.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                              if (product.isDiscounted)
                                Text(
                                  product.discountPercentage, //
                                  style: text.labelMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Seller Info
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => ViewSellerPage(
                              sellerId: product.sellerId,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceDim,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.storefront, color: colors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Sold by", style: text.labelSmall),
                                    // 🌟 UPDATED SELLER FETCH LOGIC 🌟
                                    Consumer(
                                      builder: (context, ref, _) {
                                        return ref
                                            .watch(
                                              getProfileByIdProvider(
                                                product.sellerId,
                                              ),
                                            )
                                            .when(
                                              data: (seller) => Text(
                                                seller
                                                    .shopName, // Assuming Shop Name for sellers
                                                style: text.bodyMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              loading: () => const SizedBox(
                                                height: 10,
                                                width: 50,
                                                child:
                                                    LinearProgressIndicator(),
                                              ),
                                              error: (_, __) =>
                                                  const Text("Unknown Seller"),
                                            );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        "Description",
                        style: text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : "No description provided.",
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// 🌟 Ratings Section
                      ConsumerProductRatingsSection(
                        productId: product.productId, // Pass the ID
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Item Location",
                                  style: text.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showExpandedMap(context, product),
                                  icon: const Icon(Icons.fullscreen),
                                  label: const Text("Expand"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            GestureDetector(
                              onTap: () => _showExpandedMap(context, product),
                              child: AbsorbPointer(
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

/// --------------------------------------------------------------------------
/// INTERNAL WIDGET: Retail Expanded Map Sheet
/// --------------------------------------------------------------------------
class _RetailExpandedMapSheet extends ConsumerWidget {
  final RetailProduct product;

  const _RetailExpandedMapSheet({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.text;
    // Get current consumer profile to calculate distance/show relative location
    final userProfileAsync = ref.watch(currentConsumerProfileProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Product Location", style: text.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline.withOpacity(0.3)),

          // Map
          Expanded(
            child: userProfileAsync.when(
              data: (user) {
                if (user == null ||
                    user.latitude == null ||
                    user.longitude == null) {
                  // User location unknown, center on product
                  return _buildMap(
                    context: context,
                    productLocation: LatLng(
                      product.latitude,
                      product.longitude,
                    ),
                  );
                }

                final userLocation = LatLng(user.latitude!, user.longitude!);
                final productLocation = LatLng(
                  product.latitude,
                  product.longitude,
                );

                final bounds = LatLngBounds.fromPoints([
                  userLocation,
                  productLocation,
                ]);

                return _buildMap(
                  context: context,
                  productLocation: productLocation,
                  userLocation: userLocation,
                  bounds: bounds,
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (e, _) => Center(
                child: Text("Could not load location data: $e"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap({
    required BuildContext context,
    required LatLng productLocation,
    LatLng? userLocation,
    LatLngBounds? bounds,
  }) {
    final colors = context.colors;

    final List<Marker> markers = [
      // Product Marker
      Marker(
        point: productLocation,
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    ];

    if (userLocation != null) {
      markers.add(
        // User Marker
        Marker(
          point: userLocation,
          width: 48,
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              color: colors.tertiary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
        ),
      );
    }

    final List<Polyline> polylines = (userLocation != null)
        ? [
            Polyline(
              points: [userLocation, productLocation],
              color: colors.primary.withOpacity(0.7),
              strokeWidth: 3,
              isDotted: true,
            ),
          ]
        : [];

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: bounds != null
            ? CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(60),
              )
            : null,
        initialCenter: bounds == null ? productLocation : bounds.center,
        initialZoom: 14,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${dotenv.env["MAPTILER_API_KEY"]}",
          userAgentPackageName: "com.locally.app",
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
