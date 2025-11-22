import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/retail_search_provider.dart';
import 'package:locally/common/services/search/retail_search_service.dart';

// -----------------------------------------------------------------------------
// 1. Filter Notifier (Unchanged)
// -----------------------------------------------------------------------------
class SearchFilterNotifier extends StateNotifier<SearchFilters> {
  SearchFilterNotifier() : super(const SearchFilters());

  void setQuery(String query) => state = state.copyWith(query: query);
  
  void setCategory(ProductCategories? category) => 
      state = category == state.category 
          ? SearchFilters(query: state.query, sortBy: state.sortBy)
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

// -----------------------------------------------------------------------------
// 2. Pagination Notifier (New Implementation)
// -----------------------------------------------------------------------------

class SearchResultsNotifier extends StateNotifier<AsyncValue<List<RetailProduct>>> {
  final RetailSearchService _searchService;
  final SearchFilters _filters;
  final double? _userLat;
  final double? _userLon;
  
  // Pagination State
  int _offset = 0;
  final int _limit = 20; // Matches the default in your SQL
  bool _hasMore = true;
  bool _isLoadingNext = false;

  SearchResultsNotifier({
    required RetailSearchService searchService,
    required SearchFilters filters,
    double? userLat,
    double? userLon,
  })  : _searchService = searchService,
        _filters = filters,
        _userLat = userLat,
        _userLon = userLon,
        super(const AsyncValue.loading()) {
    // Fetch first page immediately upon creation
    fetchFirstPage();
  }

  // Used for the initial load (and when filters change)
  Future<void> fetchFirstPage() async {
    state = const AsyncValue.loading();
    _offset = 0;
    _hasMore = true;

    try {
      final products = await _performSearch(offset: 0);
      if (mounted) {
        // If we got fewer items than the limit, we've reached the end
        if (products.length < _limit) _hasMore = false;
        state = AsyncValue.data(products);
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  // Used for Infinite Scroll
  Future<void> fetchNextPage() async {
    // Prevent multiple calls or calls when no data left
    if (_isLoadingNext || !_hasMore || state.value == null) return;

    _isLoadingNext = true;
    
    try {
      // Calculate next offset
      _offset += _limit;
      
      final newProducts = await _performSearch(offset: _offset);
      
      if (newProducts.length < _limit) _hasMore = false;

      if (mounted) {
        // Append new products to the existing list
        final currentList = state.value!;
        state = AsyncValue.data([...currentList, ...newProducts]);
      }
    } catch (e) {
      // If pagination fails, we usually just don't load more, 
      // or show a snackbar, rather than replacing the whole screen with Error.
      // We decrease the offset so they can try again.
      _offset -= _limit; 
    } finally {
      _isLoadingNext = false;
    }
  }

  Future<List<RetailProduct>> _performSearch({required int offset}) {
    // Determine Sort Option logic (fallback to relevance if location missing for nearest)
    var sortOption = _filters.sortBy;
    if (sortOption == SearchSortOption.nearest) {
      if (_userLat == null || _userLon == null) {
        sortOption = SearchSortOption.relevance;
      }
    }

    return _searchService.searchProducts(
      query: _filters.query,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      category: _filters.category,
      minRating: _filters.minRating,
      userLat: _userLat,
      userLon: _userLon,
      sortBy: sortOption,
      limit: _limit,
      offset: offset,
    );
  }
  
  bool get hasMore => _hasMore;
}

// The Provider
final searchResultsProvider = StateNotifierProvider.autoDispose<SearchResultsNotifier, AsyncValue<List<RetailProduct>>>((ref) {
  final filters = ref.watch(searchFilterProvider);
  final searchService = ref.watch(retailSearchServiceProvider);
  final userProfile = ref.watch(currentConsumerProfileProvider).value;

  // Whenever filters change, this provider is re-built, 
  // creating a new Notifier which calls fetchFirstPage() automatically.
  return SearchResultsNotifier(
    searchService: searchService,
    filters: filters,
    userLat: userProfile?.latitude,
    userLon: userProfile?.longitude,
  );
});