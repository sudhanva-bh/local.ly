import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/features/retail_seller/orders/wholesale_retail/providers/order_providers.dart';
// import 'package:locally/features/retail_seller/orders/providers/order_providers.dart';

class RetailerSalesOrderDetailPage extends ConsumerWidget {
  final OrderModel order;

  const RetailerSalesOrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: context.colors.surface, // Adapts to dark/light mode
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER CARD
            _buildHeaderCard(context, dateFormat),
            const SizedBox(height: 24),

            // 2. ITEMS
            Text(
              "Items",
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildItemsList(context, currencyFormat),
            const SizedBox(height: 24),

            // 3. FINANCIAL SUMMARY
            _buildFinancialCard(context, currencyFormat),
            const SizedBox(height: 24),

            // 4. SHIPPING
            _buildShippingCard(context),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, ref),
    );
  }

  // ---------------------------------------------------------------------------
  // UI SECTIONS
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(BuildContext context, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context
            .colors
            .surfaceContainerLow, // Slightly distinct from background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order #${order.id.substring(0, 8).toUpperCase()}",
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(order.createdAt),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(context, order.status),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, NumberFormat currencyFormat) {
    final items = order.items ?? [];

    if (items.isEmpty) {
      return Center(
        child: Text(
          "No items in this order.",
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Row(
            children: [
              // Placeholder Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: context.colors.onSecondaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? "Unknown Product",
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item.quantity} x ${currencyFormat.format(item.priceAtPurchase)}",
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(item.quantity * item.priceAtPurchase),
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            context,
            "Subtotal",
            currencyFormat.format(order.totalAmount),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: context.colors.outlineVariant),
          ),
          _buildSummaryRow(
            context,
            "Total Amount",
            currencyFormat.format(order.totalAmount),
            isBold: true,
            fontSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: isBold
                ? context.colors.onSurface
                : context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Delivery Address",
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.deliveryAddress,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomAction(BuildContext context, WidgetRef ref) {
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return null;
    }

    final actionText = _getNextActionText(order.status);
    final isDestructive = order.status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: context.colors.shadow.withOpacity(0.1),
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton(
          onPressed: () => _advanceStatus(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive
                ? context.colors.error
                : context.colors.primary,
            foregroundColor: isDestructive
                ? context.colors.onError
                : context.colors.onPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS & BADGES
  // ---------------------------------------------------------------------------

  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
    Color containerColor;
    Color onContainerColor;
    String text = status.name.toUpperCase();

    // Mapping Status to Material 3 Semantics
    switch (status) {
      case OrderStatus.pending:
        // Use Secondary (often neutral/calm) or Tertiary (often warmer)
        containerColor = context.colors.secondaryContainer;
        onContainerColor = context.colors.onSecondaryContainer;
        break;
      case OrderStatus.accepted:
        // Use Primary Container
        containerColor = context.colors.primaryContainer;
        onContainerColor = context.colors.onPrimaryContainer;
        break;
      case OrderStatus.shipped:
        // Use Tertiary Container (Distinct from Accepted)
        containerColor = context.colors.tertiaryContainer;
        onContainerColor = context.colors.onTertiaryContainer;
        break;
      case OrderStatus.delivered:
        // Use Primary (Strong confirmation)
        containerColor = context.colors.primary;
        onContainerColor = context.colors.onPrimary;
        break;
      case OrderStatus.cancelled:
        // Use Error Container
        containerColor = context.colors.errorContainer;
        onContainerColor = context.colors.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: context.text.labelSmall?.copyWith(
          color: onContainerColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getNextActionText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "Accept Order";
      case OrderStatus.accepted:
        return "Mark as Shipped";
      case OrderStatus.shipped:
        return "Mark as Delivered";
      default:
        return "Close";
    }
  }

  void _advanceStatus(BuildContext context, WidgetRef ref) {
    String nextStatus;
    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = 'accepted';
        break;
      case OrderStatus.accepted:
        nextStatus = 'shipped';
        break;
      case OrderStatus.shipped:
        nextStatus = 'delivered';
        break;
      default:
        return;
    }

    print("${order.id} $nextStatus");

    ref.read(updateConsumerOrderStatusProvider)(
      orderId: order.id,
      newStatus: nextStatus,
    );

    Navigator.pop(context);
  }
}
