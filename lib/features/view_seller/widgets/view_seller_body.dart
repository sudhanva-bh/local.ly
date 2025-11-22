// lib/features/view_seller/widgets/view_seller_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/models/users/account_type.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/consumer/view_product/pages/consumer_view_product.dart';
import 'package:locally/features/retail_seller/profile_page/widgets/editable_info_tile.dart';
import 'package:locally/features/retail_seller/profile_page/widgets/shop_location_map.dart';
import 'package:locally/features/view_seller/widgets/add_review_sheet.dart';

/// Provider to stream products for a specific seller
final productsBySellerIdProvider =
    StreamProvider.family<List<RetailProduct>, String>((ref, sellerId) {
      final service = ref.watch(retailProductServiceProvider);
      return service.getProductsBySeller(sellerId);
    });

class ViewSellerBody extends ConsumerWidget {
  final Seller seller;

  const ViewSellerBody({
    super.key,
    required this.seller,
  });

  // --- Constants for modern UI ---
  static const double _cardElevation = 2.0;
  static const double _cardBorderRadius = 16.0;
  static const double _sectionSpacing = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasLocation =
        seller.latitude != null &&
        seller.longitude != null &&
        seller.address != null;
    final productCount = seller.productIds?.length ?? 0;

    // Consistent card shape
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
    );
    // Consistent shadow
    final shadowColor = colors.shadow.withOpacity(0.1);

    // Watch the products for this seller
    final productsAsync = ref.watch(productsBySellerIdProvider(seller.uid));

    return RefreshIndicator(
      // Allow pull-to-refresh to get latest seller data
      onRefresh: () async {
        await ref.refresh(getProfileByIdProvider(seller.uid).future);
        // Also refresh the product list stream if needed (streams usually auto-update, but good practice)
        ref.invalidate(productsBySellerIdProvider(seller.uid));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100), // Padding for FAB
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // 🏪 Profile image with shadow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: seller.profileImageUrl != null
                    ? NetworkImage(seller.profileImageUrl!)
                    : null,
                child: seller.profileImageUrl == null
                    ? const Icon(Icons.store, size: 48)
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // 🏷️ Shop name (Read-only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                seller.shopName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              seller.accountType.toWords(),
              style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),

            // 🛒 NEW: Horizontal Products Scroll Section
            // We don't add horizontal padding here so the list can scroll edge-to-edge
            _buildProductsSection(context, productsAsync),
            const SizedBox(height: _sectionSpacing),

            // 📞 Contact Info Group (Read-only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: Column(
                  children: [
                    EditableInfoTile(
                      title: 'Phone Number',
                      value: seller.phoneNumber ?? 'Not provided',
                      icon: Icons.phone_outlined,
                      editable: false, // Read-only
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Email',
                      value: seller.email,
                      icon: Icons.email_outlined,
                      editable: false, // Read-only
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Address',
                      value: seller.address ?? 'No address set',
                      icon: Icons.location_on_outlined,
                      editable: false, // Read-only
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _sectionSpacing),

            // 🗺️ Map display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                clipBehavior: Clip.antiAlias, // Important for map
                child: hasLocation
                    ? ShopLocationMap(seller: seller)
                    : Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text('No location set'),
                      ),
              ),
            ),
            const SizedBox(height: _sectionSpacing),

            // ✨ Account Meta Group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: Column(
                  children: [
                    EditableInfoTile(
                      title: 'Joined On',
                      value: _formatDate(seller.createdAt),
                      icon: Icons.calendar_today_outlined,
                      editable: false, // Read-only
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Last Updated',
                      value: _formatDate(seller.updatedAt),
                      icon: Icons.history_outlined,
                      editable: false, // Read-only
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _sectionSpacing),

            // ⭐ Ratings (with "Add Review" button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ratings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.rate_review_outlined,
                                size: 18,
                              ),
                              label: const Text('Add Review'),
                              onPressed: () =>
                                  _showAddReviewSheet(context, ref, seller),
                            ),
                          ],
                        ),
                      ),
                      // Show existing ratings
                      if (seller.ratings != null && seller.ratings!.isNotEmpty)
                        ...seller.ratings!
                            .take(5) // Show up to 5
                            .map(
                              (r) => ListTile(
                                leading: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                title: Text(r.reviewerName ?? 'Anonymous'),
                                subtitle: Text(
                                  '${r.stars}/5 - ${r.title}\n${r.description ?? ''}',
                                ),
                                isThreeLine:
                                    r.description != null &&
                                    r.description!.isNotEmpty,
                              ),
                            )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('No ratings yet. Be the first!'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(
    BuildContext context,
    AsyncValue<List<RetailProduct>> productsAsync,
  ) {
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Products (0)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 0,
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        "This seller hasn't listed any products yet.",
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // --- HORIZONTAL SCROLLING LIST ---
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Text(
                'Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 240, // Height constraint for the horizontal list
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _HorizontalProductCard(product: products[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Center(
        child: Text('Error loading products: $error'),
      ),
    );
  }

  Future<void> _showAddReviewSheet(
    BuildContext context,
    WidgetRef ref,
    Seller seller,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AddReviewSheet(seller: seller);
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    try {
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (e) {
      return date.toIso8601String();
    }
  }
}

class _HorizontalProductCard extends StatefulWidget {
  final RetailProduct product;
  const _HorizontalProductCard({required this.product});

  @override
  State<_HorizontalProductCard> createState() => _HorizontalProductCardState();
}

class _HorizontalProductCardState extends State<_HorizontalProductCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95; // pressed scale
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0; // release scale
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 160.0;
    final product = widget.product;
    final hasImage = product.imageUrls.isNotEmpty;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConsumerViewProduct(
              productId: product.productId,
              placeholderImage: product.imageUrls.first,
            ),
          ),
        );
      },

      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,

        child: SizedBox(
          width: cardWidth,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),

            child: InkWell(
              splashColor: Colors.black12,
              highlightColor: Colors.transparent,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    child: Container(
                      color: Colors.grey[200],
                      width: double.infinity,
                      child: hasImage
                          ? Hero(
                              tag: 'product_img_${product.productId}',
                              child: Image.network(
                                product.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),

                  // Info Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${product.price.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
