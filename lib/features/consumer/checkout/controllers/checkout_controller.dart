import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';

// 1. Delivery Fee Provider (Keep as is, or update to use distance later)
final deliveryFeeProvider = Provider.autoDispose<double>((ref) {
  final cartState = ref.watch(cartControllerProvider);
  return cartState.maybeWhen(
    data: (items) {
      if (items.isEmpty) return 0.0;
      final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
      double fee = 20.0 + (totalQuantity * 5.0);
      return fee > 100 ? 100.0 : fee;
    },
    orElse: () => 0.0,
  );
});

// 2. Grand Total Provider
final grandTotalProvider = Provider.autoDispose<double>((ref) {
  final subtotal = ref.watch(cartTotalProvider);
  final delivery = ref.watch(deliveryFeeProvider);
  return subtotal + delivery;
});

// 3. Checkout State
class CheckoutState {
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String selectedPaymentMethod;
  final bool isProcessing;

  CheckoutState({
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.selectedPaymentMethod = 'UPI',
    this.isProcessing = false,
  });

  bool get hasValidAddress =>
      deliveryAddress != null &&
      deliveryLatitude != null &&
      deliveryLongitude != null;

  CheckoutState copyWith({
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? selectedPaymentMethod,
    bool? isProcessing,
  }) {
    return CheckoutState(
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

// --- Notifier ---
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(CheckoutState());

  void initializeLocation(String? address, double? lat, double? lng) {
    if (state.deliveryAddress == null && address != null) {
      state = state.copyWith(
        deliveryAddress: address,
        deliveryLatitude: lat,
        deliveryLongitude: lng,
      );
    }
  }

  void setDeliveryLocation(String address, double lat, double lng) {
    state = state.copyWith(
      deliveryAddress: address,
      deliveryLatitude: lat,
      deliveryLongitude: lng,
    );
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  // Simulates the API call to place the order
  Future<bool> placeOrder() async {
    state = state.copyWith(isProcessing: true);
    // Simulate network delay for final placement
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isProcessing: false);
    return true;
  }
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
      return CheckoutNotifier();
    });
