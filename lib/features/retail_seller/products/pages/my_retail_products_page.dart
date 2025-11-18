import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/product_service_providers.dart'; // 👈 Has retail providers
import 'package:locally/features/retail_seller/products/providers/retail_product_filter_provider.dart'; // 👈 Updated import
import 'package:locally/features/retail_seller/products/widgets/retail_category_filter_bar.dart'; // 👈 Updated import
import 'package:locally/features/retail_seller/products/widgets/retail_product_card.dart';
import 'package:locally/features/retail_seller/products/widgets/retail_product_search_bar.dart'; // 👈 Updated import

class MyRetailProductsPage extends ConsumerWidget {
  const MyRetailProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 👈 Use retail providers
    final productsAsync = ref.watch(userRetailProductsProvider);
    final query = ref.watch(retailSearchQueryProvider);
    final selectedCategory = ref.watch(retailSelectedCategoryProvider);

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('My Retail Products'),
      ),
      body: Column(
        children: [
          const RetailProductSearchBar(), // 👈 Use retail widget
          const RetailCategoryFilterBar(), // 👈 Use retail widget
          const SizedBox(height: 8),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                // Apply filters
                final filtered = products.where((p) {
                  final matchesQuery = p.name.toLowerCase().contains(
                        query.toLowerCase(),
                      );
                  final matchesCategory = selectedCategory == null ||
                      p.category == selectedCategory; // 👈 Use enum directly
                  return matchesQuery && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      RetailProductCard(product: filtered[index]), // 👈 Use retail widget
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