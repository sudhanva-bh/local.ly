import 'dart:convert';

import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/ratings/rating_model.dart';

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
  final double latitude;
  final double longitude;

  // 🌟 ADDED: New nullable field
  final String? sourceWholesaleShopId;

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
    required this.latitude, // 🌟 CORRECTED: Added to constructor
    required this.longitude, // 🌟 CORRECTED: Added to constructor
    this.sourceWholesaleShopId,
  });

  /// Factory: From JSON map
  factory RetailProduct.fromJson(Map<String, dynamic> json) {
    return RetailProduct.fromMap(json);
  }

  /// Factory: From map with robust parsing and type-safety
  factory RetailProduct.fromMap(Map<String, dynamic> map) {
    // --- Safe parsing helpers ---
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

    ProductCategories parseCategory(dynamic v) {
      if (v == null) return ProductCategories.tech;
      final name = v.toString();
      return ProductCategories.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ProductCategories.tech,
      );
    }
    
    // --- Parse image URLs ---
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

    // --- Parse ratings ---
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


    return RetailProduct(
      productId: (map['product_id'] ?? map['id'] ?? '').toString(),
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
      latitude: parseDouble(map['latitude']), // 🌟 CORRECTED: Parse latitude
      longitude: parseDouble(map['longitude']), // 🌟 CORRECTED: Parse longitude
      sourceWholesaleShopId: map['source_wholesale_shop_id']?.toString(),
    );
  }

  /// Convert model to a plain Map
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'seller_id': sellerId,
      'product_name': name,
      'description': description,
      'category': category.name,
      'price': price,
      'discounted_price': discountedPrice,
      'stock': stock,
      'image_urls': imageUrls,
      'ratings': ratings.map((r) => r.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude, // 🌟 CORRECTED: Add to map
      'longitude': longitude, // 🌟 CORRECTED: Add to map
      'source_wholesale_shop_id': sourceWholesaleShopId,
    };
  }

  /// Convert model to JSON string
  String toJson() => json.encode(toMap());

  /// Create model from JSON string
  factory RetailProduct.fromJsonString(String source) =>
      RetailProduct.fromMap(json.decode(source));

  /// Copy with method for immutability
  RetailProduct copyWith({
    String? productId,
    String? sellerId,
    String? name,
    String? description,
    ProductCategories? category,
    double? price,
    double? discountedPrice,
    int? stock,
    List<String>? imageUrls,
    List<Rating>? ratings,
    DateTime? createdAt,
    double? latitude, // 🌟 CORRECTED: Add to copyWith
    double? longitude, // 🌟 CORRECTED: Add to copyWith
    String? sourceWholesaleShopId,
  }) {
    return RetailProduct(
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      stock: stock ?? this.stock,
      imageUrls: imageUrls ?? this.imageUrls,
      ratings: ratings ?? this.ratings,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude, // 🌟 CORRECTED: Use copyWith value
      longitude: longitude ?? this.longitude, // 🌟 CORRECTED: Use copyWith value
      sourceWholesaleShopId:
          sourceWholesaleShopId ?? this.sourceWholesaleShopId,
    );
  }

  /// Computed average rating (0.0 if none)
  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold<int>(0, (sum, r) => sum + r.stars);
    return total / ratings.length;
  }

  /// Number of ratings
  int get ratingCount => ratings.length;
}