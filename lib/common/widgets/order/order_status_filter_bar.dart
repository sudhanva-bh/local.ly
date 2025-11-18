import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/orders/order_filter_provider.dart';

// Define your order statuses here
const List<String> _orderStatuses = [
  'Pending',
  'Confirmed',
  'Shipped',
  'Delivered',
  'Cancelled',
];

class OrderStatusFilterBar extends ConsumerWidget {
  const OrderStatusFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(selectedOrderStatusProvider);

    // Add "All" to the beginning of the list
    final allOptions = [null, ..._orderStatuses];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allOptions.length,
        itemBuilder: (context, index) {
          final status = allOptions[index];
          final isSelected = selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                status ?? "All",
                style: context.text.labelLarge?.copyWith(
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                ref.read(selectedOrderStatusProvider.notifier).state =
                    (selected) ? status : null;
              },
              selectedColor: context.colors.primary,
              backgroundColor: context.colors.surfaceVariant.withOpacity(0.5),
              pressElevation: 0,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // 👈 Rounded chips
                side: BorderSide(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.outline.withOpacity(0.4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
