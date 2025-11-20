import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/retail_search_provider.dart';
import 'package:locally/common/services/search/retail_search_service.dart';

// 1. State Notifier to manage the Filters (Query, Category, etc.)
class SearchFilterNotifier extends StateNotifier<SearchFilters> {
  SearchFilterNotifier() : super(const SearchFilters());

  void setQuery(String query) => state = state.copyWith(query: query);
  
  void setCategory(ProductCategories? category) => 
      state = category == state.category 
          ? SearchFilters(query: state.query, sortBy: state.sortBy) // Toggle off
          : state.copyWith(category: category);

  void setPriceRange(double? min, double? max) => 
      state = state.copyWith(minPrice: min, maxPrice: max);

  void setSortBy(SearchSortOption option) => state = state.copyWith(sortBy: option);
  
  void resetFilters() => state = const SearchFilters();
}

final searchFilterProvider = 
    StateNotifierProvider.autoDispose<SearchFilterNotifier, SearchFilters>((ref) {
  return SearchFilterNotifier();
});

// 2. The Search Results Provider
// This watches the filter state AND the user profile (for location)
// and triggers the search service automatically.
final searchResultsProvider = FutureProvider.autoDispose<List<RetailProduct>>((ref) async {
  final filters = ref.watch(searchFilterProvider);
  final searchService = ref.watch(retailSearchServiceProvider);
  
  // Get User Location for "Nearest" sort
  final userProfile = ref.watch(currentConsumerProfileProvider).value;

  // If user wants nearest but has no location, fallback to relevance
  var sortOption = filters.sortBy;
  if (sortOption == SearchSortOption.nearest) {
    if (userProfile?.latitude == null || userProfile?.longitude == null) {
      sortOption = SearchSortOption.relevance;
    }
  }

  // Debounce simple text queries if needed, or rely on UI submission
  // Here we fetch immediately on change
  return searchService.searchProducts(
    query: filters.query,
    minPrice: filters.minPrice,
    maxPrice: filters.maxPrice,
    category: filters.category,
    minRating: filters.minRating,
    userLat: userProfile?.latitude,
    userLon: userProfile?.longitude,
    sortBy: sortOption,
  );
});