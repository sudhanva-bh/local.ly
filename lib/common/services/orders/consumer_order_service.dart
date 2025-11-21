import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/cart/cart_item_model.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Service Provider ---
final orderServiceProvider = Provider<OrderService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderService(client);
});

// 1. The List Provider (for the main page)
final sellerOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final service = ref.watch(orderServiceProvider);
  return service.getSellerOrdersStream();
});

// 2. The Single Order Provider (for the details page)
// This ensures that if the status changes while viewing details, the UI updates.
final sellerOrderDetailsProvider = StreamProvider.family.autoDispose<OrderModel, String>((ref, orderId) {
  final service = ref.watch(orderServiceProvider);
  return service.getSingleOrderStream(orderId);
});

// --- Data Provider (Converted to StreamProvider) ---
final myOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final service = ref.watch(orderServiceProvider);

  // This stream will automatically emit new values whenever
  // the 'orders' table changes for this user.
  return service.getConsumerOrdersStream();
});

class OrderService {
  final SupabaseClient _supabase;
  OrderService(this._supabase);

  /// 🛒 Place Order
  /// Automatically uses the logged-in user's ID as the consumer_id
  // Inside OrderService class

  /// 🛒 Place Order (Refactored with Stock Check)
  Future<Either<String, List<String>>> placeOrder({
    required List<CartItemModel> cartItems,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLong,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Left("User not logged in");
    if (cartItems.isEmpty) return const Left("Cart is empty");

    try {
      // 1. Group items by Seller ID (Split Order Logic)
      final Map<String, List<CartItemModel>> itemsBySeller = {};

      for (var item in cartItems) {
        if (item.product == null) continue;
        final sellerId = item.product!.sellerId;

        if (!itemsBySeller.containsKey(sellerId)) {
          itemsBySeller[sellerId] = [];
        }
        itemsBySeller[sellerId]!.add(item);
      }

      final List<String> createdOrderIds = [];

      // 2. Process each Seller Group
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        // Calculate Total for this specific order batch
        final totalAmount = sellerItems.fold(0.0, (sum, item) {
          return sum + item.totalCost;
        });

        // --- CRITICAL STEP: BATCH STOCK CHECK AND DECREMENT ---
        // We must check stock for ALL items in this seller's batch BEFORE inserting the order.
        // If any one item fails, the exception is thrown, and we skip inserting the order.

        final List<Map<String, dynamic>> orderItemsPayload = [];

        for (var item in sellerItems) {
          final price = item.product!.discountedPrice ?? item.product!.price;

          // 🚨 Stock Check/Decrement via RPC
          await _supabase.rpc(
            'decrement_product_stock',
            params: {
              'product_id_input': item.productId,
              'quantity_input': item.quantity,
            },
          );

          // Add to payload only if stock was successfully decremented
          orderItemsPayload.add({
            'order_id': '', // Placeholder, will be updated after header insert
            'product_id': item.productId,
            'quantity': item.quantity,
            'price_at_purchase': price,
          });
        }
        // --- END CRITICAL STEP ---

        // A. Insert Order Header (Only if all stock decrements succeeded)
        final orderRes = await _supabase
            .from('orders')
            .insert({
              'consumer_id': user.id,
              'seller_id': sellerId,
              'status': 'pending',
              'total_amount': totalAmount,
              'delivery_address': deliveryAddress,
              'delivery_lat': deliveryLat,
              'delivery_long': deliveryLong,
            })
            .select()
            .single();

        final orderId = orderRes['id'].toString();
        createdOrderIds.add(orderId);

        // B. Finalize Order Items Payload with the correct orderId
        final finalOrderItemsPayload = orderItemsPayload.map((item) {
          item['order_id'] = orderId;
          return item;
        }).toList();

        // C. Insert Order Items
        await _supabase.from('order_items').insert(finalOrderItemsPayload);
      }

      // 3. Clear the Cart for this user (Only if ALL seller groups succeeded)
      await _supabase.from('cart_items').delete().eq('user_id', user.id);

      return Right(createdOrderIds);
    } on PostgrestException catch (e) {
      // If stock check/decrement failed, the PostgrestException contains the error message
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }
  // ---------------------------------------------------------------------------
  // 📡 REALTIME STREAMS
  // ---------------------------------------------------------------------------

  /// 📜 Get Consumer Orders (Realtime)
  Stream<List<OrderModel>> getConsumerOrdersStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('consumer_id', user.id)
        .order('created_at', ascending: false)
        .asyncMap((_) => _fetchFullOrdersData(isSeller: false));
  }

  /// 🏪 Get Seller Orders (Realtime)
  /// This was missing! This listens for changes on orders where you are the seller.
  Stream<List<OrderModel>> getSellerOrdersStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('seller_id', user.id)
        .order('created_at', ascending: false)
        .asyncMap((_) => _fetchFullOrdersData(isSeller: true));
  }

  /// Helper to fetch deep data (items + products) because Streams don't support Joins
  Future<List<OrderModel>> _fetchFullOrdersData({
    required bool isSeller,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final filterColumn = isSeller ? 'seller_id' : 'consumer_id';

    try {
      final data = await _supabase
          .from('orders')
          // Fetch order, items, and the product details inside items
          .select(
            '*, order_items(*, retail_products(product_name, image_urls))',
          )
          .eq(filterColumn, user.id)
          .order('created_at', ascending: false);

      final dataList = data as List<dynamic>;
      return dataList.map((e) => OrderModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception("Failed to fetch realtime orders: $e");
    }
  }

  // --- Status Updates (RPC Calls) ---

  /// 🏪 Retailer accepts order
  Future<Either<String, void>> receiveOrder(String orderId) async {
    // RPC 'receive_order' uses auth.uid() internally to verify seller ownership
    try {
      await _supabase.rpc(
        'receive_order',
        params: {
          'order_id_input': orderId,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// 🚚 Mark as shipped
  /// Requires sellerId explicitly to verify the package matches the pickup location
  Future<Either<String, void>> receiveShipment(
    String orderId,
    String sellerId,
  ) async {
    try {
      await _supabase.rpc(
        'receive_shipment',
        params: {
          'order_id_input': orderId,
          'seller_id_input': sellerId,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// 🏠 Consumer marks as delivered
  Future<Either<String, void>> receiveDelivery(String orderId) async {
    // RPC 'receive_delivery' uses auth.uid() internally to verify consumer ownership
    try {
      await _supabase.rpc(
        'receive_delivery',
        params: {
          'order_id_input': orderId,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// ❌ Cancel Order
  Future<Either<String, void>> cancelOrder(String orderId) async {
    // RPC 'cancel_order' checks if auth.uid() is either the seller OR consumer
    try {
      await _supabase.rpc(
        'cancel_order',
        params: {
          'order_id_input': orderId,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}

extension OrderServiceExtensions on OrderService {
  
  /// 🔍 Get Single Order Stream (Realtime)
  Stream<OrderModel> getSingleOrderStream(String orderId) {
    // We subscribe to the specific row in the DB
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .asyncMap((event) async {
          // If the order was deleted or doesn't exist
          if (event.isEmpty) {
            throw Exception("Order not found");
          }
          
          // We need to fetch the full details (items + products) again
          // because the stream event only gives us the order header.
          // Reuse your existing fetch logic but filter by ID.
          final data = await _supabase
              .from('orders')
              .select('*, order_items(*, retail_products(product_name, image_urls))')
              .eq('id', orderId)
              .single();
          
          return OrderModel.fromMap(data);
        });
  }
}