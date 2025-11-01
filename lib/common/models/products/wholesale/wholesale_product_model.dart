// lib/common/models/products/wholesale/wholesale_product_model.dart
import 'dart:convert';

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
  final List<Map<String, dynamic>> ratings;

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

  factory WholesaleProduct.fromJson(Map<String, dynamic> json) {
    return WholesaleProduct.fromMap(json);
  }

  factory WholesaleProduct.fromMap(Map<String, dynamic> map) {
    // parse images
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

    // ratings
    List<Map<String, dynamic>> parsedRatings = [];
    final rawRatings = map['ratings'];
    if (rawRatings != null) {
      if (rawRatings is List) {
        parsedRatings = rawRatings.cast<Map<String, dynamic>>();
      } else if (rawRatings is String) {
        try {
          final decoded = jsonDecode(rawRatings);
          if (decoded is List) {
            parsedRatings = decoded.cast<Map<String, dynamic>>();
          }
        } catch (_) {}
      }
    }

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

    return WholesaleProduct(
      productId: (map['product_id'] ?? map['id'] ?? '').toString(),
      shopId: (map['shop_id'] ?? '').toString(),
      minOrderQuantity:
          parseInt(map['min_order_quantity'] ?? map['minOrderQuantity']),
      stock: parseInt(map['stock']),
      productName:
          (map['product_name'] ?? map['productName'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      price: parseDouble(map['price']),
      imageUrls: parsedImages,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      ratings: parsedRatings,
    );
  }

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
      'ratings': ratings,
    };
  }
}
