import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/services/products/supabase_image_service.dart';
import 'package:locally/common/services/supabase_services/supabase_service_search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WholesaleProductService {
  final SupabaseClient _supabase;
  late final SupabaseService _supabaseService;
  static const _tableName = 'wholesale_products';
  final SupabaseImageService _imageService;

  WholesaleProductService(this._supabase, this._imageService) {
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

  /// Stream a single product by ID (real-time updates)
  Stream<WholesaleProduct?> streamProductById(String productId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('product_id', productId)
        .map((data) {
          if (data.isEmpty) return null;
          return WholesaleProduct.fromMap(data.first);
        });
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

  /// 🧾 Update an existing product
  Future<void> updateProduct(WholesaleProduct product) async {
    try {
      await _supabase
          .from(_tableName)
          .update(product.toMap())
          .eq('product_id', product.productId);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Deletes a wholesale product and its associated images.
  Future<void> deleteProduct(String productId) async {
    final db = _supabase.from('wholesale_products');

    try {
      // 🧩 Step 1: Fetch image URLs before deleting
      final response = await db
          .select('image_urls')
          .eq('product_id', productId)
          .maybeSingle();

      final imageUrls =
          (response?['image_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // 🧹 Step 2: Delete all related images
      for (final url in imageUrls) {
        await _imageService.deleteImage(url);
      }

      // ❌ Step 3: Delete the product itself
      await db.delete().eq('product_id', productId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete product: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting product: $e');
    }
  }

  /// Delete all products for a seller (shop)
  /// Deletes all products belonging to a given seller (shopId),
  /// and cleans up all associated product images from Supabase Storage.
  Future<void> deleteProductsBySeller(String shopId) async {
    try {
      // 🧩 Step 1: Fetch all products for the seller
      final response = await _supabase
          .from(_tableName)
          .select('product_id, image_urls')
          .eq('shop_id', shopId);

      final products = (response as List<dynamic>?) ?? [];

      // 🧹 Step 2: Delete images for each product
      for (final product in products) {
        final imageUrls =
            (product['image_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        for (final url in imageUrls) {
          await _imageService.deleteImage(url);
        }
      }

      // ❌ Step 3: Delete all products belonging to the seller
      await _supabase.from(_tableName).delete().eq('shop_id', shopId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete products by seller: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting seller products: $e');
    }
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
