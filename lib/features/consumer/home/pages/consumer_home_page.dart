import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/features/consumer/home/widgets/product_card.dart';
import 'package:locally/features/consumer/home/widgets/product_skeleton_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Project Imports
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/features/consumer/consumer_nav_page.dart';

// Order Imports
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/consumer/view_orders/pages/order_details_page.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_expandable_card.dart';

// -----------------------------------------------------------------------------
// PROVIDERS
// -----------------------------------------------------------------------------
final recommendationsProvider = FutureProvider<List<RetailProduct>>((
  ref,
) async {
  final response = await Supabase.instance.client.rpc(
    'get_recommendations',
    params: {'target_user_id': Supabase.instance.client.auth.currentUser?.id},
  );
  return (response as List).map((data) => RetailProduct.fromMap(data)).toList();
});

final freshFindsProvider = FutureProvider<List<RetailProduct>>((ref) async {
  final response = await Supabase.instance.client.rpc(
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
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final freshFindsAsync = ref.watch(freshFindsProvider);
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER
          SliverToBoxAdapter(child: _buildHeader(context)),

          // 2. TITLE: DISCOVER
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

          // 3. DISCOVER CONTENT (Updated to Single Slider)
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

              // Single Horizontal Slider for all items
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
                          isLarge: false, // Standard size for all
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            // === SHIMMER LOADING FOR DISCOVER ===
            loading: () => [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 4, // Show a few skeletons
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

          // 4. TITLE: FRESH FROM SELLERS
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

          // 5. FRESH FINDS CONTENT
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
                          isLarge: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            },
            // === SHIMMER LOADING FOR FRESH FINDS ===
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

          // 6. RECENT ORDERS SECTION
          ...ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) return [const SliverToBoxAdapter()];
              final recentOrders = orders.take(3).toList();

              return [
                // Title
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
                // List of Orders
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
                  child: Icon(Icons.person),
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
