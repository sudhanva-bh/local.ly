import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/features/retail_seller/products/providers/retail_product_filter_provider.dart';
// Note: You may want to create a retail-specific filter sheet later
// import 'package:locally/features/retail_seller/place_orders/widgets/product_filter_sheet.dart'; 

class RetailProductSearchBar extends ConsumerStatefulWidget {
  const RetailProductSearchBar({super.key});

  @override
  ConsumerState<RetailProductSearchBar> createState() =>
      _RetailProductSearchBarState();
}

class _RetailProductSearchBarState
    extends ConsumerState<RetailProductSearchBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // 👈 Use the retail search provider
    _searchController = TextEditingController(
      text: ref.read(retailSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for external changes (e.g., a "reset" button)
    ref.listen(retailSearchQueryProvider, (previous, next) {
      if (next != _searchController.text) {
        _searchController.text = next;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // 👈 Update the provider on every change for live filtering
                ref.read(retailSearchQueryProvider.notifier).state = value;
              },
              onSubmitted: (value) {
                // 👈 Also update on submit
                ref.read(retailSearchQueryProvider.notifier).state =
                    value.trim();
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
              // TODO: Show a modal bottom sheet for retail filters if needed
              // showModalBottomSheet(
              //   context: context,
              //   builder: (ctx) => const RetailProductFilterSheet(),
              //   isScrollControlled: true,
              // );
            },
          ),
        ],
      ),
    );
  }
}