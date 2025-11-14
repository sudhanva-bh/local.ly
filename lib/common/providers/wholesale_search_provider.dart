// lib/features/wholesale_search/providers/wholesale_search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/models/search/search_filters.dart';
import 'package:locally/common/services/search/wholesale_search_service.dart';


// 1. Provider for the search service
final wholesaleSearchServiceProvider = Provider((ref) {
  return WholesaleSearchService(Supabase.instance.client);
});

// 2. Provider for the filter state
final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters(); // Initial empty filters
});

// 3. State Notifier for managing the product list, pagination, and loading
final wholesaleSearchNotifierProvider = StateNotifierProvider.autoDispose<
    WholesaleSearchNotifier, AsyncValue<List<WholesaleProduct>>>((ref) {
  return WholesaleSearchNotifier(ref);
});

class WholesaleSearchNotifier
    extends StateNotifier<AsyncValue<List<WholesaleProduct>>> {
  final Ref _ref;
  // Note: Pagination is complex. For a search query,
  // it's common to just refetch the list when filters change.
  // We will follow the example's pattern of a single-list FutureProvider.
  // If you need infinite scrolling, the approach would be different.

  WholesaleSearchNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchProducts(); // Initial fetch
  }

  Future<void> _fetchProducts() async {
    // Read the *current* filters
    final filters = _ref.read(searchFiltersProvider);
    final service = _ref.read(wholesaleSearchServiceProvider);

    state = const AsyncValue.loading();

    try {
      final products = await service.searchProducts(
        userLat: 28.6139, // TODO: Replace with dynamic user location
        userLon: 77.2090,
        searchText: filters.searchText,
        category: filters.category,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        minRating: filters.minRating,
        // page: 1 // Pagination logic would go here
      );
      state = AsyncValue.data(products);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Called by the UI to set filters and trigger a refetch
  void setFilters(SearchFilters filters) {
    // Set the new filter state
    _ref.read(searchFiltersProvider.notifier).state = filters;
    // Trigger a new fetch
    _fetchProducts();
  }
  
  // Called by the search bar to update just the text
  void setSearchText(String? text) {
    final currentFilters = _ref.read(searchFiltersProvider);
    _ref.read(searchFiltersProvider.notifier).state =
        currentFilters.copyWith(searchText: text);
    _fetchProducts();
  }
}