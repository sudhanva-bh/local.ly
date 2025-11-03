import 'dart:convert';

class Rating {
  final String ratingId;
  final int stars;
  final String title;
  final String? description;

  Rating({
    required this.ratingId,
    required this.stars,
    required this.title,
    this.description,
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
    return {
      'ratingId': ratingId,
      'stars': stars,
      'title': title,
      'description': description,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory Rating.fromJson(String source) => Rating.fromMap(json.decode(source));
}
