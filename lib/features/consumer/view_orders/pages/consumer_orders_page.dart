import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/consumer/view_orders/pages/order_details_page.dart';
import 'package:locally/features/consumer/view_orders/widgets/delivery_service.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_expandable_card.dart';

class ConsumerOrdersPage extends ConsumerWidget {
  const ConsumerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text('My Orders', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: const [DeliveryScanAction()],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return _buildEmptyState(context);
          
          return ListView.separated(
            padding: const EdgeInsets.all(16).copyWith(bottom: 160),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              
              // Assuming OrderExpandableCard has an onTap or you wrap it in GestureDetector
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // ⚠️ CHANGE HERE: Passing ID instead of Object
                      builder: (_) => OrderDetailsScreen(orderId: order.id),
                    ),
                  );
                },
                child: OrderExpandableCard(order: order),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(child: Text("No orders yet")); // Simplified for brevity
  }
}