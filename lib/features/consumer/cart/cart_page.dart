import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // For context.colors
import 'package:locally/common/models/cart/cart_item_model.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';
import 'package:locally/features/consumer/checkout/pages/checkout_page.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  // Styling constants matching ConsumerProfileBody
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
          // Clear Cart Button
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
              return _buildEmptyState(context, colors);
            }

            final totalCost = ref.watch(cartTotalProvider);

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
                          child: _CartItemTile(
                            item: item,
                            currencyFormat: currencyFormat,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: _sectionSpacing),

                    // 🧾 Order Summary Card
                    Card(
                      elevation: _cardElevation,
                      shadowColor: shadowColor,
                      shape: cardShape,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order Summary",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            _SummaryRow(
                              label: "Subtotal",
                              value: currencyFormat.format(totalCost),
                            ),
                            const SizedBox(height: 8),
                            const _SummaryRow(
                              label: "Delivery Fee",
                              value: "Calculated at checkout",
                              isMuted: true,
                            ),
                            const Divider(height: 24),
                            _SummaryRow(
                              label: "Total",
                              value: currencyFormat.format(totalCost),
                              isTotal: true,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 20),

                            // Checkout Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckoutPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Proceed to Checkout",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: colors.outline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your cart is empty",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Looks like you haven't added anything yet.",
            style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 168),
        ],
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

// --- Helper Widgets ---

class _CartItemTile extends ConsumerWidget {
  final CartItemModel item;
  final NumberFormat currencyFormat;

  const _CartItemTile({
    required this.item,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final product = item.product;

    // Fallback if product details failed to load
    if (product == null) {
      return ListTile(
        title: const Text("Product unavailable"),
        subtitle: const Text("This item may have been removed."),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => ref
              .read(cartControllerProvider.notifier)
              .removeItem(item.productId),
        ),
      );
    }

    final firstImage = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : null;
    final price = product.discountedPrice ?? product.price;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              image: firstImage != null
                  ? DecorationImage(
                      image: NetworkImage(firstImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: firstImage == null
                ? Icon(
                    Icons.image_not_supported_outlined,
                    color: colors.outline,
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.name.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(price),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Column
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Increment
                    InkWell(
                      onTap: () {
                        ref
                            .read(cartControllerProvider.notifier)
                            .updateQuantity(item.productId, item.quantity + 1);
                      },
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: colors.onSurface,
                        ),
                      ),
                    ),

                    // Count
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        "${item.quantity}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Decrement
                    InkWell(
                      onTap: () {
                        ref
                            .read(cartControllerProvider.notifier)
                            .updateQuantity(item.productId, item.quantity - 1);
                      },
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isMuted;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isMuted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isMuted
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                : null,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
