import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // Assuming this exists for context.colors
import 'package:locally/common/models/orders/order_model.dart';
import 'package:locally/common/providers/orders/order_providers.dart'; // Your new provider file location
import 'package:locally/features/retail_seller/orders/wholesale_retail/widgets/retailer_order_card.dart'; // Import where you saved the card

class RetailOrdersPage extends ConsumerWidget {
  const RetailOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the stream of orders for the current retailer
    final ordersAsync = ref.watch(currentRetailOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        // 2. Handle Empty State
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: context.colors.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Orders you place will appear here.'),
              ],
            ),
          );
        }

        // 3. Sort orders: Newest first
        final sortedOrders = List<WholesaleRetailOrder>.from(orders)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // void markAsRecieved() {
        //   for (WholesaleRetailOrder order in sortedOrders) {
        //     try {
        //       final wholesaleRetailOrderService = ref.read(
        //         wholesaleRetailOrderServiceProvider,
        //       );
        //       wholesaleRetailOrderService.updateOrderStatus(
        //         order.orderId,
        //         "Received",
        //       );
        //       wholesaleRetailOrderService.addOrderToRetailerInventory(
        //         order,
        //       );
        //     } catch (e) {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Text('Failed to update status: $e'),
        //           backgroundColor: context.colors.error,
        //         ),
        //       );
        //     }
        //   }
        // }

        // 4. List of Orders
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 160),
              itemCount: sortedOrders.length,
              itemBuilder: (context, index) {
                final order = sortedOrders[index];

                return RetailOrderCard(
                  order: order,
                  // 5. Logic to handle status updates if triggered from the card
                  onUpdateStatus: (newStatus) async {
                    try {
                      await ref
                          .read(wholesaleRetailOrderServiceProvider)
                          .updateOrderStatus(order.orderId, newStatus);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order marked as $newStatus'),
                            backgroundColor: context.colors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: context.colors.error,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
            // IconButton(
            //   onPressed: markAsRecieved,
            //   icon: Icon(Icons.all_inclusive_sharp),
            // ),
          ],
        );
      },
      // 6. Loading State
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      // 7. Error State
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  // Invalidate provider to retry stream connection
                  ref.invalidate(currentRetailOrdersProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
