import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/features/consumer/view_orders/pages/order_details_page.dart';
import 'package:locally/features/consumer/view_orders/widgets/realtime_order_item_row.dart';
import 'package:locally/features/consumer/view_orders/widgets/status_chip.dart';

class OrderExpandableCard extends StatelessWidget {
  final OrderModel order;

  const OrderExpandableCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(order.createdAt);
    final totalStr = NumberFormat.currency(
      symbol: '₹',
    ).format(order.totalAmount);

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.12),
      color: context.colors.surfaceDim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),

          // Header
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order.id.substring(0, 8).toUpperCase()}",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalStr,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Expanded Content
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  if (order.items != null && order.items!.isNotEmpty)
                    ...order.items!.map(
                      (item) => RealtimeOrderItemRow(item: item),
                    )
                  else
                    _buildNoItemsInfo(context),
                  const SizedBox(height: 16),
                  _buildDetailsButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoItemsInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "No items info available",
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.outline,
        ),
      ),
    );
  }

  Widget _buildDetailsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text("View Full Details"),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
