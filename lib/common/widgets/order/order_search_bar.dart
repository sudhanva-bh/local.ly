import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/orders/order_filter_provider.dart';

class OrderSearchBar extends ConsumerWidget {
  const OrderSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Order ID...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          ref.read(orderSearchQueryProvider.notifier).state = value;
        },
        onSubmitted: (value) {
          ref.read(orderSearchQueryProvider.notifier).state = value.trim();
        },
      ),
    );
  }
}
