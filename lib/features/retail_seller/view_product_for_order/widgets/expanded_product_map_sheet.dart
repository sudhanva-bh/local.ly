import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/profile_provider.dart';

class ExpandedProductMapSheet extends ConsumerWidget {
  final WholesaleProduct product;

  const ExpandedProductMapSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.text;
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Sheet Header ---
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

          // --- Map Content ---
          Expanded(
            child: userProfileAsync.when(
              data: (seller) {
                if (seller == null ||
                    seller.latitude == null ||
                    seller.longitude == null) {
                  // User location not available, show only product
                  return _buildMap(
                    context: context,
                    productLocation: LatLng(
                      product.latitude,
                      product.longitude,
                    ),
                  );
                }

                // Both locations are available
                final userLocation = LatLng(
                  seller.latitude!,
                  seller.longitude!,
                );
                final productLocation = LatLng(
                  product.latitude,
                  product.longitude,
                );

                // Calculate bounds to fit both markers
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
                child: Text("Could not load user location: $e"),
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

    // Create markers
    final List<Marker> markers = [
      // --- IMPROVED PRODUCT MARKER ---
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
            Icons.storefront, // Thematic icon for a seller
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    ];

    // Add user marker if available
    if (userLocation != null) {
      markers.add(
        // --- IMPROVED USER MARKER ---
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
            child: const Icon(
              Icons.person, // Thematic icon for the user
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      );
    }

    // Create polyline if both locations are available
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
        // If bounds are available, fit map to them. Otherwise, center on product.
        initialCameraFit: bounds != null
            ? CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(60), // Add padding
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
