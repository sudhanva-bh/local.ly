import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';
import 'package:locally/features/consumer/cart/widgets/cart_item_tile.dart';
import 'package:locally/features/consumer/cart/widgets/cart_summary_card.dart';
import 'package:locally/features/consumer/cart/widgets/empty_cart_view.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  // Styling constants
  static const double _cardElevation = 2.0;
  static const double _cardBorderRadius = 16.0;
  static const double _sectionSpacing = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final colors = context.colors;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');

    // Visual helpers
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
    );
    final shadowColor = colors.shadow.withOpacity(0.1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        centerTitle: true,
        actions: [
          // Clear Cart Button (Only show if items exist)
          if (cartState.hasValue && cartState.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: "Clear Cart",
              onPressed: () => _confirmClearCart(context, ref),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(cartControllerProvider.future),
        child: cartState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
          data: (cartItems) {
            if (cartItems.isEmpty) {
              return const EmptyCartView();
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Text
                    Text(
                      "${cartItems.length} Items",
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 📦 Items List
                    ...cartItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          elevation: _cardElevation,
                          shadowColor: shadowColor,
                          shape: cardShape,
                          clipBehavior: Clip.antiAlias,
                          child: CartItemTile(
                            item: item,
                            currencyFormat: currencyFormat,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: _sectionSpacing),

                    // 🧾 Order Summary Card
                    CartSummaryCard(
                      currencyFormat: currencyFormat,
                      shadowColor: shadowColor,
                      shape: cardShape,
                      elevation: _cardElevation,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Clear Cart?"),
        content: const Text("Are you sure you want to remove all items?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(cartControllerProvider.notifier).clearCart();
    }
  }
}