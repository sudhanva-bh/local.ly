import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/cart/cart_item_model.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Provider ---
final orderServiceProvider = Provider<OrderService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderService(client);
});

final myOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return [];

  final service = ref.watch(orderServiceProvider);
  final result = await service.getConsumerOrders(user.id);
  
  return result.fold(
    (l) => throw Exception(l), 
    (r) => r
  );
});

// --- Service ---
class OrderService {
  final SupabaseClient _supabase;
  OrderService(this._supabase);

  /// 🛒 Place Order
  Future<Either<String, List<String>>> placeOrder({
    required String consumerId,
    required List<CartItemModel> cartItems,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLong,
  }) async {
    if (cartItems.isEmpty) return const Left("Cart is empty");

    try {
      // 1. Group items by Seller ID to create split orders
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

        // Calculate Total for this specific order
        final totalAmount = sellerItems.fold(0.0, (sum, item) {
           return sum + item.totalCost;
        });

        // A. Insert Order Header
        final orderRes = await _supabase.from('orders').insert({
          'consumer_id': consumerId,
          'seller_id': sellerId,
          'status': 'pending',
          'total_amount': totalAmount,
          'delivery_address': deliveryAddress,
          'delivery_lat': deliveryLat,
          'delivery_long': deliveryLong,
        }).select().single();
        
        final orderId = orderRes['id'].toString();
        createdOrderIds.add(orderId);

        // B. Prepare Order Items
        final List<Map<String, dynamic>> orderItemsPayload = sellerItems.map((item) {
          final price = item.product!.discountedPrice ?? item.product!.price;
          return {
            'order_id': orderId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'price_at_purchase': price,
          };
        }).toList();

        // C. Insert Order Items
        await _supabase.from('order_items').insert(orderItemsPayload);
      }

      // 3. Clear the Cart (Database side)
      await _supabase.from('cart_items').delete().eq('user_id', consumerId);

      return Right(createdOrderIds);

    } on PostgrestException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// 📜 Get Orders
  Future<Either<String, List<OrderModel>>> getConsumerOrders(String consumerId) async {
    try {
      // We join 'order_items' AND nested 'retail_products' to get names/images
      final data = await _supabase
          .from('orders')
          .select('*, order_items(*, retail_products(product_name, image_urls))')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false);

      final List<dynamic> dataList = data as List<dynamic>;
      final orders = dataList.map((e) => OrderModel.fromMap(e)).toList();
      
      return Right(orders);
    } catch (e) {
      return Left(e.toString());
    }
  }
}