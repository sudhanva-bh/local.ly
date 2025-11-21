import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/retail_seller/orders/retail_consumer/pages/sellers_consumers_orders_page.dart';
import 'package:locally/features/retail_seller/orders/wholesale_retail/retail_orders_page.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(
          title: Text(
            'My Orders',
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: context.colors.surface,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          bottom: TabBar(
            indicatorColor: context.colors.primary,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.onSurface.withOpacity(0.7),
            labelStyle: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Consumer'),
              Tab(text: 'Wholesale'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tab 1: Consumer / Retail Orders
            SellerOrdersPage(),

            // Tab 2: Wholesale / B2B Orders
            RetailOrdersPage(),
          ],
        ),
      ),
    );
  }
}
