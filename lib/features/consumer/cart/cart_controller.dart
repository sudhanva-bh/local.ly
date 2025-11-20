import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/cart/cart_item_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/cart/cart_service.dart';

// 1. Provider for the Service Instance
final cartServiceProvider = Provider<CartService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CartService(client);
});

// 2. Provider for the Cart Total Cost (Derived State)
final cartTotalProvider = Provider.autoDispose<double>((ref) {
  final cartState = ref.watch(cartControllerProvider);
  
  return cartState.maybeWhen(
    data: (items) => items.fold(0.0, (sum, item) => sum + item.totalCost),
    orElse: () => 0.0,
  );
});

// 3. The Main Controller (AsyncNotifier)
final cartControllerProvider =
    AsyncNotifierProvider<CartController, List<CartItemModel>>(
  CartController.new,
);

class CartController extends AsyncNotifier<List<CartItemModel>> {
  @override
  Future<List<CartItemModel>> build() async {
    return _fetchCart();
  }

  /// Internal helper to fetch data
  Future<List<CartItemModel>> _fetchCart() async {
    // We get the UID directly from the Auth client to be fast
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return [];

    final service = ref.read(cartServiceProvider);
    final result = await service.getCart(user.id);

    return result.fold(
      (error) => throw Exception(error),
      (items) => items,
    );
  }

  /// Add item to cart
  Future<void> addItem({required String productId, int quantity = 1}) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;

    // Optional: Set state to loading if you want a global spinner
    // state = const AsyncLoading(); 
    
    final service = ref.read(cartServiceProvider);
    final result = await service.addToCart(
      userId: user.id,
      productId: productId,
      quantity: quantity,
    );

    result.fold(
      (l) => state = AsyncError(l, StackTrace.current),
      (r) => ref.invalidateSelf(), // Successfully added, refresh list
    );
  }

  /// Update Quantity (+ or -)
  Future<void> updateQuantity(String productId, int newQuantity) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;

    // Optimistic update logic can go here, but invalidating is safer for consistency
    final service = ref.read(cartServiceProvider);
    final result = await service.updateQuantity(
      userId: user.id,
      productId: productId,
      newQuantity: newQuantity,
    );

    result.fold(
      (l) => state = AsyncError(l, StackTrace.current),
      (r) => ref.invalidateSelf(), 
    );
  }

  /// Remove item completely
  Future<void> removeItem(String productId) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;

    final service = ref.read(cartServiceProvider);
    await service.removeFromCart(userId: user.id, productId: productId);
    ref.invalidateSelf();
  }
  
  /// Clear entire cart
  Future<void> clearCart() async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return;
    
    final service = ref.read(cartServiceProvider);
    await service.clearCart(user.id);
    ref.invalidateSelf();
  }
}