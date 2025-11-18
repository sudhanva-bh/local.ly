// lib/common/models/ratings/rating_model.dart
import 'dart:convert';

class Rating {
  final String ratingId;
  final int stars;
  final String title;
  final String? description;
  final String? reviewerName; // Added this field

  Rating({
    required this.ratingId,
    required this.stars,
    required this.title,
    this.description,
    this.reviewerName, // Added to constructor
  });

  Rating copyWith({
    String? ratingId,
    int? stars,
    String? title,
    String? description,
    String? reviewerName, // Added to copyWith
  }) {
    return Rating(
      ratingId: ratingId ?? this.ratingId,
      stars: stars ?? this.stars,
      title: title ?? this.title,
      description: description ?? this.description,
      reviewerName: reviewerName ?? this.reviewerName, // Added here
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ratingId': ratingId,
      'stars': stars,
      'title': title,
      'description': description,
      'reviewer_name': reviewerName, // Use snake_case for Supabase
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    int parseStars(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Rating(
      ratingId: (map['ratingId'] ?? map['id'] ?? '').toString(),
      stars: parseStars(map['stars']),
      title: (map['title'] ?? '').toString(),
      description: map['description'] as String?,
      reviewerName: map['reviewer_name'] as String?, // Read from snake_case
    );
  }

  String toJson() => json.encode(toMap());

  factory Rating.fromJson(String source) => Rating.fromMap(json.decode(source));
}