import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/consumer/order/controller/consumer_search_controller.dart';
import 'package:locally/features/consumer/order/widgets/active_filters_list.dart';
import 'package:locally/features/consumer/order/widgets/consumer_search_bar.dart';
import 'package:locally/features/consumer/order/widgets/search_results.dart';

// ... imports

class ConsumerOrderScreen extends ConsumerWidget {
  const ConsumerOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SearchHeader(),
            const SizedBox(height: 8),
            const ActiveFiltersList(),
            Expanded(
              child: searchResultsAsync.when(
                // 1. Data Loaded (Page 1+)
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }
                  // Pass the products to our new infinite scroll grid
                  return SearchResultsGrid(products: products);
                },
                
                // 2. Initial Loading (Page 1 only)
                loading: () => const Center(child: CircularProgressIndicator()),
                
                // 3. Error State
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}