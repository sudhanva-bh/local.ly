import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';

class OrderTracker extends StatelessWidget {
  final OrderStatus status;
  const OrderTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // 1. Cancelled State
    if (status == OrderStatus.cancelled) {
      return _buildCancelledState(context);
    }

    // 2. Define Steps
    final steps = [
      (OrderStatus.pending, 'Placed', Icons.receipt_long_rounded),
      (OrderStatus.accepted, 'Accepted', Icons.store_rounded),
      (OrderStatus.shipped, 'Shipped', Icons.local_shipping_rounded),
      (OrderStatus.delivered, 'Delivered', Icons.check_circle_rounded),
    ];

    final currentIndex = steps.indexWhere((s) => s.$1 == status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          return _buildStep(context, index, currentIndex, steps);
        }),
      ),
    );
  }

  Widget _buildCancelledState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.error.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, color: context.colors.error),
          const SizedBox(width: 12),
          Text(
            "Order Cancelled",
            style: context.text.titleMedium?.copyWith(
              color: context.colors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    int index,
    int currentIndex,
    List<(OrderStatus, String, IconData)> steps,
  ) {
    final isCompleted = index < currentIndex;
    final isCurrent = index == currentIndex;
    final isActive = index <= currentIndex;
    final primaryColor = context.colors.primary;
    final greyColor = context.colors.outlineVariant;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // Left Line
                Expanded(
                  child: Container(
                    height: 4,
                    color: index == 0
                        ? Colors.transparent
                        : (isActive
                            ? primaryColor
                            : greyColor.withOpacity(0.3)),
                  ),
                ),
                // Icon Node
                _buildIconNode(
                    context, isCurrent, isCompleted, isActive, steps[index]),
                // Right Line
                Expanded(
                  child: Container(
                    height: 4,
                    color: index == steps.length - 1
                        ? Colors.transparent
                        : (index < currentIndex
                            ? primaryColor
                            : greyColor.withOpacity(0.3)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildStepLabel(context, isCurrent, steps[index].$2),
        ],
      ),
    );
  }

  Widget _buildIconNode(BuildContext context, bool isCurrent, bool isCompleted,
      bool isActive, (OrderStatus, String, IconData) step) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 40 : 32,
          height: isCurrent ? 40 : 32,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent
                ? context.colors.primary
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? context.colors.primary
                  : context.colors.outlineVariant,
              width: 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: context.colors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              isCompleted ? Icons.check : step.$3,
              size: isCurrent ? 20 : 16,
              color: isCompleted || isCurrent
                  ? context.colors.onPrimary
                  : context.colors.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel(BuildContext context, bool isCurrent, String text) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: isCurrent
          ? context.text.labelLarge!.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
            )
          : context.text.labelMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}