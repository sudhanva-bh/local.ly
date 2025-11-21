import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';

// 1. Service Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderService(client);
});

// 2. Fetch My Orders Provider
final myOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final service = ref.watch(orderServiceProvider);
  final result = await service.getConsumerOrders(user.id);
  
  return result.fold(
    (l) => throw Exception(l), 
    (r) => r
  );
});

// 3. Order Controller (for placing orders)
final orderControllerProvider = StateNotifierProvider<OrderController, AsyncValue<void>>((ref) {
  return OrderController(ref);
});

class OrderController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  OrderController(this.ref) : super(const AsyncData(null));

  Future<bool> placeOrder({
    required String address,
    required double lat,
    required double long,
  }) async {
    state = const AsyncLoading();

    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      state = const AsyncError("User not logged in", StackTrace.empty);
      return false;
    }

    // Get current cart items from the CartController state
    final cartState = ref.read(cartControllerProvider);
    
    if (!cartState.hasValue || cartState.value!.isEmpty) {
      state = const AsyncError("Cart is empty", StackTrace.empty);
      return false;
    }

    final service = ref.read(orderServiceProvider);
    
    final result = await service.placeOrder(
      consumerId: user.id,
      cartItems: cartState.value!,
      deliveryAddress: address,
      deliveryLat: lat,
      deliveryLong: long,
    );

    return result.fold(
      (l) {
        state = AsyncError(l, StackTrace.current);
        return false;
      },
      (r) {
        state = const AsyncData(null);
        // Refresh cart (it should be empty now)
        ref.invalidate(cartControllerProvider);
        return true; // Success
      },
    );
  }
}