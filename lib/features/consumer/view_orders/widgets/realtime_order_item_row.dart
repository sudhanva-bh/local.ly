import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/order_item_model.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/features/consumer/view_product/pages/consumer_view_product.dart';

class RealtimeOrderItemRow extends ConsumerWidget {
  final OrderItemModel item;
  final bool isEmbedded;

  const RealtimeOrderItemRow({
    super.key,
    required this.item,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(retailProductByIdProvider(item.productId));

    return Container(
      margin: isEmbedded ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: isEmbedded
          ? null
          : BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colors.outlineVariant.withOpacity(0.3),
              ),
            ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConsumerViewProduct(productId: item.productId),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: productAsync.when(
                data: (product) {
                  if (product != null && product.imageUrls.isNotEmpty) {
                    return Hero(
                      tag: 'product_img_${item.productId}',
                      child: Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 20),
                      ),
                    );
                  }
                  return Icon(
                    Icons.shopping_bag_outlined,
                    color: context.colors.outline,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Icon(Icons.error_outline, size: 20),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  productAsync.when(
                    data: (product) => Text(
                      product?.name ?? item.productName ?? "Unknown Product",
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Container(
                      height: 14,
                      width: 80,
                      color: context.colors.surfaceContainerHigh,
                    ),
                    error: (_, __) => Text(item.productName ?? "Unknown"),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.quantity} unit(s)",
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}",
                  style: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${item.priceAtPurchase}/ea",
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}