import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/features/consumer/order/controller/consumer_search_controller.dart'; // Import the new controller
import 'package:locally/features/consumer/order/widgets/product_grid_card.dart';

class SearchResultsGrid extends ConsumerWidget {
  final List<RetailProduct> products;

  const SearchResultsGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Check if we are 200 pixels from the bottom
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          // Trigger fetch next page
          // We use .read here because we are inside a callback
          ref.read(searchResultsProvider.notifier).fetchNextPage();
        }
        return false; // Allow event to propagate
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return RetailProductGridCard(product: products[index]);
                },
                childCount: products.length,
              ),
            ),
          ),

          // Optional: Bottom Loading Indicator
          // We can check the notifier state to see if we are theoretically fetching more
          // For simplicity, we just add padding at the bottom so the user can scroll
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}
