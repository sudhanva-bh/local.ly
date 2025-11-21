import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/retail_seller/orders/retail_consumer/pages/sellers_consumers_orders_page.dart';

class SellerOrdersPage extends ConsumerWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚡ WATCH THE STREAM
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      // Wrap in scaffold for background color consistency
      backgroundColor: context.colors.surface,
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState(context, ref);
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
        // 🔴 Error State
        error: (err, stack) => Center(
          child: Text('Error loading orders: $err'),
        ),
        // ⏳ Loading State
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(sellerOrdersProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
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
          ),
        ),
      ),
    );
  }
}
