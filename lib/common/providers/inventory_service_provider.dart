import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/inventory/inventory_service.dart';

// 2. Service Provider
final inventoryServiceProvider = Provider((ref) {
  return InventoryService(ref.watch(supabaseClientProvider));
});

// -------------------------------------------------------
// A. Pending Orders Provider (Simple Stream)
// -------------------------------------------------------
final pendingOrderIdsProvider = StreamProvider.family<List<String>, String>((
  ref,
  shopId,
) {
  final service = ref.watch(inventoryServiceProvider);
  return service.streamPendingOrderIds(shopId);
});

// -------------------------------------------------------
// B. Low Stock Provider (Reactive RPC)
// -------------------------------------------------------
final lowStockIdsProvider = StreamProvider.family<List<String>, String>((
  ref,
  shopId,
) async* {
  final client = ref.watch(supabaseClientProvider);
  final tolerance =
      5; // Define your tolerance here or pass it in a wrapper object

  // 1. Fetch and yield the INITIAL data immediately
  final initialData = await client.rpc(
    'get_products_near_moq',
    params: {
      'target_shop_id': shopId,
      'tolerance': tolerance,
    },
  );
  yield List<String>.from(initialData);

  // 2. Create a stream that listens to database changes
  final changeStream = client
      .from('wholesale_products')
      .stream(primaryKey: ['product_id'])
      .eq('shop_id', shopId);

  // 3. Watch that stream. Every time the TABLE changes, we re-run the RPC.
  await for (final _ in changeStream) {
    // We ignore the actual row data from the stream because we need
    // the complex logic inside your SQL function.
    final updatedData = await client.rpc(
      'get_products_near_moq',
      params: {
        'target_shop_id': shopId,
        'tolerance': tolerance,
      },
    );

    yield List<String>.from(updatedData);
  }
});
