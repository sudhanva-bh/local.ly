import 'dart:convert';

import 'package:locally/common/models/products/retail_product_model.dart';

class CartItemModel {
  final String userId;
  final String productId;
  final int quantity;
  
  // Nullable: We populate this when we fetch the cart so the UI can show details
  final RetailProduct? product; 

  CartItemModel({
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  double get totalCost {
    if (product == null) return 0.0;
    final price = product!.discountedPrice ?? product!.price;
    return price * quantity;
  }

  CartItemModel copyWith({
    String? userId,
    String? productId,
    int? quantity,
    RetailProduct? product,
  }) {
    return CartItemModel(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      userId: map['user_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      quantity: int.tryParse(map['quantity'].toString()) ?? 1,
      // If you perform a JOIN in Supabase, the product data might be nested here.
      // For now, we keep it null and populate it in the Service.
      product: null, 
    );
  }

  String toJson() => json.encode(toMap());

  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(json.decode(source));
}