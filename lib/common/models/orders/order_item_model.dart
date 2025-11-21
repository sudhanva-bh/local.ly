class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double priceAtPurchase;
  // Optional: Include Product Name for UI without extra fetch
  final String? productName; 

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    this.productName,
  });

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_purchase': priceAtPurchase,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      priceAtPurchase: (map['price_at_purchase'] as num?)?.toDouble() ?? 0.0,
      // If you join retail_products in query:
      productName: map['retail_products']?['product_name'], 
    );
  }
}