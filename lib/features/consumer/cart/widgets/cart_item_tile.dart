import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/models/cart/cart_item_model.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';
import 'package:locally/features/consumer/view_product/pages/consumer_view_product.dart';

class CartItemTile extends ConsumerWidget {
  final CartItemModel item;
  final NumberFormat currencyFormat;

  const CartItemTile({
    super.key,
    required this.item,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final product = item.product;

    // Fallback if product details failed to load or were deleted
    if (product == null) {
      return ListTile(
        title: const Text("Product unavailable"),
        subtitle: const Text("This item may have been removed."),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => ref
              .read(cartControllerProvider.notifier)
              .removeItem(item.productId),
        ),
      );
    }

    final firstImage = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : null;
    final price = product.discountedPrice ?? product.price;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) =>
              ConsumerViewProduct(productId: product.productId),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Thumbnail
            Hero(
              tag: "product_img_${product.productId}",
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  image: firstImage != null
                      ? DecorationImage(
                          image: NetworkImage(firstImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: firstImage == null
                    ? Icon(
                        Icons.image_not_supported_outlined,
                        color: colors.outline,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(price),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Column
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Increment
                      InkWell(
                        onTap: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(
                                item.productId,
                                item.quantity + 1,
                              );
                        },
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: colors.onSurface,
                          ),
                        ),
                      ),

                      // Count
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          "${item.quantity}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Decrement
                      InkWell(
                        onTap: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .updateQuantity(
                                item.productId,
                                item.quantity - 1,
                              );
                        },
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
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
