// lib/features/wholesale_search/widgets/product_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/wholesale_search_provider.dart';
import 'package:locally/features/wholesale_seller/products/widgets/product_card.dart';

class ProductList extends ConsumerWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the main provider
    final productsAsync = ref.watch(wholesaleSearchNotifierProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No products found.'));
        }
        
        // Use ListView.builder to render the list
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}