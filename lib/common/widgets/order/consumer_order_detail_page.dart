import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/models/orders/order_item_model.dart';

// Status constants for the tracker
const List<OrderStatus> _trackerStatuses = [
  OrderStatus.pending,
  OrderStatus.accepted,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

class ConsumerOrderDetailPage extends ConsumerWidget {
  final OrderModel order;

  const ConsumerOrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.simpleCurrency(locale: 'en_IN');
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 1: Order Tracker & Status ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.numbers,
                      title: "Order ID",
                      value: "#${order.id.substring(0, 8).toUpperCase()}",
                    ),
                    const SizedBox(height: 16),
                    const Text("Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _OrderTracker(currentStatus: order.status),
                    const Divider(height: 32),
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today,
                      title: "Date Placed",
                      value: DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Section 2: Items ---
            Text("Items", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items?.length ?? 0,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = order.items![index];
                  return _ConsumerOrderItemTile(item: item);
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- Section 3: Address & Payment ---
            Text("Delivery Details", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_outlined,
                      title: "Delivery Address",
                      value: order.deliveryAddress,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      icon: Icons.payment_outlined,
                      title: "Total Amount",
                      value: currency.format(order.totalAmount),
                      valueStyle: textTheme.titleLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Section 4: Actions (Cancel only if Pending) ---
            if (order.status == OrderStatus.pending)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text("Cancel Order"),
                  onPressed: () => _showCancelConfirmationDialog(context, ref),
                ),
              ),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              // Implement Cancel Logic via Supabase
              // For now, we can just assume the service exists or simulate it
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Requesting cancellation...")),
              );
              // Typically you'd call ref.read(orderServiceProvider).cancelOrder(order.id)
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: valueStyle ?? Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// --- VISUAL COMPONENTS ---

class _ConsumerOrderItemTile extends StatelessWidget {
  final OrderItemModel item;
  const _ConsumerOrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'en_IN');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
      ),
      title: Text(
        item.productName ?? "Product ID: ${item.productId}",
        maxLines: 1, 
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text("Qty: ${item.quantity}"),
      trailing: Text(
        currency.format(item.priceAtPurchase * item.quantity),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OrderTracker extends StatelessWidget {
  final OrderStatus currentStatus;

  const _OrderTracker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: colors.error),
            const SizedBox(width: 12),
            Text(
              "This order has been Cancelled",
              style: TextStyle(color: colors.error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Determine active step index
    int currentIndex = _trackerStatuses.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0; 

    return Row(
      children: [
        _TrackerStep(
          icon: Icons.receipt_long,
          title: "Pending",
          isActive: currentIndex >= 0,
          isLast: false,
        ),
        _TrackerStep(
          icon: Icons.check_circle_outline,
          title: "Accepted",
          isActive: currentIndex >= 1,
          isLast: false,
        ),
        _TrackerStep(
          icon: Icons.local_shipping_outlined,
          title: "Shipped",
          isActive: currentIndex >= 2,
          isLast: false,
        ),
        _TrackerStep(
          icon: Icons.home_outlined,
          title: "Delivered",
          isActive: currentIndex >= 3,
          isLast: true,
        ),
      ],
    );
  }
}

class _TrackerStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool isLast;

  const _TrackerStep({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade400;

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: isLast ? Colors.transparent : (isActive ? color : Colors.grey.shade300),
                  margin: const EdgeInsets.only(right: 4), // visual fix
                ),
              ),
              Icon(icon, color: color, size: 24),
              Expanded(
                child: Container(
                  height: 2,
                  color: isLast ? Colors.transparent : (isActive ? color : Colors.grey.shade300),
                   margin: const EdgeInsets.only(left: 4), // visual fix
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10, 
              color: color, 
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}