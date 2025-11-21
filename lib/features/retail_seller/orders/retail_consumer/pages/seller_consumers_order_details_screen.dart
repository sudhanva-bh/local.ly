import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/features/consumer/view_orders/consumer_orders_page.dart';
import 'package:locally/features/retail_seller/orders/retail_consumer/providers/seller_order_service.dart';

class SellerOrderDetailsScreen extends ConsumerWidget {
  final OrderModel order;

  const SellerOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider to get the *latest* version of this specific order
    // in case status changed since entering the screen.
    final latestOrders = ref.watch(sellerOrdersProvider).value;
    final currentOrder =
        latestOrders?.firstWhere(
          (o) => o.id == order.id,
          orElse: () => order,
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
            // 1. Status Tracker (Reuse existing component)
            OrderHeaderCard(
              orderId: currentOrder.id,
              date: DateFormat('MMM dd, yyyy').format(currentOrder.createdAt),
              time: DateFormat('hh:mm a').format(currentOrder.createdAt),
              status: currentOrder.status,
              sellerId: currentOrder.sellerId,
              child: OrderTracker(status: currentOrder.status),
            ),
            const SizedBox(height: 20),

            // 2. Customer / Delivery Info
            SectionLabel(label: "Customer Details"),
            const SizedBox(height: 8),
            AddressCard(address: currentOrder.deliveryAddress),
            // You could add a "Call Customer" button here if you join consumer_profiles
            const SizedBox(height: 24),

            // 3. Items List (Reuse existing logic)
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

            // 4. Financials
            BillSummaryCard(totalAmount: currentOrder.totalAmount),
            const SizedBox(height: 80), // Space for bottom bar
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
    // Define the next logical step based on current status
    final (
      String label,
      IconData icon,
      VoidCallback? action,
      Color? color,
    ) = switch (order.status) {
      OrderStatus.pending => (
        "Accept Order",
        Icons.check,
        () => _update(ref, order.id, OrderStatus.accepted),
        Colors.green, // Accept is usually green
      ),
      OrderStatus.accepted => (
        "Mark as Shipped",
        Icons.local_shipping,
        () => _update(ref, order.id, OrderStatus.shipped),
        context.colors.primary,
      ),
      OrderStatus.shipped => (
        "Mark Delivered",
        Icons.check_circle,
        () => _update(ref, order.id, OrderStatus.delivered),
        Colors.teal,
      ),
      OrderStatus.delivered => (
        "Order Completed",
        Icons.thumb_up,
        null,
        context.colors.outline,
      ),
      OrderStatus.cancelled => (
        "Order Cancelled",
        Icons.block,
        null,
        context.colors.error,
      ),
    };

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: action,
                icon: Icon(icon),
                label: Text(label),
                style: FilledButton.styleFrom(
                  backgroundColor: color ?? context.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Cancel Option (Only show if not delivered or already cancelled)
            if (order.status != OrderStatus.delivered &&
                order.status != OrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Add confirmation dialog logic here
                    _update(ref, order.id, OrderStatus.cancelled);
                  },
                  child: Text(
                    "Cancel Order",
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _update(WidgetRef ref, String orderId, OrderStatus status) {
    ref.read(sellerOrdersProvider.notifier).updateStatus(orderId, status);
  }
}
