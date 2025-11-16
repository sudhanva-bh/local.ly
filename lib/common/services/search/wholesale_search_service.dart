// lib/common/services/wholesale_search_service.dart
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/models/search/search_filters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WholesaleSearchService {
  final SupabaseClient _supabase;
  final int _limit = 20; // Our page size

  WholesaleSearchService(this._supabase);

  /// Search wholesale products using the PostgreSQL function
  Future<List<WholesaleProduct>> searchProducts({
    required double userLat,
    required double userLon,
    required SearchFilters filters,
    required int page, // Page number (1-based)
  }) async {
    try {
      final params = {
        'user_lat': userLat,
        'user_lon': userLon,
        'search_text': filters.searchText,
        
        // Filters
        'category_filter': filters.categories.isNotEmpty
            ? filters.categories.map((c) => c.name).toList()
            : null,
        'min_price_filter': filters.minPrice,
        'max_price_filter': filters.maxPrice,
        'min_rating_filter': filters.minRating,
        'max_distance_filter': filters.maxDistance,
        'min_stock_filter': filters.minStock,
        'max_moq_filter': filters.maxMoq,
        'min_ratings_count_filter': filters.minRatingsCount,
        
        // Sorting & Pagination
        'sort_by': filters.sortBy.value,
        'result_limit': _limit,
        'offset_val': (page - 1) * _limit,
      };

      final response = await _supabase.rpc(
        'search_wholesale_products',
        params: params,
      );

      // response is directly List<dynamic>
      if (response == null) return [];

      final rawList = response as List<dynamic>;

      return rawList.map((item) {
        if (item is Map) {
          return WholesaleProduct.fromMap(
              Map<String, dynamic>.from(item));
        } else {
          throw Exception('Unexpected item type: ${item.runtimeType}');
        }
      }).toList();
    } catch (e) {
      print('WholesaleSearchService error: $e');
      rethrow; // Rethrow to be caught by the Notifier
    }
  }

  int getLimit() => _limit;
}