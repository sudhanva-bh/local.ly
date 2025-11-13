// lib/features/products/pages/my_products_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/features/wholesale_seller/products/providers/product_filter_provider.dart';
import 'package:locally/features/wholesale_seller/products/widgets/category_filter_bar.dart';
import 'package:locally/features/wholesale_seller/products/widgets/product_card.dart';
import 'package:locally/features/wholesale_seller/products/widgets/product_search_bar.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(userWholesaleProductsProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('My Products'),
      ),
      body: Column(
        children: [
          const ProductSearchBar(),
          const CategoryFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                // Apply filters
                final filtered = products.where((p) {
                  final matchesQuery = p.productName.toLowerCase().contains(
                    query.toLowerCase(),
                  );
                  final matchesCategory =
                      selectedCategory == null ||
                      p.category.toLowerCase() ==
                          categoryDisplayName(selectedCategory).toLowerCase();
                  return matchesQuery && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      ProductCard(product: filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
