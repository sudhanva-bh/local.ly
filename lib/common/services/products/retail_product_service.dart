import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/products/wholesale/retail_product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RetailProductService {
  final SupabaseClient _supabase;
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
}