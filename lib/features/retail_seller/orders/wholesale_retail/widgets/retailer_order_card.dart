// --- Make sure to add these imports ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/product_service_providers.dart';
// Import OrderDetailPage (path from example)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/models/orders/order_model.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/widgets/order/order_details.dart';

class RetailOrderCard extends ConsumerWidget {
  final WholesaleRetailOrder order;
  final Function(String newStatus) onUpdateStatus;

  const RetailOrderCard({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final String? productId = (order.items.isNotEmpty)
        ? order.items.first['productId'] as String?
        : null;

    if (productId == null) {
      return _buildStyledCard(
        context,
        ref,
        textTheme: textTheme,
        title: 'Order ID: ${order.orderId}',
        leading: Icon(
          Icons.receipt_long,
          color: context.colors.primary,
          size: 40,
        ),
      );
    }

    final productAsync = ref.watch(wholesaleProductByIdProvider(productId));

    return productAsync.when(
      data: (product) {
        final title = product?.productName ?? 'Order ID: ${order.orderId}';
        final String? imageUrl =
            (product != null && product.imageUrls.isNotEmpty)
            ? product.imageUrls.first
            : null;

        return _buildStyledCard(
          context,
          ref,
          textTheme: textTheme,
          title: title,
          leading: _buildLeadingImage(context, imageUrl),
        );
      },
      loading: () {
        return _buildStyledCard(
          context,
          ref,
          textTheme: textTheme,
          title: 'Loading product...',
          leading: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        );
      },
      error: (_, __) {
        return _buildStyledCard(
          context,
          ref,
          textTheme: textTheme,
          title: 'Error loading product',
          leading: Icon(
            Icons.receipt_long,
            color: context.colors.error,
            size: 40,
          ),
        );
      },
    );
  }

  // =====================================================================
  // 🔥 Styled card (same style as SellerOrderCard)
  // =====================================================================
  Widget _buildStyledCard(
    BuildContext context,
    WidgetRef ref, {
    required TextTheme textTheme,
    required String title,
    required Widget leading,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderDetailPage(
                  orderId: order.orderId,
                  isWholesaleSeller: false,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT IMAGE
                leading,

                const SizedBox(width: 16),

                // RIGHT SIDE CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Total: ₹${order.totalAmount.toStringAsFixed(2)}",
                        style: textTheme.bodyMedium,
                      ),

                      Text(
                        "Date: ${DateFormat.yMd().format(order.createdAt)}",
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // TRAILING STATUS CHIP
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _chipColor(order.status, context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _chipColor(order.status, context).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _chipColor(order.status, context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.status,
                        style: context.text.labelSmall?.copyWith(
                          color: _chipColor(order.status, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // LEADING IMAGE (unchanged)
  // =====================================================================
  Widget _buildLeadingImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) {
      return Icon(Icons.receipt_long, color: context.colors.primary, size: 40);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.receipt_long,
          color: context.colors.primary,
          size: 40,
        ),
        loadingBuilder: (_, child, loading) {
          if (loading == null) return child;
          return Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
          );
        },
      ),
    );
  }

  Color _chipColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case "received":
        return Colors.green;
      case "delivered":
        return Colors.green;
      case "pending":
        return context.colors.onSurface;
      case "accepted":
        return context.colors.onSurface;
      case "shipped":
        return context.colors.onSurface;
      case "cancelled":
        return context.colors.error;
      default:
        return context.colors.onSurface;
    }
  }
}
