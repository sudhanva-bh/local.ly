// lib/features/wholesale_search/widgets/product_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/wholesale_search_provider.dart';
import 'package:locally/features/retail_seller/place_orders/widgets/product_card.dart'; // Corrected path

class ProductList extends ConsumerStatefulWidget {
  const ProductList({super.key});

  @override
  ConsumerState<ProductList> createState() => _ProductListState();
}

class _ProductListState extends ConsumerState<ProductList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If we're at the bottom and not loading, fetch more
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !ref.read(wholesaleSearchNotifierProvider).isLoading) {
      final notifier = ref.read(wholesaleSearchNotifierProvider.notifier);
      if (ref.read(wholesaleSearchNotifierProvider).hasMore) {
        notifier.fetchNextPage();
      }
    }
  }

  Future<void> _refresh() async {
    // Invalidate the provider so it reloads the data
    ref.invalidate(wholesaleSearchNotifierProvider);
    // Optionally scroll to top after refresh
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(wholesaleSearchNotifierProvider);
    final products = searchState.products;

    if (products.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty && !searchState.isLoading) {
      return const Center(child: Text('No products found.'));
    }

    if (searchState.error != null && products.isEmpty) {
      return Center(child: Text('Error: ${searchState.error}'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: products.length + (searchState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            // Loading spinner at the bottom
            return searchState.error != null
                ? Center(child: Text('Error: ${searchState.error}'))
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
          }

          final product = products[index];
          return ProductCard(product: product);
        },
      ),
    );
  }
}
