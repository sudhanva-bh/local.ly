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
  final _minStockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize local state from the provider
    _localFilters = ref.read(searchFiltersProvider);
    _minPriceController.text = _localFilters.minPrice?.toString() ?? '';
    _maxPriceController.text = _localFilters.maxPrice?.toString() ?? '';
    _minStockController.text = _localFilters.minStock?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Update provider state
    ref.read(wholesaleSearchNotifierProvider.notifier).setFilters(_localFilters);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _localFilters = _localFilters.reset(); // Use new reset method
      _minPriceController.clear();
      _maxPriceController.clear();
      _minStockController.clear();
    });
    // Apply the reset filters
    ref
        .read(wholesaleSearchNotifierProvider.notifier)
        .setFilters(_localFilters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding to push content above the keyboard
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters & Sort',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Sort By ---
            Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
            DropdownButton<SortBy>(
              isExpanded: true,
              value: _localFilters.sortBy,
              items: SortBy.values.map((sort) {
                return DropdownMenuItem(
                  value: sort,
                  child: Text(sort.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _localFilters = _localFilters.copyWith(sortBy: value);
                });
              },
            ),
            const SizedBox(height: 20),

            // --- Categories ---
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: ProductCategories.values.map((category) {
                final isSelected = _localFilters.categories.contains(category);
                return FilterChip(
                  label: Text(categoryDisplayName(category)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      var currentCategories =
                          List<ProductCategories>.from(_localFilters.categories);
                      if (selected) {
                        currentCategories.add(category);
                      } else {
                        currentCategories.remove(category);
                      }
                      _localFilters =
                          _localFilters.copyWith(categories: currentCategories);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // --- Max Distance ---
            Text('Distance (km)', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 0,
              max: 100, // 100km
              divisions: 20,
              label: (_localFilters.maxDistance == null ||
                      _localFilters.maxDistance == 100000)
                  ? 'Any'
                  : '${(_localFilters.maxDistance! / 1000).toStringAsFixed(0)} km',
              value: (_localFilters.maxDistance ?? 100000) / 1000,
              onChanged: (value) {
                setState(() {
                  if (value == 100) { // 'Any'
                    _localFilters = _localFilters.copyWith(maxDistance: null);
                  } else {
                    _localFilters =
                        _localFilters.copyWith(maxDistance: value * 1000);
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            // --- Price Range ---
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

            // --- Min Rating ---
            Text('Minimum Rating',
                style: Theme.of(context).textTheme.titleMedium),
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

            // --- Min Stock ---
            Text('Minimum Stock',
                style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: _minStockController,
              decoration: const InputDecoration(labelText: 'e.g., 10'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _localFilters =
                    _localFilters.copyWith(minStock: int.tryParse(value));
              },
            ),
            const SizedBox(height: 20),

            // --- Apply Button ---
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _applyFilters,
                child: const Text('Apply'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}