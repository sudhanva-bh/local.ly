import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Rating {
  final String ratingId;

  final int stars;
  final String title;
  final String description;
  Rating({
    required this.ratingId,
    required this.stars,
    required this.title,
    required this.description,
  });

  Rating copyWith({
    String? ratingId,
    int? stars,
    String? title,
    String? description,
  }) {
    return Rating(
      ratingId: ratingId ?? this.ratingId,
      stars: stars ?? this.stars,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ratingId': ratingId,
      'stars': stars,
      'title': title,
      'description': description,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      ratingId: map['ratingId'] as String,
      stars: map['stars'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Rating.fromJson(String source) =>
      Rating.fromMap(json.decode(source) as Map<String, dynamic>);
}
