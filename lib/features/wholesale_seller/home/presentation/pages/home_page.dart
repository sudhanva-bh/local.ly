import 'package:flutter/material.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/products_list_page.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locally Home'),
        actions: [
          //search icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(
                    //introduce tableName here
                    tableName: 'test_products',
                    searchColumn: 'product_name',
                    initialQuery: '', // initial on opening the search bar
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Text(
              'Welcome to Locally!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductListPage(
                      //Here input changes are made
                      tableName: 'test_products',
                    ),
                  ),
                );
              },
              child: const Text("View All Products"),
            ),
          ],
        ),
      ),
    );
  }
}
