import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';
import 'package:locally/features/consumer/checkout/pages/checkout_page.dart';

class CartSummaryCard extends ConsumerWidget {
  final NumberFormat currencyFormat;
  final double elevation;
  final Color shadowColor;
  final ShapeBorder shape;

  const CartSummaryCard({
    super.key,
    required this.currencyFormat,
    this.elevation = 2.0,
    required this.shadowColor,
    required this.shape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCost = ref.watch(cartTotalProvider);
    final colors = context.colors;

    return Card(
      elevation: elevation,
      shadowColor: shadowColor,
      shape: shape,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Summary",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
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