// lib/features/view_seller/widgets/view_seller_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/retail_seller/profile_page/widgets/editable_info_tile.dart';
import 'package:locally/features/retail_seller/profile_page/widgets/shop_location_map.dart';
import 'package:locally/features/view_seller/widgets/add_review_sheet.dart'; // New widget

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

    return RefreshIndicator(
      // Allow pull-to-refresh to get latest seller data
      onRefresh: () async =>
          await ref.refresh(getProfileByIdProvider(seller.uid).future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                seller.sellerType.toWords(),
                style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),

              // 📦 Product count
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text("Products"),
                  subtitle: Text('$productCount total'),
                ),
              ),
              const SizedBox(height: _sectionSpacing),

              // 📞 Contact Info Group (Read-only)
              Card(
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
              const SizedBox(height: _sectionSpacing),

              // 🗺️ Map display
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                clipBehavior: Clip.antiAlias, // Important for map
                child: hasLocation
                    ? ShopLocationMap(seller: seller) // Re-using this widget
                    : Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text('No location set'),
                      ),
              ),
              const SizedBox(height: _sectionSpacing),

              // ✨ Account Meta Group
              Card(
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
              const SizedBox(height: _sectionSpacing),

              // ⭐ Ratings (with "Add Review" button)
              Card(
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
                            left: 16.0, right: 8, top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ratings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            // --- NEW FEATURE ---
                            TextButton.icon(
                              icon: const Icon(Icons.rate_review_outlined,
                                  size: 18),
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
                                // Show the reviewer's name
                                title: Text(r.reviewerName ?? 'Anonymous'),
                                // Format the subtitle
                                subtitle: Text(
                                  '${r.stars}/5 - ${r.title}\n${r.description ?? ''}',
                                ),
                                // Use three lines if there is a description
                                isThreeLine: r.description != null &&
                                    r.description!.isNotEmpty,
                              ),
                            )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                              child: Text('No ratings yet. Be the first!')),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to show the "Add Review" bottom sheet
  Future<void> _showAddReviewSheet(
      BuildContext context, WidgetRef ref, Seller seller) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Pass the seller to the new sheet widget
        return AddReviewSheet(seller: seller);
      },
    );
  }

  // Helper method to format dates
  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }
    try {
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (e) {
      return date.toIso8601String();
    }
  }
}