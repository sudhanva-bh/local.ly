import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/features/retail_seller/orders/wholesale_retail/widgets/retail_sales_details_page.dart';

class RetailerSalesOrderCard extends ConsumerWidget {
  final OrderModel order;

  const RetailerSalesOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final currency = NumberFormat.simpleCurrency(locale: 'en_IN');

    // Logic to find a display image from the first item in the order
    // String? firstImageUrl;
    // Assuming OrderModel -> items -> OrderItemModel
    // You might need to adjust based on how you nested the product data in the fetch
    // The provider used: .select('*, order_items(*, retail_products(product_name, image_urls))')
    if (order.items != null && order.items!.isNotEmpty) {
      // In Supabase response, this data might be in a map if not fully deserialized,
      // but assuming OrderItemModel handles it or we access strictly:
      // For this display, we might just use the Generic Icon to save complexity
      // unless OrderItemModel has an imageUrl field.
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        isThreeLine: true,
        // 1. Leading: Visual distinction for "Sale" vs "Purchase"
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                Colors.orange.shade100, // Different color to distinguish Sales
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shopping_bag, color: Colors.orange.shade800),
        ),

        // 2. Title: Customer Name (or ID if name unavailable)
        title: Text(
          "Order #${order.id.substring(0, 8).toUpperCase()}",
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        // 3. Subtitle: Items count and Date
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${order.items?.length ?? 0} items • ${currency.format(order.totalAmount)}",
            ),
            Text(DateFormat.yMd().add_jm().format(order.createdAt)),
          ],
        ),

        // 4. Trailing: Status Chip
        trailing: SizedBox(
          width: 110, // Slightly wider for status text
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusChip(status: order.status),
            ],
          ),
        ),

        onTap: () {
          // Navigate to Detail Page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RetailerSalesOrderDetailPage(order: order),
            ),
          );
        },
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
