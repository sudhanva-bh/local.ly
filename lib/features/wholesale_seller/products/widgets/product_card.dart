// lib/features/products/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // for context.colors
import 'package:locally/common/models/products/wholesale_product_model.dart';
import 'package:locally/features/wholesale_seller/products/pages/view_product.dart';

class ProductCard extends StatelessWidget {
  final WholesaleProduct product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image = (product.imageUrls.isNotEmpty)
        ? product.imageUrls.first
        : 'https://via.placeholder.com/150';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: colors.primary.withOpacity(0.1),
        highlightColor: colors.primary.withOpacity(0.05),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProduct(
                productId: product.productId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: context
                          .colors
                          .surfaceContainerHighest, // optional background
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: context.colors.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Category
                    Text(
                      product.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price + Stock
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '• Stock: ${product.stock}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Min Order Quantity (optional)
                    if (product.minOrderQuantity > 1)
                      Text(
                        'Min order: ${product.minOrderQuantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
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
