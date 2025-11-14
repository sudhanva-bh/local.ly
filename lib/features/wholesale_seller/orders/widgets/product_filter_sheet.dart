// lib/features/wholesale_search/widgets/product_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/search/search_filters.dart';
import 'package:locally/common/providers/wholesale_search_provider.dart';

class ProductFilterSheet extends ConsumerStatefulWidget {
  const ProductFilterSheet({super.key});

  @override
  ConsumerState<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends ConsumerState<ProductFilterSheet> {
  late SearchFilters _localFilters;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize local state from the provider
    _localFilters = ref.read(searchFiltersProvider);
    _minPriceController.text = _localFilters.minPrice?.toString() ?? '';
    _maxPriceController.text = _localFilters.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Update provider state
    ref.read(wholesaleSearchNotifierProvider.notifier).setFilters(_localFilters);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _localFilters = const SearchFilters();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    ref
        .read(wholesaleSearchNotifierProvider.notifier)
        .setFilters(const SearchFilters());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          DropdownButton<ProductCategories>(
            isExpanded: true,
            value: _localFilters.category,
            hint: const Text('Select Category'),
            items: ProductCategories.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(categoryDisplayName(category)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _localFilters = _localFilters.copyWith(category: value, clearCategory: value == null);
              });
            },
          ),
          const SizedBox(height: 20),

          // Price Range
          Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  decoration: const InputDecoration(labelText: 'Min Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _localFilters = _localFilters.copyWith(
                        minPrice: double.tryParse(value));
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  decoration: const InputDecoration(labelText: 'Max Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _localFilters = _localFilters.copyWith(
                        maxPrice: double.tryParse(value));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Min Rating
          Text('Minimum Rating', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            min: 0,
            max: 5,
            divisions: 5,
            label: _localFilters.minRating?.toStringAsFixed(1) ?? 'Any',
            value: _localFilters.minRating ?? 0,
            onChanged: (value) {
              setState(() {
                _localFilters = _localFilters.copyWith(
                    minRating: value == 0 ? null : value);
              });
            },
          ),
          const SizedBox(height: 20),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}