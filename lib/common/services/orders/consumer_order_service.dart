import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/cart/cart_item_model.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/notification/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Service Provider ---
final orderServiceProvider = Provider<OrderService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderService(client);
});

// 1. The List Provider (for the main page)
final sellerOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  final service = ref.watch(orderServiceProvider);
  return service.getSellerOrdersStream();
});

// 2. The Single Order Provider (for the details page)
// This ensures that if the status changes while viewing details, the UI updates.
final sellerOrderDetailsProvider = StreamProvider.family
    .autoDispose<OrderModel, String>((ref, orderId) {
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

final singleOrderProvider = StreamProvider.family
    .autoDispose<OrderModel, String>((ref, orderId) {
      final service = ref.watch(orderServiceProvider);
      // Uses the extension method from your Service code
      return service.getSingleOrderStream(orderId);
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
      final Map<String, List<CartItemModel>> itemsBySeller = {};

      for (var item in cartItems) {
        if (item.product == null) continue;
        final sellerId = item.product!.sellerId;

        itemsBySeller.putIfAbsent(sellerId, () => []);
        itemsBySeller[sellerId]!.add(item);
      }

      final List<String> createdOrderIds = [];

      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;

        final totalAmount = sellerItems.fold(0.0, (sum, item) {
          return sum + item.totalCost;
        });

        final List<Map<String, dynamic>> orderItemsPayload = [];

        // --- Stock decrement for each item ---
        for (var item in sellerItems) {
          final price = item.product!.discountedPrice ?? item.product!.price;

          await _supabase.rpc(
            'decrement_product_stock',
            params: {
              'product_id_input': item.productId,
              'quantity_input': item.quantity,
            },
          );

          orderItemsPayload.add({
            'order_id': '',
            'product_id': item.productId,
            'quantity': item.quantity,
            'price_at_purchase': price,
          });
        }

        // --- Insert order header ---
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

        // --- Insert order items ---
        final finalOrderItemsPayload = orderItemsPayload.map((item) {
          item['order_id'] = orderId;
          return item;
        }).toList();

        await _supabase.from('order_items').insert(finalOrderItemsPayload);

        // ---------------------------------------------------------
        // 🔥 SEND NOTIFICATION TO SELLER
        // ---------------------------------------------------------

        // We safely wrap this so that order placement NEVER fails due to notifications
        print("-----> Place Order: $sellerId $orderId");
        unawaited(
          sendNotificationToUser(
            targetUserId: sellerId,
            title: "New Order Received",
            body: "You have a new order (#$orderId). Tap to view.",
          ).catchError((e) {
            print("Notification failed for seller $sellerId: $e");
          }),
        );
      }

      // --- Clear cart ---
      await _supabase.from('cart_items').delete().eq('user_id', user.id);

      return Right(createdOrderIds);
    } on PostgrestException catch (e) {
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
  Future<Either<String, void>> receiveOrder(OrderModel order) async {
    // RPC 'receive_order' uses auth.uid() internally to verify seller ownership
    try {
      await _supabase.rpc(
        'receive_order',
        params: {
          'order_id_input': order.id,
        },
      );

      print("-----> Receive Order: ${order.consumerId} ${order.id}");

      unawaited(
        sendNotificationToUser(
          targetUserId: order.consumerId,
          title: "You order has been accepted",
          body:
              "The seller has accepted your order(${order.id}) consisting of ${order.items?.length ?? 0} items. Tap to view.",
        ).catchError((e) {
          print("receiveOrder notification failed");
        }),
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// 🚚 Mark as shipped
  /// Requires sellerId explicitly to verify the package matches the pickup location
  Future<Either<String, void>> receiveShipment(
    OrderModel order,
  ) async {
    try {
      await _supabase.rpc(
        'receive_shipment',
        params: {
          'order_id_input': order.id,
          'seller_id_input': order.sellerId,
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
              .select(
                '*, order_items(*, retail_products(product_name, image_urls))',
              )
              .eq('id', orderId)
              .single();

          return OrderModel.fromMap(data);
        });
  }
}
