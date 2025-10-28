// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/models/ratings/rating_model.dart';

class WholesaleProduct {
  final String productId;
  final String shopId;

  final int minOrderQuantity;
  final int stock;

  final String productName;
  final String description;
  final ProductCategories category;
  final double price;
  final List<String>? imageUrls;

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
    this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.ratings,
  });
}
