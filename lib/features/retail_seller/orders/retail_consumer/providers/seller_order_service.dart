import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart'; // Assuming shared model

// -----------------------------------------------------------------------------
// 🧠 PROVIDER
// -----------------------------------------------------------------------------
final sellerOrdersProvider =
    AsyncNotifierProvider<SellerOrdersController, List<OrderModel>>(
  SellerOrdersController.new,
);

class SellerOrdersController extends AsyncNotifier<List<OrderModel>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<OrderModel>> build() async {
    return _fetchOrders();
  }

  Future<List<OrderModel>> _fetchOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('orders')
        .select('*, order_items(*)') // Select orders and nested items
        .eq('seller_id', userId)
        .order('created_at', ascending: false);

    // Convert List<Map> to List<OrderModel>
    // Assuming OrderModel.fromJson handles the nesting of order_items
    return (response as List).map((e) => OrderModel.fromJson(e)).toList();
  }

  // ⚡ ACTION: Update Order Status
  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    state = const AsyncValue.loading();
    
    try {
      // 1. Update Supabase
      await _supabase
          .from('orders')
          .update({
            'status': newStatus.name, // Assuming OrderStatus is an enum
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // 2. Refresh local state
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}