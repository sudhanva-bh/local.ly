import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WholesaleSearchService {
  final SupabaseClient _supabase;

  WholesaleSearchService(this._supabase);

  /// Search wholesale products using the PostgreSQL function
  Future<List<WholesaleProduct>> searchProducts({
    required double userLat,
    required double userLon,
    String? searchText,
    ProductCategories? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'search_wholesale_products',
        params: {
          'user_lat': userLat,
          'user_lon': userLon,
          'search_text': searchText,
          'category_filter': category?.name,
          'min_price_filter': minPrice,
          'max_price_filter': maxPrice,
          'min_rating_filter': minRating,
          'result_limit': limit,
        },
      );

      // response is directly List<dynamic>
      if (response == null) return [];

      final rawList = response as List<dynamic>;

      return rawList.map((item) {
        if (item is Map) {
          return WholesaleProduct.fromMap(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>));
        } else {
          throw Exception('Unexpected item type: ${item.runtimeType}');
        }
      }).toList();
    } catch (e) {
      print('WholesaleSearchService error: $e');
      return [];
    }
  }
}
