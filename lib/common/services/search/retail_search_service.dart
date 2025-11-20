import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// 🛠️ Service Definition
// -----------------------------------------------------------------------------

class RetailSearchService {
  final SupabaseClient _supabase;

  RetailSearchService(this._supabase);

  Future<List<RetailProduct>> searchProducts({
    required String query,
    double? minPrice,
    double? maxPrice,
    ProductCategories? category,
    double? minRating,
    double? userLat,
    double? userLon,
    SearchSortOption sortBy = SearchSortOption.relevance,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = {
        'search_term': query,
        'min_price': minPrice,
        'max_price': maxPrice,
        'category_filter': category?.name, // Matches DB text column
        'min_rating': minRating,
        'user_lat': userLat,
        'user_lon': userLon,
        'sort_by': sortBy.value,
        'limit_val': limit,
        'offset_val': offset,
      };

      // Remove nulls to let RPC defaults take over
      params.removeWhere((key, value) => value == null);

      final List<dynamic> response = await _supabase.rpc(
        'search_retail_products',
        params: params,
      );

      return response.map((e) => RetailProduct.fromMap(e)).toList();
    } catch (e) {
      // Log error or rethrow
      rethrow;
    }
  }
}

// -----------------------------------------------------------------------------
// 🗂️ Enums & Helper Classes
// -----------------------------------------------------------------------------

enum SearchSortOption {
  relevance('relevance', 'Relevance'),
  nearest('nearest', 'Nearest to Me'),
  priceLowHigh('price_asc', 'Price: Low to High'),
  priceHighLow('price_desc', 'Price: High to Low'),
  newest('newest', 'Newest Arrivals'),
  rating('rating', 'Top Rated');

  final String value; // Passed to SQL
  final String label; // UI Label
  const SearchSortOption(this.value, this.label);
}

class SearchFilters {
  final String query;
  final double? minPrice;
  final double? maxPrice;
  final ProductCategories? category;
  final double? minRating;
  final SearchSortOption sortBy;

  const SearchFilters({
    this.query = '',
    this.minPrice,
    this.maxPrice,
    this.category,
    this.minRating,
    this.sortBy = SearchSortOption.relevance,
  });

  SearchFilters copyWith({
    String? query,
    double? minPrice,
    double? maxPrice,
    ProductCategories? category,
    double? minRating,
    SearchSortOption? sortBy,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      category: category ?? this.category,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
