// lib/common/providers/orders/order_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/providers/auth_providers.dart';

// Provider to fetch orders RECEIVED by the retailer (Sales)
final retailerSalesOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return [];

  final supabase = ref.watch(supabaseClientProvider);

  // Fetch orders where I am the SELLER
  final data = await supabase
      .from('orders')
      .select('*, order_items(*, retail_products(product_name, image_urls))') // Deep fetch
      .eq('seller_id', user.id) 
      .order('created_at', ascending: false);

  final List<dynamic> dataList = data as List<dynamic>;
  return dataList.map((e) => OrderModel.fromMap(e)).toList();
});

// Provider to update order status (For Sales)
final updateConsumerOrderStatusProvider = Provider((ref) {
  return ({required String orderId, required String newStatus}) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
    // Invalidate to refresh the UI
    ref.invalidate(retailerSalesOrdersProvider);
  };
});