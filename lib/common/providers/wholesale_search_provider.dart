// lib/common/providers/wholesale_search_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/models/search/search_filters.dart';
import 'package:locally/common/models/users/seller_model.dart'; // Import Seller
import 'package:locally/common/providers/profile_provider.dart'; // Import profile provider
import 'package:locally/common/services/search/wholesale_search_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provider for the search service
final wholesaleSearchServiceProvider = Provider((ref) {
  return WholesaleSearchService(Supabase.instance.client);
});

// 2. Provider for the filter state
final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters(); // Initial empty filters
});

// 3. State class for the notifier (No changes)
class ProductSearchState {
  final List<WholesaleProduct> products;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final Object? error;

  ProductSearchState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  ProductSearchState copyWith({
    List<WholesaleProduct>? products,
    bool? isLoading,
    bool? hasMore,
    int? page,
    Object? error,
    bool clearError = false,
  }) {
    return ProductSearchState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// 4. State Notifier Provider (UPDATED)
final wholesaleSearchNotifierProvider =
    StateNotifierProvider.autoDispose<
      WholesaleSearchNotifier,
      ProductSearchState
    >((ref) {
      // *** CHANGE ***
      // Watch the current user's profile.
      // This provider will now re-run whenever the user's profile changes.
      final profileAsync = ref.watch(currentUserProfileProvider);

      // Pass the profile's AsyncValue to the notifier
      return WholesaleSearchNotifier(ref, profileAsync);
    });

// 5. State Notifier (UPDATED)
class WholesaleSearchNotifier extends StateNotifier<ProductSearchState> {
  final Ref _ref;
  final AsyncValue<Seller?> _profileAsync; // Store the profile's state
  late final WholesaleSearchService _service;

  // *** CHANGE ***
  // Accept the profile AsyncValue in the constructor
  WholesaleSearchNotifier(this._ref, this._profileAsync)
    : super(ProductSearchState()) {
    _service = _ref.read(wholesaleSearchServiceProvider);

    // Handle the profile state *before* fetching
    _profileAsync.when(
      data: (profile) {
        if (profile == null) {
          state = state.copyWith(isLoading: false, error: "Not logged in.");
        } else if (profile.latitude == null || profile.longitude == null) {
          state = state.copyWith(
            isLoading: false,
            error: "Please update your location in your profile to search.",
          );
        } else {
          // Profile is valid, perform the initial fetch
          _fetchProducts();
        }
      },
      loading: () {
        // Profile is loading, so search is also loading
        state = state.copyWith(isLoading: true);
      },
      error: (e, s) {
        // Error loading profile
        state = state.copyWith(
          isLoading: false,
          error: "Error loading profile: $e",
        );
      },
    );
  }

  Future<void> _fetchProducts() async {
    if (state.isLoading) return;

    // *** CHANGE ***
    // Get the profile from the stored AsyncValue
    final profile = _profileAsync.value;

    // Double-check profile and location before every fetch
    if (profile == null ||
        profile.latitude == null ||
        profile.longitude == null) {
      state = state.copyWith(
        isLoading: false,
        error: "Cannot search: User location is missing from profile.",
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final filters = _ref.read(searchFiltersProvider);
      final newProducts = await _service.searchProducts(
        // *** CHANGE ***
        // Use the dynamic location from the user's profile
        userLat: profile.latitude!,
        userLon: profile.longitude!,
        filters: filters,
        page: state.page,
      );

      final hasMore = newProducts.length == _service.getLimit();

      state = state.copyWith(
        products: [...state.products, ...newProducts],
        isLoading: false,
        hasMore: hasMore,
        page: state.page + 1, // Increment page *after* successful fetch
      );
    } catch (e) {
      print('Error fetching products: $e');
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // Called to fetch the next page (infinite scroll)
  void fetchNextPage() {
    // No changes needed, _fetchProducts() handles the logic
    _fetchProducts();
  }

  // Called when filters are changed
  void setFilters(SearchFilters filters) {
    // Set the new filter state
    _ref.read(searchFiltersProvider.notifier).state = filters;

    // Reset the list and fetch page 1 with new filters
    state = ProductSearchState(page: 1); // Reset state

    // We don't need to re-check the profile here,
    // _fetchProducts() will do it.
    _fetchProducts();
  }

  // Called by the search bar
  void setSearchText(String? text) {
    // No changes needed
    final currentFilters = _ref.read(searchFiltersProvider);
    setFilters(currentFilters.copyWith(searchText: text));
  }
}
