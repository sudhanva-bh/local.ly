import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/features/consumer/order/controller/consumer_search_controller.dart';
import 'package:locally/features/consumer/order/widgets/active_filters_list.dart';
import 'package:locally/features/consumer/order/widgets/consumer_search_bar.dart';
import 'package:locally/features/consumer/order/widgets/search_results.dart';

// Helper extension (reused)
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
}

class ConsumerOrderScreen extends ConsumerWidget {
  const ConsumerOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the results here to handle loading/error states at the page level
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
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }
                  return SearchResultsGrid(products: products);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}