// lib/common/models/search_filters.dart
import 'package:flutter/foundation.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';

/// Enum for all available sorting options from the SQL function
enum SortBy {
  // value: 'default'
  relevance(displayName: 'Relevance', value: 'default'),
  // value: 'distance_asc'
  distance(displayName: 'Distance: Nearest', value: 'distance_asc'),
  // value: 'price_asc'
  priceAsc(displayName: 'Price: Low to High', value: 'price_asc'),
  // value: 'price_desc'
  priceDesc(displayName: 'Price: High to Low', value: 'price_desc'),
  // value: 'rating_desc'
  rating(displayName: 'Rating: High to Low', value: 'rating_desc'),
  // value: 'newest_desc'
  newest(displayName: 'Newest', value: 'newest_desc');

  const SortBy({required this.displayName, required this.value});
  final String displayName;
  final String value;
}

@immutable
class SearchFilters {
  final String? searchText;
  final SortBy sortBy;

  // Filters
  final List<ProductCategories> categories; // Changed to list
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? maxDistance; // NEW: in meters
  final int? minStock; // NEW
  final int? maxMoq; // NEW
  final int? minRatingsCount; // NEW
  // Skipping shop_id and added_since for UI simplicity for now

  const SearchFilters({
    this.searchText,
    this.sortBy = SortBy.relevance,
    this.categories = const [],
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxDistance,
    this.minStock,
    this.maxMoq,
    this.minRatingsCount,
  });

  // copyWith method to easily create new instances with updated values
  SearchFilters copyWith({
    String? searchText,
    SortBy? sortBy,
    List<ProductCategories>? categories,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxDistance,
    int? minStock,
    int? maxMoq,
    int? minRatingsCount,
  }) {
    return SearchFilters(
      searchText: searchText ?? this.searchText,
      sortBy: sortBy ?? this.sortBy,
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      minStock: minStock ?? this.minStock,
      maxMoq: maxMoq ?? this.maxMoq,
      minRatingsCount: minRatingsCount ?? this.minRatingsCount,
    );
  }

  // Helper to reset all filters
  SearchFilters reset() {
    return SearchFilters(
      searchText: searchText, // Keep search text
      sortBy: SortBy.relevance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchFilters &&
        other.searchText == searchText &&
        other.sortBy == sortBy &&
        listEquals(other.categories, categories) &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating &&
        other.maxDistance == maxDistance &&
        other.minStock == minStock &&
        other.maxMoq == maxMoq &&
        other.minRatingsCount == minRatingsCount;
  }

  @override
  int get hashCode {
    return searchText.hashCode ^
        sortBy.hashCode ^
        categories.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        minRating.hashCode ^
        maxDistance.hashCode ^
        minStock.hashCode ^
        maxMoq.hashCode ^
        minRatingsCount.hashCode;
  }
}