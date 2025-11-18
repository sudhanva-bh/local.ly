import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  final SupabaseClient _client;

  InventoryService(this._client);

  // -------------------------------------------------------
  // 1. STREAM: Pending Orders
  // Since the logic is simple (status == pending), we stream the table directly.
  // -------------------------------------------------------
  Stream<List<String>> streamPendingOrderIds(String shopId) {
    return _client
        .from('wholesale_retail_orders')
        .stream(primaryKey: ['order_id'])
        // 1. APPLY THE RELIABLE SERVER-SIDE FILTER HERE
        .eq('wholesale_shop_id', shopId)
        // REMOVE the second .eq('status', 'pending') filter here
        .map((data) {
          // 2. APPLY THE SECOND FILTER IN DART
          final filteredData = data.where((order) {
            // Check the status locally on the streamed data
            return order['status'] == 'pending';
          });

          // 3. Extract IDs from the now fully-filtered list
          return filteredData.map((e) => e['order_id'] as String).toList();
        });
  }

  // -------------------------------------------------------
  // 2. STREAM: Low Stock (MOQ) - The "Listen & Fetch" Pattern
  // We listen to the table for changes, but we execute the complex RPC logic.
  // -------------------------------------------------------
  Stream<List<String>> streamLowStockProductIds(
    String shopId,
    int tolerance,
  ) async* {
    // 1. Emit the initial data immediately (Fetch once)
    yield await _fetchLowStock(shopId, tolerance);

    // 2. Listen to ANY change on the products table
    _client
        .channel('public:wholesale_products')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wholesale_products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: shopId,
          ),
          callback: (payload) async {
            // We don't care WHAT changed, just that something did.
            // We can't "yield" from inside a callback easily, so this part
            // is tricky in pure Dart without a StreamController.
            // *See the implementation in the Controller section below for the clean fix*
          },
        )
        .subscribe();

    // Note: The cleaner implementation is in the Provider section below
    // because mixing Streams and Async generators can be messy.
  }

  // Helper for the Low Stock RPC
  Future<List<String>> _fetchLowStock(String shopId, int tolerance) async {
    final response = await _client.rpc(
      'get_products_near_moq',
      params: {'target_shop_id': shopId, 'tolerance': tolerance},
    );

    // Supabase RPC returns a dynamic list, cast it to String List
    return List<String>.from(response);
  }
}
