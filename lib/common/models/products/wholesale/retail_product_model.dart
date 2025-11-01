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
  final List<String> imageUrls;
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
    required this.imageUrls,
    required this.ratings,
    required this.createdAt,
  });

  // -----------------------------
  // JSON parsing with safeguards
  // -----------------------------
  factory RetailProduct.fromMap(Map<String, dynamic> map) {
    // parse image URLs
    List<String> parsedImages = [];
    final rawImages = map['image_urls'];
    if (rawImages != null) {
      if (rawImages is List) {
        parsedImages = rawImages.map((e) => e.toString()).toList();
      } else if (rawImages is String) {
        try {
          final decoded = jsonDecode(rawImages);
          if (decoded is List) {
            parsedImages = decoded.map((e) => e.toString()).toList();
          } else {
            parsedImages = [rawImages];
          }
        } catch (_) {
          parsedImages = [rawImages];
        }
      } else {
        parsedImages = [rawImages.toString()];
      }
    }

    // parse ratings
    List<Rating> parsedRatings = [];
    final rawRatings = map['ratings'];
    if (rawRatings != null) {
      if (rawRatings is List) {
        parsedRatings = rawRatings
            .map((e) => Rating.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } else if (rawRatings is String) {
        try {
          final decoded = jsonDecode(rawRatings);
          if (decoded is List) {
            parsedRatings = decoded
                .map((e) => Rating.fromMap(Map<String, dynamic>.from(e)))
                .toList();
          }
        } catch (_) {}
      }
    }

    // helpers
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // category parsing
    ProductCategories parseCategory(dynamic v) {
      if (v == null) return ProductCategories.tech;
      final name = v.toString();
      return ProductCategories.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ProductCategories.tech,
      );
    }

    return RetailProduct(
      productId: (map['id'] ?? map['product_id'] ?? '').toString(),
      sellerId: (map['seller_id'] ?? map['shop_id'] ?? '').toString(),
      name: (map['name'] ?? map['product_name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: parseCategory(map['category']),
      price: parseDouble(map['price']),
      discountedPrice: map['discounted_price'] != null
          ? parseDouble(map['discounted_price'])
          : null,
      stock: parseInt(map['stock']),
      imageUrls: parsedImages,
      ratings: parsedRatings,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory RetailProduct.fromJson(Map<String, dynamic> json) {
    return RetailProduct.fromMap(json);
  }

  // toMap()
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

  // toJson/fromJson
  String toJson() => json.encode(toMap());

  // factory RetailProduct.fromJson(String source) =>
  //     RetailProduct.fromMap(json.decode(source));
}
