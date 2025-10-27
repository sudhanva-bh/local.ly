// lib/common/models/seller/seller.dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:locally/common/models/ratings/rating_model.dart';

enum SellerType {
  wholesaleSeller,
  retailSeller,
}

extension SellerTypeX on SellerType {
  String toValue() {
    switch (this) {
      case SellerType.wholesaleSeller:
        return 'wholesaleSeller';
      case SellerType.retailSeller:
        return 'retailSeller';
    }
  }

  static SellerType fromValue(String? value) {
    switch (value) {
      case 'wholesaleSeller':
        return SellerType.wholesaleSeller;
      case 'retailSeller':
        return SellerType.retailSeller;
      default:
        // default to retail if unknown
        return SellerType.retailSeller;
    }
  }
}

class Seller {
  final String uid;
  final String? fcmToken;

  final String email;
  final String? phonenNumber;
  final String? profileImageUrl;

  final String shopName;
  final List<String>? productIds;
  final SellerType sellerType;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final double? latitude;
  final double? longitude;

  final List<Rating>? ratings;

  Seller({
    required this.uid,
    this.fcmToken,
    required this.email,
    this.phonenNumber,
    this.profileImageUrl,
    required this.shopName,
    this.productIds,
    required this.sellerType,
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.ratings,
  });

  Seller copyWith({
    String? uid,
    String? fcmToken,
    String? email,
    String? phonenNumber,
    String? profileImageUrl,
    String? shopName,
    List<String>? productIds,
    SellerType? sellerType,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    List<Rating>? ratings,
  }) {
    return Seller(
      uid: uid ?? this.uid,
      fcmToken: fcmToken ?? this.fcmToken,
      email: email ?? this.email,
      phonenNumber: phonenNumber ?? this.phonenNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      shopName: shopName ?? this.shopName,
      productIds: productIds ?? this.productIds,
      sellerType: sellerType ?? this.sellerType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ratings: ratings ?? this.ratings,
    );
  }

  /// Convert to a map suitable for storing in Supabase.
  /// Uses ISO strings for datetimes and primitive-friendly collections.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': uid, // use your primary key column name; commonly `id` or `uid`
      'fcm_token': fcmToken,
      'email': email,
      'phone_number': phonenNumber,
      'profile_image_url': profileImageUrl,
      'shop_name': shopName,
      'product_ids': productIds,
      'seller_type': sellerType.toValue(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      // If Rating has toMap, convert to list of maps; else adapt to your schema
      'ratings': ratings?.map((r) => r.toMap()).toList(),
    };
  }

  factory Seller.fromMap(Map<String, dynamic> map) {
    // Helper to parse DateTime from either int milliseconds or ISO string or timestamptz
    DateTime parseDate(dynamic v) {
      if (v == null) throw ArgumentError('createdAt is required');
      if (v is int) {
        return DateTime.fromMillisecondsSinceEpoch(v);
      } else if (v is String) {
        return DateTime.parse(v);
      } else {
        throw ArgumentError('Unsupported date format: ${v.runtimeType}');
      }
    }

    DateTime created = parseDate(map['created_at'] ?? map['createdAt'] ?? map['createdAtMillis']);

    DateTime? updated;
    if (map['updated_at'] != null) {
      final u = map['updated_at'];
      if (u is int) updated = DateTime.fromMillisecondsSinceEpoch(u);
      if (u is String) updated = DateTime.tryParse(u);
    }

    List<String>? productIdsParsed;
    if (map['product_ids'] != null) {
      final p = map['product_ids'];
      if (p is List) {
        productIdsParsed = p.map((e) => e.toString()).toList();
      }
    } else if (map['productIds'] != null) {
      final p = map['productIds'];
      if (p is List) {
        productIdsParsed = p.map((e) => e.toString()).toList();
      }
    }

    List<Rating>? ratingsParsed;
    if (map['ratings'] != null) {
      final r = map['ratings'];
      if (r is List) {
        ratingsParsed = r
            .where((e) => e != null)
            .map<Rating>((e) => Rating.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    }

    double? lat;
    double? lon;
    if (map['latitude'] != null) {
      final v = map['latitude'];
      if (v is num) lat = v.toDouble();
      if (v is String) lat = double.tryParse(v);
    }
    if (map['longitude'] != null) {
      final v = map['longitude'];
      if (v is num) lon = v.toDouble();
      if (v is String) lon = double.tryParse(v);
    }

    return Seller(
      uid: (map['id'] ?? map['uid'] ?? map['uid_str']) as String,
      fcmToken: (map['fcm_token'] ?? map['fcmToken'] ?? '') as String?,
      email: (map['email'] ?? '') as String,
      phonenNumber: map['phone_number'] != null
          ? (map['phone_number'] as String)
          : map['phonenNumber'] != null
              ? (map['phonenNumber'] as String?)
              : null,
      profileImageUrl: map['profile_image_url'] != null
          ? (map['profile_image_url'] as String)
          : map['profileImageUrl'] != null
              ? (map['profileImageUrl'] as String?)
              : null,
      shopName: (map['shop_name'] ?? map['shopName'] ?? '') as String,
      productIds: productIdsParsed,
      sellerType: SellerTypeX.fromValue(
          (map['seller_type'] ?? map['sellerType'])?.toString()),
      createdAt: created,
      updatedAt: updated,
      latitude: lat,
      longitude: lon,
      ratings: ratingsParsed,
    );
  }

  String toJson() => json.encode(toMap());

  factory Seller.fromJson(String source) =>
      Seller.fromMap(json.decode(source) as Map<String, dynamic>);
}
