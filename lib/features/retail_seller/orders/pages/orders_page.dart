import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/orders/order_filter_provider.dart';
import 'package:locally/common/providers/orders/order_providers.dart';
import 'package:locally/common/widgets/order/order_search_bar.dart';
import 'package:locally/common/widgets/order/order_status_filter_bar.dart';
// ✅ 1. Import the provider for the update action
import 'package:locally/common/providers/orders/order_actions_provider.dart';
import 'package:locally/features/retail_seller/orders/widgets/retailer_order_card.dart';

class RetailOrdersPage extends ConsumerWidget {
  const RetailOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(currentRetailOrdersProvider);
    final query = ref.watch(orderSearchQueryProvider);
    final selectedStatus = ref.watch(selectedOrderStatusProvider);

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('My Orders'), // Kept 'My Orders' title for Retail
      ),
      body: Column(
        children: [
          const OrderSearchBar(),
          const OrderStatusFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filtered = orders.where((o) {
                  final matchesQuery = o.orderId
                      .toLowerCase()
                      .contains(query.toLowerCase());
                  final matchesStatus = selectedStatus == null ||
                      o.status.toLowerCase() == selectedStatus.toLowerCase();
                  return matchesQuery && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    // ✅ 2. Pass the onUpdateStatus callback to the RetailOrderCard
                    return RetailOrderCard(
                      order: order,
                      onUpdateStatus: (newStatus) {
                        ref.read(updateOrderStatusProvider)(
                          orderId: order.orderId,
                          newStatus: newStatus,
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}