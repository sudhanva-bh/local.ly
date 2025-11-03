import 'dart:convert';
import 'package:locally/common/models/ratings/rating_model.dart';

class WholesaleProduct {
  final String productId;
  final String shopId;
  final int minOrderQuantity;
  final int stock;
  final String productName;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final List<Rating> ratings;

  WholesaleProduct({
    required this.productId,
    required this.shopId,
    required this.minOrderQuantity,
    required this.stock,
    required this.productName,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.ratings,
  });

  /// Factory: From JSON map
  factory WholesaleProduct.fromJson(Map<String, dynamic> json) {
    return WholesaleProduct.fromMap(json);
  }

  /// Factory: From map with robust parsing and type-safety
  factory WholesaleProduct.fromMap(Map<String, dynamic> map) {
    // --- Parse image URLs ---
    List<String> parsedImages = [];
    final rawImages = map['image_urls'] ?? map['imageUrls'];
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
            .map(
              (r) => r is Map<String, dynamic>
                  ? Rating.fromMap(r)
                  : Rating.fromJson(r.toString()),
            )
            .toList();
      } else if (rawRatings is String) {
        try {
          final decoded = jsonDecode(rawRatings);
          if (decoded is List) {
            parsedRatings = decoded
                .map((r) => Rating.fromMap(r as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
    }

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

    // --- Construct instance ---
    return WholesaleProduct(
      productId: (map['product_id'] ?? map['id'] ?? '').toString(),
      shopId: (map['shop_id'] ?? '').toString(),
      minOrderQuantity: parseInt(
        map['min_order_quantity'] ?? map['minOrderQuantity'],
      ),
      stock: parseInt(map['stock']),
      productName: (map['product_name'] ?? map['productName'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      price: parseDouble(map['price']),
      imageUrls: parsedImages,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      ratings: parsedRatings,
    );
  }

  /// Convert model to a plain Map
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'shop_id': shopId,
      'min_order_quantity': minOrderQuantity,
      'stock': stock,
      'product_name': productName,
      'description': description,
      'category': category,
      'price': price,
      'image_urls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'ratings': ratings.map((r) => r.toMap()).toList(),
    };
  }

  /// Convert model to JSON string
  String toJson() => json.encode(toMap());

  /// Create model from JSON string
  factory WholesaleProduct.fromJsonString(String source) =>
      WholesaleProduct.fromMap(json.decode(source));

  /// Copy with method for immutability
  WholesaleProduct copyWith({
    String? productId,
    String? shopId,
    int? minOrderQuantity,
    int? stock,
    String? productName,
    String? description,
    String? category,
    double? price,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    List<Rating>? ratings,
  }) {
    return WholesaleProduct(
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      stock: stock ?? this.stock,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ratings: ratings ?? this.ratings,
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
