import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // Your theme extension
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/consumer/view_orders/consumer_orders_page.dart';
import 'package:locally/features/retail_seller/orders/retail_consumer/pages/seller_consumers_order_details_screen.dart';
// ⬇️ Make sure to import the file where you defined the 'sellerOrdersProvider' and 'orderServiceProvider'
import 'package:locally/features/retail_seller/orders/retail_consumer/providers/seller_order_service.dart'; 

class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚡ WATCH THE STREAM: This rebuilds automatically when DB changes
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Container(
      color: context.colors.surface,
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return RefreshIndicator(
              // Even with streams, a manual refresh is sometimes nice to have
              onRefresh: () => ref.refresh(sellerOrdersProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(context),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return SellerOrderCard(order: orders[index]);
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 64,
            color: context.colors.outline,
          ),
          const SizedBox(height: 16),
          Text("No consumer orders", style: context.text.headlineSmall),
          Text(
            "Wait for customers to place orders.",
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🃏 WIDGET: SELLER ORDER CARD
// -----------------------------------------------------------------------------
class SellerOrderCard extends ConsumerWidget {
  final OrderModel order;

  const SellerOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MMM dd • hh:mm a').format(order.createdAt);
    final totalStr = NumberFormat.currency(symbol: '₹').format(order.totalAmount);
    final itemCount = order.items?.length ?? 0;

    return Card(
      elevation: 0,
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerOrderDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${order.id.substring(0, 8).toUpperCase()}",
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Assuming you have a StatusChip widget. If not, use a Chip or Text.
                  StatusChip(status: order.status), 
                ],
              ),
              const SizedBox(height: 12),

              // Info Row: Items + Total
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$itemCount items",
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    totalStr,
                    style: context.text.titleMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateStr, style: context.text.bodySmall),

              // Actions Divider
              if (order.status == OrderStatus.pending) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Implement Shipping Label Logic
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.primary,
                          side: BorderSide(
                            color: context.colors.primary.withOpacity(0.5),
                          ),
                        ),
                        child: const Text("Shipping Label"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // ⚡ ACTION: Call the service
                          await ref.read(orderServiceProvider).receiveOrder(order.id);
                          // No need to refresh manually; the Stream will update the UI!
                        },
                        child: const Text("Accept Order"),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}