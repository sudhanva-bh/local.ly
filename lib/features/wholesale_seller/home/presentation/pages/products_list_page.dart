// lib/features/home/presentation/pages/products_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/wholesale_product_model.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/services/products/wholesale_product_service.dart';

class ProductListPage extends ConsumerStatefulWidget {
  final String tableName;
  const ProductListPage({super.key, required this.tableName});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late final WholesaleProductService _service; // ✅ correct type
  List<WholesaleProduct> _products = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _service = ref.read(wholesaleProductServiceProvider); // ✅ correct way in initState
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final products = await _service.fetchAllProducts();
      if (mounted) {
        setState(() => _products = products);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error loading products: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Products')),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(child: Text(_error))
                : _products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, i) {
                          final product = _products[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: product.imageUrls.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        product.imageUrls.first,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      size: 40),
                              title: Text(
                                product.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '₹${product.price.toStringAsFixed(2)} • Stock: ${product.stock}',
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
