// lib/features/wholesale_search/pages/wholesale_search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/features/wholesale_seller/orders/widgets/product_list.dart';
import 'package:locally/features/wholesale_seller/products/widgets/product_search_bar.dart';

class WholesaleSearchPage extends ConsumerWidget {
  const WholesaleSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wholesale Products')),
      body: const Column(
        children: [
          // 1. Search bar and filter button
          ProductSearchBar(),

          // 2. The list of products
          Expanded(
            child: ProductList(),
          ),
        ],
      ),
    );
  }
}
