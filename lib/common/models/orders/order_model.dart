class WholesaleRetailOrder {
  final String orderId;
  final String retailSellerId;
  final String wholesaleShopId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WholesaleRetailOrder({
    required this.orderId,
    required this.retailSellerId,
    required this.wholesaleShopId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'retail_seller_id': retailSellerId,
      'wholesale_shop_id': wholesaleShopId,
      'items': items,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory WholesaleRetailOrder.fromMap(Map<String, dynamic> map) {
    return WholesaleRetailOrder(
      orderId: map['order_id'],
      retailSellerId: map['retail_seller_id'],
      wholesaleShopId: map['wholesale_shop_id'],
      items: List<Map<String, dynamic>>.from(map['items']),
      totalAmount: map['total_amount'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  /// Create a copy of this order with optional new values
  WholesaleRetailOrder copyWith({
    String? orderId,
    String? retailSellerId,
    String? wholesaleShopId,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WholesaleRetailOrder(
      orderId: orderId ?? this.orderId,
      retailSellerId: retailSellerId ?? this.retailSellerId,
      wholesaleShopId: wholesaleShopId ?? this.wholesaleShopId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
