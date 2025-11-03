import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/services/supabase_services/supabase_service_search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WholesaleProductService {
  final SupabaseClient _supabase;
  late final SupabaseService _supabaseService;
  static const _tableName = 'wholesale_products';

  WholesaleProductService(this._supabase) {
    _supabaseService = SupabaseService(_supabase);
  }

  /// Fetch all wholesale products (admin/global use)
  Future<List<WholesaleProduct>> fetchAllProducts() async {
    return _supabaseService.fetchFromTable(
      tableName: _tableName,
      fromJson: WholesaleProduct.fromMap,
    );
  }

  /// Fetch products belonging to the current logged-in seller
  Stream<List<WholesaleProduct>> streamProductsForCurrentSeller() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('shop_id', user.id)
        .map(
          (data) => data.map((json) => WholesaleProduct.fromMap(json)).toList(),
        );
  }

  /// Stream of all products for a given shop
  Stream<List<WholesaleProduct>> getProductsByShop(String shopId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('shop_id', shopId)
        .map(
          (data) => data.map((json) => WholesaleProduct.fromMap(json)).toList(),
        );
  }

  /// Add a new product
  Future<Either<String, WholesaleProduct>> addProduct(
    WholesaleProduct product,
  ) async {
    try {
      final result = await _supabase
          .from(_tableName)
          .insert(product.toMap())
          .select()
          .single();

      return Right(WholesaleProduct.fromMap(result));
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Delete a single product by ID
  Future<Either<String, void>> deleteProduct(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('product_id', id);
      return Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Delete all products for a seller (shop)
  Future<void> deleteProductsBySeller(String shopId) async {
    await _supabase.from(_tableName).delete().eq('shop_id', shopId);
  }

  /// Search products using Edge Function
  Future<List<WholesaleProduct>> searchProducts({
    required String query,
    required String searchColumn,
  }) async {
    final params = {
      "query": query,
      "table_name": _tableName,
      "search_column": searchColumn,
    };
    return _supabaseService.invokeFunction(
      functionName: 'search_products',
      params: params,
      fromJson: WholesaleProduct.fromMap,
    );
  }
}
