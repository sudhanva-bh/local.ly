// lib/common/models/search_filters.dart
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:flutter/foundation.dart';

@immutable
class SearchFilters {
  final String? searchText;
  final ProductCategories? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  const SearchFilters({
    this.searchText,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  // copyWith method to easily create new instances with updated values
  SearchFilters copyWith({
    String? searchText,
    ProductCategories? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool clearCategory = false, // Add this to allow clearing the category
  }) {
    return SearchFilters(
      searchText: searchText ?? this.searchText,
      category: clearCategory ? null : (category ?? this.category),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchFilters &&
        other.searchText == searchText &&
        other.category == category &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating;
  }

  @override
  int get hashCode {
    return searchText.hashCode ^
        category.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        minRating.hashCode;
  }
}