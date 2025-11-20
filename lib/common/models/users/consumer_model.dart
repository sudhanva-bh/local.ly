// lib/common/models/users/consumer_model.dart
// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

class ConsumerModel {
  final String uid;
  final String? fcmToken;

  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;

  final String fullName;

  final double? latitude;
  final double? longitude;
  final String? address;

  final List<String>? favouriteSellerIds;
  final List<String>? cartItemIds;
  final List<String>? recentlyViewedProductIds;
  final List<String>? searchHistory;
  final List<String>? purchasedCategories;

  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsumerModel({
    required this.uid,
    this.fcmToken,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.fullName,
    this.latitude,
    this.longitude,
    this.address,
    this.favouriteSellerIds,
    this.cartItemIds,
    this.recentlyViewedProductIds,
    this.searchHistory,
    this.purchasedCategories,
    required this.createdAt,
    this.updatedAt,
  });

  ConsumerModel copyWith({
    String? uid,
    String? fcmToken,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? fullName,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? favouriteSellerIds,
    List<String>? cartItemIds,
    List<String>? recentlyViewedProductIds,
    List<String>? searchHistory,
    List<String>? purchasedCategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsumerModel(
      uid: uid ?? this.uid,
      fcmToken: fcmToken ?? this.fcmToken,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fullName: fullName ?? this.fullName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      favouriteSellerIds: favouriteSellerIds ?? this.favouriteSellerIds,
      cartItemIds: cartItemIds ?? this.cartItemIds,
      recentlyViewedProductIds:
          recentlyViewedProductIds ?? this.recentlyViewedProductIds,
      searchHistory: searchHistory ?? this.searchHistory,
      purchasedCategories: purchasedCategories ?? this.purchasedCategories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': uid,
      'fcm_token': fcmToken,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'full_name': fullName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'favourite_seller_ids': favouriteSellerIds,
      'cart_item_ids': cartItemIds,
      'recently_viewed_product_ids': recentlyViewedProductIds,
      'search_history': searchHistory,
      'purchased_categories': purchasedCategories,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ConsumerModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) {
        throw ArgumentError('createdAt is required');
      }
      if (v is int) {
        return DateTime.fromMillisecondsSinceEpoch(v);
      } else if (v is String) {
        return DateTime.parse(v);
      }
      throw ArgumentError('Unsupported date format: ${v.runtimeType}');
    }

    List<String>? parseStringList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return ConsumerModel(
      uid: (map['id'] ?? map['uid'] ?? '') as String,
      fcmToken: map['fcm_token'] as String?,
      email: (map['email'] ?? '') as String,
      phoneNumber: map['phone_number'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      fullName: (map['full_name'] ?? '') as String,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      address: map['address'] as String?,
      favouriteSellerIds: parseStringList(map['favourite_seller_ids']),
      cartItemIds: parseStringList(map['cart_item_ids']),
      recentlyViewedProductIds: parseStringList(
        map['recently_viewed_product_ids'],
      ),
      searchHistory: parseStringList(map['search_history']),
      purchasedCategories: parseStringList(map['purchased_categories']),
      createdAt: parseDate(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? parseDate(map['updated_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ConsumerModel.fromJson(String source) =>
      ConsumerModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
