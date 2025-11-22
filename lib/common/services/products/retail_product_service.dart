import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/common/services/products/supabase_image_service.dart';
import 'package:locally/common/services/supabase_services/supabase_service_search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RetailProductService {
  final SupabaseClient _supabase;
  late final SupabaseService _supabaseService;
  static const _tableName = 'retail_products';
  final SupabaseImageService _imageService;

  RetailProductService(this._supabase, this._imageService) {
    _supabaseService = SupabaseService(_supabase);
  }

  /// Fetch all retail products (admin/global use)
  Future<List<RetailProduct>> fetchAllProducts() async {
    return _supabaseService.fetchFromTable(
      tableName: _tableName,
      fromJson: RetailProduct.fromMap,
    );
  }

  /// Fetch products belonging to the current logged-in seller
  Stream<List<RetailProduct>> streamProductsForCurrentSeller() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('seller_id', user.id)
        .map(
          (data) => data.map((json) => RetailProduct.fromMap(json)).toList(),
        );
  }

  /// Stream of all products for a given seller
  Stream<List<RetailProduct>> getProductsBySeller(String sellerId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('seller_id', sellerId)
        .map(
          (data) => data.map((json) => RetailProduct.fromMap(json)).toList(),
        );
  }

  /// Stream a single product by ID (real-time updates)
  Stream<RetailProduct?> streamProductById(String productId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('product_id', productId)
        .map((data) {
          if (data.isEmpty) return null;
          return RetailProduct.fromMap(data.first);
        });
  }

  /// Add a new product
  Future<Either<String, RetailProduct>> addProduct(
    RetailProduct product,
  ) async {
    try {
      final result = await _supabase
          .from(_tableName)
          .insert(product.toMap())
          .select()
          .single();

      return Right(RetailProduct.fromMap(result));
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// 🧾 Update an existing product
  Future<void> updateProduct(RetailProduct product) async {
    try {
      await _supabase
          .from(_tableName)
          .update(product.toMap())
          .eq('product_id', product.productId);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Deletes a retail product and its associated images.
  Future<void> deleteProduct(String productId) async {
    final db = _supabase.from(_tableName);

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

  /// Delete all products for a seller
  Future<void> deleteProductsBySeller(String sellerId) async {
    try {
      // 🧩 Step 1: Fetch all products for the seller
      final response = await _supabase
          .from(_tableName)
          .select('product_id, image_urls')
          .eq('seller_id', sellerId);

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
      await _supabase.from(_tableName).delete().eq('seller_id', sellerId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete products by seller: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error deleting seller products: $e');
    }
  }

  /// Search products using Edge Function
  Future<List<RetailProduct>> searchProducts({
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
      fromJson: RetailProduct.fromMap,
    );
  }

  // 🌟 NEWLY ADDED METHOD 🌟
  /// Stream of all retail products sourced from a specific wholesale shop
  Stream<List<RetailProduct>> getProductsByWholesaleSource(
      String wholesaleShopId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['product_id'])
        .eq('source_wholesale_shop_id', wholesaleShopId)
        .map(
          (data) => data.map((json) => RetailProduct.fromMap(json)).toList(),
        );
  }

  Future<void> addProductRating(String productId, Rating rating) async {
    try {
      // 1. Fetch current ratings (to avoid race conditions with full product updates,
      // strictly select only the ratings column)
      final response = await _supabase
          .from(_tableName)
          .select('ratings')
          .eq('product_id', productId)
          .single();

      List<Rating> currentRatings = [];
      if (response['ratings'] != null) {
        final list = response['ratings'] as List;
        currentRatings = list
            .map((e) => Rating.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      // 2. Append new rating
      currentRatings.add(rating);

      // 3. Update the column
      await _supabase.from(_tableName).update({
        'ratings': currentRatings.map((r) => r.toMap()).toList(),
      }).eq('product_id', productId);
      
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }
}