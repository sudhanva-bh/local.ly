// lib/features/wholesale_search/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';

class ProductCard extends StatelessWidget {
  final WholesaleProduct product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: product.imageUrls.isNotEmpty
              ? Image.network(
                  product.imageUrls.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
        title: Text(
          product.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${categoryDisplayName(ProductCategories.values.firstWhere((c) => c.name == product.category, orElse: () => ProductCategories.other))} • ₹${product.price.toStringAsFixed(2)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            Text(product.averageRating.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}