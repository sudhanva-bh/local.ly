import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // Assuming you have this
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/models/orders/order_item_model.dart';
// Import your OrderService provider file
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/common/widgets/order/consumer_order_detail_page.dart';

class ConsumerOrdersPage extends ConsumerWidget {
  const ConsumerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final colors = context.colors; // Your theme extension

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Orders"),
        centerTitle: true,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text("Could not load orders: $err"),
              TextButton(
                onPressed: () => ref.refresh(myOrdersProvider),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text("No orders yet"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Or go to Home
                    child: const Text("Start Shopping"),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myOrdersProvider),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(order: order);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'en_IN');
    final date = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);
    final colors = Theme.of(context).colorScheme;

    // Helper to count total items
    final itemCount =
        order.items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsumerOrderDetailPage(order: order),
            ),
          );
        },
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(order.totalAmount),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                _StatusChip(status: order.status),
              ],
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$itemCount Items",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (order.items != null)
                      ...order.items!.map((item) => _OrderItemRow(item: item)),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItemModel item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // Note: OrderItemModel has 'productName', but mapping complex nested
    // joins (like images) usually requires parsing 'retail_products' manually
    // or updating OrderItemModel to hold an image URL.
    // For now, we list the name and quantity.

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${item.quantity}x",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.productName ?? "Product #${item.productId.substring(0, 4)}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            NumberFormat.simpleCurrency(
              locale: 'en_IN',
            ).format(item.priceAtPurchase * item.quantity),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      ),
    );
  }
}
