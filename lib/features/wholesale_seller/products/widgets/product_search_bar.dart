// lib/features/products/widgets/product_search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/wholesale_seller/products/providers/product_filter_provider.dart';

class ProductSearchBar extends ConsumerWidget {
  const ProductSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: context.colors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: context.colors.primary),
          ),
        ),
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
        controller: TextEditingController(text: query),
      ),
    );
  }
}
