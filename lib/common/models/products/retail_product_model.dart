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
    required this.latitude,
    required this.longitude,
    this.sourceWholesaleShopId,
  });

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
    double? latitude,
    double? longitude,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sourceWholesaleShopId:
          sourceWholesaleShopId ?? this.sourceWholesaleShopId,
    );
  }


  // ---------------------------------------------------------------------------
  // 🧮 Computed Properties (Helpers for UI)
  // ---------------------------------------------------------------------------
  
  /// Returns true if the product is actively discounted
  bool get isDiscounted => 
      discountedPrice != null && discountedPrice! > 0 && discountedPrice! < price;

  /// Returns the percentage off (e.g., "20% OFF")
  String get discountPercentage {
    if (!isDiscounted) return "";
    final percent = ((price - discountedPrice!) / price) * 100;
    return "${percent.toStringAsFixed(0)}% OFF";
  }

  /// Returns average rating or 0.0
  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.fold<int>(0, (sum, r) => sum + r.stars);
    return total / ratings.length;
  }

  bool get isOutOfStock => stock <= 0;

  // ---------------------------------------------------------------------------
  // 🛠️ Factory & Serialization
  // ---------------------------------------------------------------------------

  factory RetailProduct.fromMap(Map<String, dynamic> map) {
    // --- 1. Safe Type Parsing Helpers ---
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    ProductCategories parseCategory(dynamic v) {
      if (v == null) return ProductCategories.tech; // Default fallback
      final name = v.toString();
      return ProductCategories.values.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
        orElse: () => ProductCategories.tech,
      );
    }

    // --- 2. Complex List Parsing ---
    List<String> parsedImages = [];
    final rawImages = map['image_urls'];
    if (rawImages != null) {
      if (rawImages is List) {
        parsedImages = rawImages.map((e) => e.toString()).toList();
      } else if (rawImages is String) {
        // Handle cases where Supabase sends JSON string instead of array
        try {
          final decoded = jsonDecode(rawImages);
          parsedImages = (decoded is List) ? decoded.map((e) => e.toString()).toList() : [];
        } catch (_) {
           // Fallback if it's just a comma string or raw url
           parsedImages = [rawImages]; 
        }
      }
    }

    List<Rating> parsedRatings = [];
    final rawRatings = map['ratings'];
    if (rawRatings != null) {
      try {
        final List<dynamic> list = (rawRatings is String) 
            ? jsonDecode(rawRatings) 
            : rawRatings;
        
        parsedRatings = list
            .map((e) => Rating.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        // Ignore rating parse errors
      }
    }

    return RetailProduct(
      productId: (map['product_id'] ?? map['id'] ?? '').toString(),
      sellerId: (map['seller_id'] ?? '').toString(),
      // 🌟 KEY FIX: Checks 'product_name' first (DB column), then 'name'
      name: (map['product_name'] ?? map['name'] ?? 'Unknown Product').toString(),
      description: (map['description'] ?? '').toString(),
      category: parseCategory(map['category']),
      price: parseDouble(map['price']),
      discountedPrice: map['discounted_price'] != null ? parseDouble(map['discounted_price']) : null,
      stock: parseInt(map['stock']),
      imageUrls: parsedImages,
      ratings: parsedRatings,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      sourceWholesaleShopId: map['source_wholesale_shop_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'seller_id': sellerId,
      'product_name': name, // Writing back to DB correctly
      'description': description,
      'category': category.name,
      'price': price,
      'discounted_price': discountedPrice,
      'stock': stock,
      'image_urls': imageUrls,
      'ratings': ratings.map((r) => r.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'source_wholesale_shop_id': sourceWholesaleShopId,
    };
  }
  
  String toJson() => json.encode(toMap());
  factory RetailProduct.fromJson(String source) => RetailProduct.fromMap(json.decode(source));
}