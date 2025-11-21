import 'package:locally/common/models/orders/order_item_model.dart';

enum OrderStatus { pending, accepted, shipped, delivered, cancelled }

class OrderModel {
  final String id;
  final String consumerId;
  final String sellerId;
  final OrderStatus status;
  final double totalAmount;
  final String deliveryAddress;
  final DateTime createdAt;
  final List<OrderItemModel>? items; // Optional: populated via join

  OrderModel({
    required this.id,
    required this.consumerId,
    required this.sellerId,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.createdAt,
    this.items,
  });

  // ---------------------------------------------------------------------------
  // SERIALIZATION (to DB/JSON)
  // ---------------------------------------------------------------------------
  
  Map<String, dynamic> toMap() {
    return {
      'consumer_id': consumerId,
      'seller_id': sellerId,
      'status': status.name,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      // 'created_at' is usually handled by DB default, but can be included if needed
    };
  }

  /// Standard alias for toMap
  Map<String, dynamic> toJson() => toMap();

  // ---------------------------------------------------------------------------
  // DESERIALIZATION (from DB/JSON)
  // ---------------------------------------------------------------------------

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      consumerId: map['consumer_id']?.toString() ?? '',
      sellerId: map['seller_id']?.toString() ?? '',
      
      // Robust Enum Parsing
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      
      // Handle potential Int vs Double issues from DB
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      
      deliveryAddress: map['delivery_address']?.toString() ?? '',
      
      // Parse Timestamp
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      
      // Handle Joined Data (e.g. from Supabase .select('*, order_items(*)'))
      items: map['order_items'] != null
          ? (map['order_items'] as List)
              .map((x) => OrderItemModel.fromMap(x))
              .toList()
          : null,
    );
  }

  /// Standard factory that delegates to fromMap
  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      OrderModel.fromMap(json);
}