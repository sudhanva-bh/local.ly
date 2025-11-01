import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/products/wholesale/retail_product_model.dart';
import 'package:locally/common/services/supabase_services/supabase_service_search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RetailProductService {
  final SupabaseClient _supabase;
  late SupabaseService _supabaseService;
  static const _tableName = 'retail_products';

  RetailProductService(this._supabase); // ✅ Only one positional arg

  Future<Either<String, void>> addProduct(RetailProduct product) async {
    try {
      await _supabase.from(_tableName).insert(product.toMap());
      return Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, void>> deleteProduct(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);
      return Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> deleteProductsBySeller(String sellerId) async {
    await _supabase.from(_tableName).delete().eq('seller_id', sellerId);
  }

  /// ✅ Stream of all products for a given shop (user)
  Stream<List<RetailProduct>> getProductsByShop(String shopId) {
    final stream = _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('shop_id', shopId);

    return stream.map(
      (data) => data.map((json) => RetailProduct.fromMap(json)).toList(),
    );
  }

  /// Search products using the Edge Function
  Future<List<RetailProduct>> searchProducts({
    required String query,
    required String searchColumn,
  }) async {
    _supabaseService = SupabaseService(_supabase);
    final params = {
      "query": query,
      "table_name": _tableName,
      "search_column": searchColumn,
    };

    // Debug: print what we’re sending
    print("🧾 Sending search params: $params");

    return _supabaseService.invokeFunction(
      functionName: 'search_products',
      params: params,
      fromJson: RetailProduct.fromJson,
    );
  }
}