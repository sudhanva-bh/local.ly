import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:locally/common/models/orders/order_model.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/services/orders/wholesale_retail_order_service.dart';
import 'package:locally/common/providers/auth_providers.dart';

/// Provides a singleton instance of the WholesaleRetailOrderService
final wholesaleRetailOrderServiceProvider =
    Provider<WholesaleRetailOrderService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final wholesaleService = ref.watch(wholesaleProductServiceProvider);
  final retailService = ref.watch(retailProductServiceProvider);

  return WholesaleRetailOrderService(client, wholesaleService, retailService);
});

/// Stream of orders for the currently logged-in retail seller
final userRetailerOrdersProvider =
    StreamProvider.autoDispose<List<WholesaleRetailOrder>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  final service = ref.watch(wholesaleRetailOrderServiceProvider);
  return service.streamOrdersForRetailer(user.id);
});

/// Stream of orders for a specific wholesale shop
final wholesaleShopOrdersProvider = StreamProvider.autoDispose
    .family<List<WholesaleRetailOrder>, String>((ref, wholesaleShopId) {
  final service = ref.watch(wholesaleRetailOrderServiceProvider);
  return service.streamOrdersForWholesaleShop(wholesaleShopId);
});

/// Stream a single order by ID
final wholesaleRetailOrderByIdProvider = StreamProvider.autoDispose
    .family<WholesaleRetailOrder?, String>((ref, orderId) {
  final service = ref.watch(wholesaleRetailOrderServiceProvider);
  return service.streamOrderById(orderId);
});

/// Create an order and update stock automatically
final createWholesaleRetailOrderProvider =
    Provider<Future<Either<String, WholesaleRetailOrder>> Function(
  WholesaleRetailOrder order,
)>((ref) {
  final service = ref.watch(wholesaleRetailOrderServiceProvider);

  return (WholesaleRetailOrder order) async {
    // Service will handle UUID generation and stock updates
    final result = await service.createOrder(order);
    return result;
  };
});

// Stream the *current retail seller's* orders
final currentRetailOrdersProvider = StreamProvider<List<WholesaleRetailOrder>>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null) return const Stream.empty();

  final orderService = ref.watch(wholesaleRetailOrderServiceProvider);

  return orderService.streamOrdersForRetailer(profile.uid);
});

// Stream the *current wholesale seller's* orders
final currentWholesaleOrdersProvider = StreamProvider<List<WholesaleRetailOrder>>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null) return const Stream.empty();

  final orderService = ref.watch(wholesaleRetailOrderServiceProvider);

  return orderService.streamOrdersForWholesaleShop(profile.uid);
});
