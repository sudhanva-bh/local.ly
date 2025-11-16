import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/orders/order_providers.dart';

/// Provides a simple function to update an order's status.
final updateOrderStatusProvider = Provider<
    Future<void> Function({
  required String orderId,
  required String newStatus,
})>((ref) {
  final service = ref.watch(wholesaleRetailOrderServiceProvider);

  return ({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      await service.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      // Handle or rethrow the error
      rethrow;
    }
  };
});