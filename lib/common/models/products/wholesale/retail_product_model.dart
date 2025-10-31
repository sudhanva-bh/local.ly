// lib/common/models/products/retail_product_model.dart
import 'dart:convert';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';

class RetailProduct {
  final String productId;
  final String sellerId;

  final String name;
  final String description;
  final ProductCategories category;
  final double price;
  final double? discountedPrice;
  final int stock;
  final List<String>? imageUrls;
  final List<Rating> ratings;

  final DateTime createdAt;

  RetailProduct({
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.discountedPrice,
    required this.stock,
    this.imageUrls,
    required this.ratings,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': productId,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'category': category.name,
      'price': price,
      'discounted_price': discountedPrice,
      'stock': stock,
      'image_urls': imageUrls,
      'ratings': ratings.map((r) => r.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RetailProduct.fromMap(Map<String, dynamic> map) {
    return RetailProduct(
      productId: map['id'],
      sellerId: map['seller_id'],
      name: map['name'],
      description: map['description'],
      category: ProductCategories.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ProductCategories.tech,
      ),
      price: (map['price'] as num).toDouble(),
      discountedPrice: (map['discounted_price'] as num?)?.toDouble(),
      stock: map['stock'] ?? 0,
      imageUrls: map['image_urls'] != null
          ? List<String>.from(map['image_urls'])
          : null,
      ratings: (map['ratings'] as List<dynamic>? ?? [])
          .map((r) => Rating.fromMap(r as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String toJson() => json.encode(toMap());

  factory RetailProduct.fromJson(String source) =>
      RetailProduct.fromMap(json.decode(source));
}
