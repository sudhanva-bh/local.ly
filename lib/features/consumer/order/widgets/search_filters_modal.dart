import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/services/search/retail_search_service.dart';
import 'package:locally/features/consumer/order/controller/consumer_search_controller.dart';

class SearchFiltersModal extends ConsumerWidget {
  const SearchFiltersModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFilterProvider);
    final notifier = ref.read(searchFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: context.text.headlineSmall),
              TextButton(
                onPressed: () {
                  notifier.resetFilters();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text('Sort By', style: context.text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SearchSortOption.values.map((option) {
              final isSelected = filters.sortBy == option;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (val) {
                  if (val) notifier.setSortBy(option);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Text('Category', style: context.text.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ProductCategories.values.length,
              itemBuilder: (context, index) {
                final cat = ProductCategories.values[index];
                final isSelected = filters.category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (_) => notifier.setCategory(cat),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}