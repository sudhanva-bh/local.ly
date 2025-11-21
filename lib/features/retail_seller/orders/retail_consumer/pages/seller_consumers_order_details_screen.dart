import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
// ⬇️ Import these providers
import 'package:locally/features/retail_seller/orders/retail_consumer/providers/seller_order_service.dart';
// ⬇️ Import your UI components (Adjust paths as needed)
import 'package:locally/features/consumer/view_orders/consumer_orders_page.dart'; // Assuming OrderHeaderCard etc are here

class SellerOrderDetailsScreen extends ConsumerWidget {
  final OrderModel order;

  const SellerOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ---------------------------------------------------------
    // ⚡ READ LIVE ORDERS FROM sellerOrdersProvider
    // ---------------------------------------------------------
    // We watch the entire list stream. It's efficient enough for local state.
    final asyncOrders = ref.watch(sellerOrdersProvider);
    final latestOrders = asyncOrders.value;

    // Find updated version of this order (if available in the stream)
    final currentOrder =
        latestOrders?.firstWhere(
          (o) => o.id == order.id,
          orElse: () =>
              order, // Fallback to the passed object if stream is loading/empty
        ) ??
        order;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text("Manage Order"),
        centerTitle: true,
        backgroundColor: context.colors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderHeaderCard(
              orderId: currentOrder.id,
              date: DateFormat('MMM dd, yyyy').format(currentOrder.createdAt),
              time: DateFormat('hh:mm a').format(currentOrder.createdAt),
              status: currentOrder.status,
              sellerId: currentOrder.sellerId,
              child: OrderTracker(status: currentOrder.status),
            ),
            const SizedBox(height: 20),

            SectionLabel(label: "Customer Details"),
            const SizedBox(height: 8),
            AddressCard(address: currentOrder.deliveryAddress),
            const SizedBox(height: 24),

            SectionLabel(label: "Items to Pack"),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  if (currentOrder.items != null)
                    ...currentOrder.items!.map(
                      (item) => RealtimeOrderItemRow(
                        item: item,
                        isEmbedded: true,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            BillSummaryCard(totalAmount: currentOrder.totalAmount),
            const SizedBox(height: 80),
          ],
        ),
      ),

      bottomNavigationBar: _buildManagementBar(context, ref, currentOrder),
    );
  }

  Widget _buildManagementBar(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    // If the order is completed/cancelled, you might want to hide this bar or show "Archived"
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // -------------------- SHIPPING LABEL BUTTON --------------------
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement Printing Logic
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text("Shipping Label"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // -------------------- DYNAMIC ACTION BUTTON --------------------
            if (order.status == OrderStatus.pending)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    // ⚡ TRIGGER REALTIME UPDATE
                    await ref.read(orderServiceProvider).receiveOrder(order.id);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Accept Order"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else if (order.status == OrderStatus.pending)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    // ⚡ TRIGGER SHIPMENT
                    // Note: Ensure you have this method in your service
                    await ref
                        .read(orderServiceProvider)
                        .receiveShipment(order.id, order.sellerId);
                  },
                  icon: const Icon(Icons.local_shipping),
                  label: const Text("Mark Shipped"),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primaryContainer,
                    foregroundColor: context.colors.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
