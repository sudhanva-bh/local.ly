import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
// Import your OrderService file

// -----------------------------------------------------------------------------
// 🧠 SELLER ORDERS PROVIDER (REALTIME)
// -----------------------------------------------------------------------------
final sellerOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final service = ref.watch(orderServiceProvider);
  
  // This will emit a new list every time the database changes
  return service.getSellerOrdersStream();
});