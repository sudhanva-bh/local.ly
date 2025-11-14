import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/services/search/wholesale_search_service.dart';

class WholesaleSearchPage extends StatefulWidget {
  const WholesaleSearchPage({super.key});

  @override
  State<WholesaleSearchPage> createState() => _WholesaleSearchPageState();
}

class _WholesaleSearchPageState extends State<WholesaleSearchPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late WholesaleSearchService _service;

  List<WholesaleProduct> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 20;
  String? _searchText;
  ProductCategories? _selectedCategory;

  @override
  void initState() {
    super.initState();

    // Initialize service directly
    _service = WholesaleSearchService(Supabase.instance.client);

    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  Future<void> _fetchProducts({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (refresh) {
      _products.clear();
      _hasMore = true;
    }

    try {
      final results = await _service.searchProducts(
        userLat: 28.6139, // Replace with dynamic location if needed
        userLon: 77.2090,
        searchText: _searchText,
        category: _selectedCategory,
        limit: _limit,
      );

      setState(() {
        if (refresh) {
          _products = results;
        } else {
          _products.addAll(results);
        }
        _isLoading = false;
        if (results.length < _limit) _hasMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching products: $e');
    }
  }

  void _onSearchSubmitted(String value) {
    _searchText = value;
    _fetchProducts(refresh: true);
  }

  void _onCategorySelected(ProductCategories? category) {
    _selectedCategory = category;
    _fetchProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wholesale Products')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _onSearchSubmitted(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: _onSearchSubmitted,
            ),
          ),

          // Category filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<ProductCategories>(
              isExpanded: true,
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: ProductCategories.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(categoryDisplayName(category)),
                );
              }).toList(),
              onChanged: _onCategorySelected,
            ),
          ),

          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: _products.isEmpty && !_isLoading
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _products.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final product = _products[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: product.imageUrls.isNotEmpty
                              ? Image.network(
                                  product.imageUrls.first,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported),
                          title: Text(product.productName),
                          subtitle: Text(
                            '${categoryDisplayName(ProductCategories.values.firstWhere((c) => c.name == product.category, orElse: () => ProductCategories.other))} • ₹${product.price.toStringAsFixed(2)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(product.averageRating.toStringAsFixed(1)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';

// class WholesaleSearchPage extends StatefulWidget {
//   const WholesaleSearchPage({super.key});

//   @override
//   State<WholesaleSearchPage> createState() => _WholesaleSearchPageState();
// }

// class _WholesaleSearchPageState extends State<WholesaleSearchPage> {
//   final SupabaseClient _supabase = Supabase.instance.client;

//   List<WholesaleProduct> _products = [];
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _runTestQuery();
//   }

//   Future<void> _runTestQuery() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final results = await searchProducts(
//         userLat: 28.6139, // Delhi latitude
//         userLon: 77.2090, // Delhi longitude
//         searchText: 'power',
//         limit: 10,
//       );

//       setState(() {
//         _products = results;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   /// Standalone searchProducts function
//   Future<List<WholesaleProduct>> searchProducts({
//     required double userLat,
//     required double userLon,
//     String? searchText,
//     String? category,
//     double? minPrice,
//     double? maxPrice,
//     double? minRating,
//     int limit = 50,
//   }) async {
//     try {
//       final response = await _supabase.rpc(
//         'search_wholesale_products',
//         params: {
//           'user_lat': userLat,
//           'user_lon': userLon,
//           'search_text': searchText,
//           'category_filter': category,
//           'min_price_filter': minPrice,
//           'max_price_filter': maxPrice,
//           'min_rating_filter': minRating,
//           'result_limit': limit,
//         },
//       );

//       // response is directly List<dynamic>
//       if (response == null) return [];

//       final rawList = response as List<dynamic>;

//       return rawList.map((item) {
//         if (item is Map) {
//           return WholesaleProduct.fromMap(
//             Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
//           );
//         } else {
//           throw Exception('Unexpected item type: ${item.runtimeType}');
//         }
//       }).toList();
//     } catch (e) {
//       print('WholesaleSearchService error: $e');
//       return [];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Wholesale Search Test')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _error != null
//           ? Center(child: Text('Error: $_error'))
//           : _products.isEmpty
//           ? const Center(child: Text('No products found'))
//           : ListView.builder(
//               itemCount: _products.length,
//               itemBuilder: (context, index) {
//                 final product = _products[index];
//                 return ListTile(
//                   title: Text(product.productName),
//                   subtitle: Text(
//                     '${product.category} • ₹${product.price.toStringAsFixed(2)}',
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
