// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:locally/common/models/ratings/rating_model.dart';

class Wholeseller {
  final String uid;
  final String fcmToken;

  final String email;
  final String? phonenNumber;
  final String? profileImageUrl;

  final String warehouseName;
  final List<String>? productIds;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final double? latitude;
  final double? longitude;

  final List<Rating>? ratings;

  Wholeseller({
    required this.uid,
    required this.fcmToken,
    required this.warehouseName,
    required this.email,
    this.phonenNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.ratings,
    this.productIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fcmToken': fcmToken,
      'warehouseName': warehouseName,
      'email': email,
      'phonenNumber': phonenNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'ratings': ratings?.map((x) => x.toMap()).toList(),
      'productIds': productIds,
    };
  }

  factory Wholeseller.fromMap(Map<String, dynamic> map) {
    return Wholeseller(
      uid: map['uid'] as String,
      fcmToken: map['fcmToken'] as String,
      warehouseName: map['warehouseName'] as String,
      email: map['email'] as String,
      phonenNumber: map['phonenNumber'] != null
          ? map['phonenNumber'] as String
          : null,
      profileImageUrl: map['profileImageUrl'] != null
          ? map['profileImageUrl'] as String
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
      latitude: map['latitude'] != null ? map['latitude'] as double : null,
      longitude: map['longitude'] != null ? map['longitude'] as double : null,
      ratings: map['ratings'] != null
          ? List<Rating>.from(
              (map['ratings'] as List<dynamic>).map(
                (x) => Rating.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      productIds: map['productIds'] != null
          ? List<String>.from(map['productIds'] as List<dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Wholeseller.fromJson(String source) =>
      Wholeseller.fromMap(json.decode(source) as Map<String, dynamic>);

  Wholeseller copyWith({
    String? uid,
    String? fcmToken,
    String? warehouseName,
    String? email,
    String? phonenNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    List<Rating>? ratings,
    List<String>? productIds,
  }) {
    return Wholeseller(
      uid: uid ?? this.uid,
      fcmToken: fcmToken ?? this.fcmToken,
      warehouseName: warehouseName ?? this.warehouseName,
      email: email ?? this.email,
      phonenNumber: phonenNumber ?? this.phonenNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ratings: ratings ?? this.ratings,
      productIds: productIds ?? this.productIds,
    );
  }
}
