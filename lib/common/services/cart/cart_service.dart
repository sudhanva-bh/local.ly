import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locally/common/models/cart/cart_item_model.dart';

class CartService {
  final SupabaseClient _supabase;
  static const String _tableName = 'cart_items';
  static const String _productsTable =
      'retail_products'; // Change to your actual products table name

  CartService(this._supabase);

  /// GET CART
  /// Fetches items and manually joins the Product details
  Future<Either<String, List<CartItemModel>>> getCart(String userId) async {
    try {
      // 1. Get all cart items for user
      final List<Map<String, dynamic>> cartData = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at');

      if (cartData.isEmpty) return const Right([]);

      // 2. Extract Product IDs
      final productIds = cartData
          .map((e) => e['product_id'] as String)
          .toList();

      // Guard clause: If no items in cart, return early to avoid query errors
      if (productIds.isEmpty) {
        return const Right([]);
      }

      // 3. Fetch Product Details
      final List<Map<String, dynamic>> productsData = await _supabase
          .from(_productsTable)
          .select()
          // FIX: Use .filter() instead of .in_()
          .filter('product_id', 'in', productIds);

      final productsMap = {
        for (var p in productsData)
          p['product_id'].toString(): RetailProduct.fromMap(p),
      };

      // 4. Merge Cart Item with Product Data
      final List<CartItemModel> fullCart = cartData.map((itemMap) {
        final item = CartItemModel.fromMap(itemMap);
        return item.copyWith(product: productsMap[item.productId]);
      }).toList();

      return Right(fullCart);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// ADD / UPDATE ITEM
  /// Upserts: If item exists, update quantity. If not, insert.
  Future<Either<String, void>> addToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      // We use upsert. If (user_id, product_id) exists, we update.
      // However, standard upsert replaces. To increment, we usually verify existence first.

      // Simple approach: specific upsert logic
      final existingResponse = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingResponse != null) {
        // Item exists, increment quantity
        final currentQty = existingResponse['quantity'] as int;
        await _supabase
            .from(_tableName)
            .update({'quantity': currentQty + quantity})
            .match({'user_id': userId, 'product_id': productId});
      } else {
        // Item does not exist, insert
        await _supabase.from(_tableName).insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        });
      }

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// UPDATE QUANTITY DIRECTLY (e.g. + / - buttons in UI)
  Future<Either<String, void>> updateQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity <= 0) {
        // If quantity matches 0, remove the item
        return removeFromCart(userId: userId, productId: productId);
      }

      await _supabase.from(_tableName).update({'quantity': newQuantity}).match({
        'user_id': userId,
        'product_id': productId,
      });

      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// REMOVE ITEM
  Future<Either<String, void>> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      await _supabase.from(_tableName).delete().match({
        'user_id': userId,
        'product_id': productId,
      });
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// CLEAR CART
  Future<Either<String, void>> clearCart(String userId) async {
    try {
      await _supabase.from(_tableName).delete().eq('user_id', userId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
