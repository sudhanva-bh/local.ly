// --- Make sure to add these imports ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/models/orders/order_model.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/widgets/order/order_details.dart';

// ✅ Converted to a ConsumerWidget
class WholesaleOrderCard extends ConsumerWidget {
  final WholesaleRetailOrder order;
  final Function(String newStatus) onUpdateStatus;

  const WholesaleOrderCard({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  // ✅ Added WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // 1. Get the productId from the first item
    final String? productId = (order.items.isNotEmpty)
        // ⚠️ ASSUMPTION: The key is 'productId'.
        // If your key is 'product_id', change this line.
        ? order.items.first['productId'] as String?
        : null;

    // 2. If no ID, build with fallback data immediately
    if (productId == null) {
      return _buildCard(
        context,
        textTheme: textTheme,
        title: 'Order ID: ${order.orderId}',
        leading: Icon(
          Icons.receipt_long,
          color: context.colors.primary,
          size: 40,
        ),
      );
    }

    // 3. If ID exists, watch the provider
    final AsyncValue<WholesaleProduct?> productAsync = ref.watch(
      wholesaleProductByIdProvider(productId),
    );

    // 4. Use .when to build the card based on the state
    return productAsync.when(
      data: (product) {
        // Use product name or fallback to Order ID
        final String title =
            product?.productName ?? 'Order ID: ${order.orderId}';
        // Get first image URL or null
        final String? imageUrl =
            (product != null && product.imageUrls.isNotEmpty)
            ? product.imageUrls.first
            : null;

        return _buildCard(
          context,
          textTheme: textTheme,
          title: title,
          leading: _buildLeadingImage(context, imageUrl),
        );
      },
      loading: () {
        // Show a loading state in the card
        return _buildCard(
          context,
          textTheme: textTheme,
          title: 'Loading product...',
          leading: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(12.0),
            child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        );
      },
      error: (err, stack) {
        // Show an error state in the card
        return _buildCard(
          context,
          textTheme: textTheme,
          title: 'Error loading product',
          leading: Icon(
            Icons.receipt_long,
            color: context.colors.error, // Use error color
            size: 40,
          ),
        );
      },
    );
  }

  /// Helper to build the main Card structure
  Widget _buildCard(
    BuildContext context, {
    required TextTheme textTheme,
    required String title,
    required Widget leading,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        isThreeLine: true,
        leading: leading,
        // ✅ TITLE: Shows Product Name (or fallback)
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // ✅ SUBTITLE: Shows Total and Date
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
            Text('Date: ${DateFormat.yMd().format(order.createdAt)}'),
          ],
        ),
        // Trailing section remains the same
        trailing: SizedBox(
          width: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                child: Chip(
                  label: Text(order.status.capitalize()),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: context.colors.primary,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24), // 👈 Rounded chips
                    side: BorderSide(color: context.colors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(
                orderId: order.orderId,
                isWholesaleSeller: true,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Helper just for building the leading image, with fallbacks
  Widget _buildLeadingImage(BuildContext context, String? imageUrl) {
    // Fallback to icon if no image URL
    if (imageUrl == null) {
      return Icon(
        Icons.receipt_long,
        color: context.colors.primary,
        size: 40,
      );
    }

    // Build Image.network if URL exists
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        // Fallback for network error
        errorBuilder: (context, _, __) => Icon(
          Icons.receipt_long,
          color: context.colors.primary,
          size: 40,
        ),
        // Show a loader while image downloads
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(12.0),
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          );
        },
      ),
    );
  }
}
