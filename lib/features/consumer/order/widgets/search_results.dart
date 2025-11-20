import 'package:flutter/material.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/features/consumer/order/widgets/product_grid_cart.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<RetailProduct> products;

  const SearchResultsGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Adjust height/width ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return RetailProductGridCard(product: products[index]);
      },
    );
  }
}