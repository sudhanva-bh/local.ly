// lib/features/wholesale_search/widgets/product_search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/wholesale_search_provider.dart';
// Corrected import path:
import 'package:locally/features/retail_seller/place_orders/widgets/product_filter_sheet.dart';

// 1. Convert to ConsumerStatefulWidget
class ProductSearchBar extends ConsumerStatefulWidget {
  const ProductSearchBar({super.key});

  @override
  ConsumerState<ProductSearchBar> createState() => _ProductSearchBarState();
}

// 2. Create the State class
class _ProductSearchBarState extends ConsumerState<ProductSearchBar> {
  // 3. Create the controller as a state variable
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // 4. Initialize the controller *once* with the provider's current value
    _searchController = TextEditingController(
      text: ref.read(searchFiltersProvider).searchText,
    );
  }

  @override
  void dispose() {
    // 5. Dispose of the controller when the widget is removed
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 6. Listen for *external* changes to the filter provider
    // (e.g., if the user hits "Reset" in the filter sheet)
    ref.listen(searchFiltersProvider.select((filters) => filters.searchText),
        (previous, next) {
      // If the provider's text changes and it's different from the
      // controller's text, update the controller.
      if (next != _searchController.text) {
        _searchController.text = next ?? '';
      }
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              // 7. Use the persistent controller
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                ref
                    .read(wholesaleSearchNotifierProvider.notifier)
                    .setSearchText(value.trim().isEmpty ? null : value.trim());
              },
            ),
          ),
          const SizedBox(width: 8),

          // Filter Button
          IconButton.filled(
            icon: const Icon(Icons.filter_list),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: () {
              // Show the modal bottom sheet
              showModalBottomSheet(
                context: context,
                builder: (ctx) => const ProductFilterSheet(),
                isScrollControlled: true,
              );
            },
          ),
        ],
      ),
    );
  }
}