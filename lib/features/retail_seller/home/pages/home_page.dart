import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/inventory_service_provider.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/services/chat/chat_service.dart';
import 'package:locally/features/chat/pages/retailer_chat_list_page.dart';
import 'package:locally/features/retail_seller/retail_nav_page.dart';
import 'package:locally/features/wholesale_seller/home/widgets/action.dart';
import 'package:locally/features/wholesale_seller/home/widgets/alert_card.dart';

class RetailHomePage extends ConsumerWidget {
  const RetailHomePage({super.key});

  // Helper to get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 1. Watch the User Profile to get the Shop ID (uid)
    final userProfileState = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- Top Image Banner with Smooth Scroll ---
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: false,
            snap: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          colorScheme.surface.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 40,
                    child: Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(0, -40, 0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---------------------------------------------------------
                    // GREETING SECTION (New)
                    // ---------------------------------------------------------
                    userProfileState.maybeWhen(
                      data: (seller) {
                        if (seller == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getTimeBasedGreeting()},',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              seller.shopName,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 24),
                            Divider(color: colorScheme.outlineVariant),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      // Don't show anything while loading/error to prevent layout jump
                      orElse: () => const SizedBox.shrink(),
                    ),

                    Text(
                      'Alerts & Updates',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------------------------------------------------------
                    // INTEGRATED PROVIDERS SECTION
                    // ---------------------------------------------------------
                    userProfileState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error loading profile: $err'),
                      data: (seller) {
                        if (seller == null) {
                          return const Text("Please log in to view alerts.");
                        }

                        final shopId = seller.uid;

                        // 2. Watch the specific inventory providers using the shopId
                        final lowStockAsync = ref.watch(
                          retailLowStockProvider(shopId),
                        );
                        final pendingOrdersAsync = ref.watch(
                          pendingRetailOrderIdsProvider(shopId),
                        );

                        final unreadChatsAsync = ref.watch(
                          unreadChatCountProvider(shopId),
                        );

                        return Column(
                          children: [
                            // --- Stock Alert Card ---
                            AlertCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'Stock Alert',
                              description: lowStockAsync.when(
                                data: (ids) => ids.isEmpty
                                    ? 'Stock levels are healthy.'
                                    : '${ids.length} items are low in stock.',
                                loading: () => 'Checking inventory...',
                                error: (_, __) => 'Could not load stock status.',
                              ),
                              onTap: () => ref
                                  .read(retailNavIndexProvider.notifier)
                                  .state = 1,
                            ),
                            const SizedBox(height: 16),

                            // --- Pending Orders Card ---
                            AlertCard(
                              icon: Icons.access_time_outlined,
                              title: 'Pending orders',
                              description: pendingOrdersAsync.when(
                                data: (ids) => ids.isEmpty
                                    ? 'No pending orders.'
                                    : '${ids.length} orders are pending.',
                                loading: () => 'Checking orders...',
                                error: (_, __) => 'Could not load orders.',
                              ),
                              onTap: () => ref
                                  .read(retailNavIndexProvider.notifier)
                                  .state = 3,
                            ),
                            const SizedBox(height: 16),

                            AlertCard(
                              icon: Icons.chat_outlined,
                              title: 'View Chats',
                              description: unreadChatsAsync.when(
                                data: (count) => count == 0
                                    ? 'No unread messages.'
                                    : '$count unread chat${count == 1 ? '' : 's'}.',
                                loading: () => 'Checking messages...',
                                error: (_, __) => 'Could not load chats.',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SellerChatListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    // --- Quick Actions Section ---
                    const SizedBox(height: 45),
                    Text(
                      'Quick Actions',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardActionCard(
                            icon: Icons.inventory_2_rounded,
                            title: 'Manage Products',
                            onTap: () {
                              ref.read(retailNavIndexProvider.notifier).state = 1;
                            },
                          ),
                        ),
                        const SizedBox(width: 16), // Spacing between cards
                        Expanded(
                          child: DashboardActionCard(
                            icon: Icons.receipt_long_rounded,
                            title: 'View Orders',
                            onTap: () {
                              ref.read(retailNavIndexProvider.notifier).state = 3;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}