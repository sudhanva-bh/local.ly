// lib/features/home/presentation/pages/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/product_service_providers.dart'; // provider file

class SearchPage extends ConsumerStatefulWidget {
  final String tableName;
  final String searchColumn;
  final String? initialQuery;

  const SearchPage({
    super.key,
    required this.tableName,
    this.searchColumn = 'product_name',
    this.initialQuery,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<WholesaleProduct> _products = [];
  bool _loading = false;
  String _error = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Autofocus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    if (widget.initialQuery?.isNotEmpty ?? false) {
      _controller.text = widget.initialQuery!;
      _searchProducts(widget.initialQuery!);
    } else {
      _loadAllProducts();
    }
  }

  Future<void> _loadAllProducts() async {
    final service = ref.read(wholesaleProductServiceProvider);
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final results = await service.fetchAllProducts(tableName: widget.tableName);
      setState(() => _products = results);
    } catch (e) {
      setState(() => _error = 'Error fetching products: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    final service = ref.read(wholesaleProductServiceProvider);
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _loadAllProducts();
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final results = await service.searchProducts(
        query: trimmed,
        searchColumn: widget.searchColumn,
      );
      setState(() => _products = results);
    } catch (e) {
      setState(() => _error = 'Error searching products: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchProducts(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _loadAllProducts();
                        },
                      )
                    : null,
                hintText: 'Search products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error))
                      : _products.isEmpty
                          ? const Center(child: Text('No products found'))
                          : ListView.separated(
                              itemCount: _products.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final p = _products[index];
                                return ListTile(
                                  leading: p.imageUrls.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            p.imageUrls.first,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.image_not_supported),
                                  title: Text(p.productName),
                                  subtitle: Text(
                                    p.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    '₹${p.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
