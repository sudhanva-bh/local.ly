import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/orders/order_model.dart';
// 🌟 Added imports for mapping
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/services/products/retail_product_service.dart';
import 'package:locally/common/services/products/wholesale_product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class WholesaleRetailOrderService {
  final SupabaseClient _supabase;
  final WholesaleProductService _wholesaleService;
  final RetailProductService _retailService;
  static const _tableName = 'wholesale_retail_orders';
  final Uuid _uuid = const Uuid();

  WholesaleRetailOrderService(
    this._supabase,
    this._wholesaleService,
    this._retailService,
  );

  /// Create a new order and update stock
  Future<Either<String, WholesaleRetailOrder>> createOrder(
    WholesaleRetailOrder order,
  ) async {
    final db = _supabase.from(_tableName);

    try {
      // ✅ Ensure orderId is a proper UUID
      final orderWithId = order.copyWith(
        orderId: order.orderId.isNotEmpty ? order.orderId : _uuid.v4(),
      );

      // 1️⃣ Insert the order into Supabase
      final result = await db.insert(orderWithId.toMap()).select().single();
      final createdOrder = WholesaleRetailOrder.fromMap(result);

      // 2️⃣ Update stock for each ordered product
      for (final item in order.items) {
        final productId = item['productId'] as String;
        final quantity = item['quantity'] as int;

        // Fetch the wholesale product by ID
        final wholesaleProduct = await _wholesaleService
            .streamProductById(productId)
            .first;

        if (wholesaleProduct == null) {
          return Left('Product $productId does not exist.');
        }

        final newStock = wholesaleProduct.stock - quantity;
        if (newStock < 0) {
          return Left(
            'Not enough stock for product ${wholesaleProduct.productName} (${wholesaleProduct.productId})',
          );
        }

        // Update wholesale stock
        await _wholesaleService.updateProduct(
          wholesaleProduct.copyWith(stock: newStock),
        );

        // Optional: Update retail stock if this wholesale product is linked to retail products
        final retailProducts = await _retailService
            .getProductsByWholesaleSource(wholesaleProduct.shopId)
            .first;

        final matchingRetailProduct = retailProducts.firstWhereOrNull(
          (r) => r.sourceWholesaleShopId == wholesaleProduct.shopId,
        );

        if (matchingRetailProduct != null) {
          final newRetailStock = (matchingRetailProduct.stock - quantity)
              .clamp(0, double.infinity)
              .toInt();
          await _retailService.updateProduct(
            matchingRetailProduct.copyWith(stock: newRetailStock),
          );
        }
      }

      return Right(createdOrder);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Stream orders for a retail seller
  Stream<List<WholesaleRetailOrder>> streamOrdersForRetailer(
    String retailSellerId,
  ) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['order_id'])
        .eq('retail_seller_id', retailSellerId)
        .map(
          (data) =>
              data.map((json) => WholesaleRetailOrder.fromMap(json)).toList(),
        );
  }

  /// Stream orders for a wholesale shop
  Stream<List<WholesaleRetailOrder>> streamOrdersForWholesaleShop(
    String wholesaleShopId,
  ) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['order_id'])
        .eq('wholesale_shop_id', wholesaleShopId)
        .map(
          (data) =>
              data.map((json) => WholesaleRetailOrder.fromMap(json)).toList(),
        );
  }

  /// Stream a single order by ID
  Stream<WholesaleRetailOrder?> streamOrderById(String orderId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['order_id'])
        .eq('order_id', orderId)
        .map(
          (data) =>
              data.isEmpty ? null : WholesaleRetailOrder.fromMap(data.first),
        );
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabase.from(_tableName).delete().eq('order_id', orderId);
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // 🌟 NEWLY ADDED METHOD 🌟
  ///
  /// Receives an order and adds/updates the retailer's product inventory.
  ///
  /// This function iterates through a wholesale order and for each item:
  /// 1. Checks if the retailer already has a product with the same name from
  ///    the same wholesale supplier.
  /// 2. If YES: Updates the stock (restock).
  /// 3. If NO: Creates a new `RetailProduct` entry in the retailer's inventory.
  ///
  Future<Either<String, void>> addOrderToRetailerInventory(
    WholesaleRetailOrder order,
  ) async {
    try {
      // 1. Get all existing products for this retailer
      final existingRetailProducts = await _retailService
          .getProductsBySeller(order.retailSellerId)
          .first;

      for (final item in order.items) {
        final productId = item['productId'] as String;
        final quantity = item['quantity'] as int;

        // 2. Get the source wholesale product details
        final wholesaleProduct = await _wholesaleService
            .streamProductById(productId)
            .first;

        if (wholesaleProduct == null) {
          // Skip if the source product doesn't exist (or log error)
          continue;
        }

        // 3. Check for an existing product to restock
        final matchingProduct = existingRetailProducts.firstWhereOrNull(
          (p) =>
              p.sourceWholesaleShopId == wholesaleProduct.shopId &&
              p.name == wholesaleProduct.productName,
        );

        if (matchingProduct != null) {
          // 4.a. ✅ RESTOCK: Product exists, just update the stock
          final newStock = matchingProduct.stock + quantity;
          await _retailService.updateProduct(
            matchingProduct.copyWith(stock: newStock),
          );
        } else {
          // 4.b. ➕ ADD NEW: Product doesn't exist, create it
          final newRetailProduct = RetailProduct(
            productId: _uuid.v4(), // Generate a new, unique ID
            sellerId: order.retailSellerId,
            name: wholesaleProduct.productName,
            description: wholesaleProduct.description,
            // Parse category string to enum
            category: _parseCategory(wholesaleProduct.category),
            price: wholesaleProduct.price, // Retailer can change this later
            discountedPrice: null,
            stock: quantity, // The amount received from the order
            imageUrls: wholesaleProduct.imageUrls,
            ratings: [], // Starts with no ratings
            createdAt: DateTime.now(),
            latitude: wholesaleProduct.latitude,
            longitude: wholesaleProduct.longitude,
            sourceWholesaleShopId: wholesaleProduct.shopId,
          );

          await _retailService.addProduct(newRetailProduct);
        }
      }
      return Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Helper to parse category string to ProductCategories enum
  ProductCategories _parseCategory(dynamic v) {
    if (v == null) return ProductCategories.tech; // default

    final input = v.toString().toLowerCase();

    return ProductCategories.values.firstWhere(
      (e) => e.name.toLowerCase() == input,
      orElse: () => ProductCategories.tech,
    );
  }
}
