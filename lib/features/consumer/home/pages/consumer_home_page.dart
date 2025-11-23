import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/constants/widget_properties.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/features/consumer/home/widgets/product_card.dart';
import 'package:locally/features/consumer/home/widgets/product_skeleton_card.dart';

// Project Imports
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/models/users/seller_model.dart'; // Ensure Seller model is imported
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/features/consumer/consumer_nav_page.dart';

// Order Imports
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/consumer/view_orders/pages/order_details_page.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_expandable_card.dart';

// Seller Imports (Assuming this path exists based on your prompt)
import 'package:locally/features/view_seller/pages/view_seller_page.dart';

// -----------------------------------------------------------------------------
// PROVIDERS
// -----------------------------------------------------------------------------

// NEW: Nearest Stores Provider
final nearestStoresProvider = FutureProvider<List<Seller>>((ref) async {
  // 1. Get current user location
  final profile = ref.watch(currentConsumerProfileProvider).value;

  // If location isn't ready, return empty
  if (profile?.latitude == null || profile?.longitude == null) {
    return [];
  }

  // 2. Call the RPC directly
  final response = await ref
      .read(supabaseClientProvider)
      .rpc(
        'get_nearest_retail_sellers',
        params: {
          'user_lat': profile!.latitude,
          'user_lon': profile.longitude,
        },
      );

  // 3. Map to Seller model
  return (response as List).map((data) => Seller.fromMap(data)).toList();
});

final recommendationsProvider = FutureProvider<List<RetailProduct>>((
  ref,
) async {
  final response = await ref
      .read(supabaseClientProvider)
      .rpc(
        'get_recommendations',
        params: {
          'target_user_id': ref
              .read(supabaseClientProvider)
              .auth
              .currentUser
              ?.id,
        },
      );
  return (response as List).map((data) => RetailProduct.fromMap(data)).toList();
});

final freshFindsProvider = FutureProvider<List<RetailProduct>>((ref) async {
  final response = await ref
      .read(supabaseClientProvider)
      .rpc(
        'get_latest_products_from_random_sellers',
        params: {'limit_count': 5},
      );
  return (response as List).map((data) => RetailProduct.fromMap(data)).toList();
});

// -----------------------------------------------------------------------------
// MAIN HOME PAGE
// -----------------------------------------------------------------------------
class ConsumerHomePage extends ConsumerStatefulWidget {
  const ConsumerHomePage({super.key});

  @override
  ConsumerState<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends ConsumerState<ConsumerHomePage> {
  @override
  Widget build(BuildContext context) {
    final nearestStoresAsync = ref.watch(nearestStoresProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final freshFindsAsync = ref.watch(freshFindsProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER
          SliverToBoxAdapter(child: _buildHeader(context)),

          // -------------------------------------------------------------------
          // 3. TITLE: DISCOVER
          // -------------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discover",
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(consumerNavIndexProvider.notifier).state = 1,
                    icon: const Icon(Icons.navigate_next_rounded),
                  ),
                ],
              ),
            ),
          ),

          // 4. DISCOVER CONTENT
          ...recommendationsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "No recommendations available yet.",
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.outline,
                        ),
                      ),
                    ),
                  ),
                ];
              }

              return [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        width: 180,
                        child: ProductCard(
                          product: products[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            loading: () => [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => const SizedBox(
                      width: 180,
                      child: ProductCardSkeleton(isLarge: false),
                    ),
                  ),
                ),
              ),
            ],
            error: (err, stack) => [
              SliverToBoxAdapter(child: Text("Error: $err")),
            ],
          ),

          // -------------------------------------------------------------------
          // 2. NEW SECTION: STORES NEAR YOU
          // -------------------------------------------------------------------
          ...nearestStoresAsync.when(
            data: (sellers) {
              if (sellers.isEmpty) return [const SliverToBoxAdapter()];
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Text(
                      "Stores Near You",
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140, // Height for the store cards
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: sellers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final seller = sellers[index];
                        return _buildSellerCard(context, seller);
                      },
                    ),
                  ),
                ),
              ];
            },
            loading: () => [
              const SliverToBoxAdapter(),
            ], // Optional: Add Skeleton
            error: (_, __) => [const SliverToBoxAdapter()],
          ),

          // -------------------------------------------------------------------
          // 5. TITLE: FRESH FROM SELLERS
          // -------------------------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Fresh from Sellers",
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(consumerNavIndexProvider.notifier).state = 1,
                    icon: const Icon(Icons.navigate_next_rounded),
                  ),
                ],
              ),
            ),
          ),

          // 6. FRESH FINDS CONTENT
          ...freshFindsAsync.when(
            data: (products) {
              if (products.isEmpty) return [const SliverToBoxAdapter()];
              return [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        width: 180,
                        child: ProductCard(
                          product: products[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            loading: () => [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => const SizedBox(
                      width: 180,
                      child: ProductCardSkeleton(isLarge: false),
                    ),
                  ),
                ),
              ),
            ],
            error: (err, stack) => [
              const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
          ),

          // -------------------------------------------------------------------
          // 7. RECENT ORDERS SECTION
          // -------------------------------------------------------------------
          ...ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) return [const SliverToBoxAdapter()];
              final recentOrders = orders.take(3).toList();

              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Recent Orders",
                          style: context.text.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              ref
                                      .read(consumerNavIndexProvider.notifier)
                                      .state =
                                  3,
                          icon: const Icon(Icons.navigate_next_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = recentOrders[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailsScreen(orderId: order.id),
                                ),
                              );
                            },
                            child: OrderExpandableCard(order: order),
                          ),
                        );
                      },
                      childCount: recentOrders.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ];
            },
            loading: () => [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            error: (err, stack) => [
              const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // Helper Widget for the Store Card
  Widget _buildSellerCard(BuildContext context, Seller seller) {
    return GestureDetector(
      onTap: () {
        // Navigate to the Seller Profile Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewSellerPage(sellerId: seller.uid),
          ),
        );
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surfaceDim,
          borderRadius: BorderRadius.circular(16),
          boxShadow: WidgetProperties.dropShadow,
        ),
        child: Row(
          children: [
            // Store Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                image: seller.profileImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(seller.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: seller.profileImageUrl == null
                  ? Icon(Icons.store, color: context.colors.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seller.shopName,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (seller.address != null)
                    Text(
                      seller.address!,
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  // Rating Badge (Optional)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          seller.ratings?.averageRating.toStringAsFixed(1) ??
                              '0', // Placeholder or calculate from ratings
                          style: context.text.labelSmall?.copyWith(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF512F), Color(0xFFF09819)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LOCAL.LY",
                    style: context.text.titleLarge?.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Local shopping, made effortless.",
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 18,
                child: GestureDetector(
                  onTap: () =>
                      ref.read(consumerNavIndexProvider.notifier).state = 4,
                  child: const Icon(Icons.person),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            "Hello ${ref.watch(currentConsumerProfileProvider).value?.fullName ?? "User"}!",
            style: context.text.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Dart Extension on List<Rating> to calculate the average
extension RatingListExtension on List<Rating> {
  double get averageRating {
    if (isEmpty) {
      return 0.0;
    }
    // Calculate the sum of all 'stars' property using fold
    final totalStars = fold(0, (sum, rating) => sum + rating.stars);
    // Divide the sum by the number of ratings (length)
    return totalStars / length;
  }
}
