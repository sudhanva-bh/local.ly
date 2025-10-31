// lib/common/providers/product_service_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/products/retail_product_service.dart';
import 'package:locally/common/services/products/wholesale_product_service.dart';

final retailProductServiceProvider = Provider<RetailProductService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RetailProductService(client);
});

final wholesaleProductServiceProvider = Provider<WholesaleProductService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WholesaleProductService(client);
});

final userWholesaleProductsProvider =
    StreamProvider.autoDispose<List<WholesaleProduct>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  final service = ref.watch(wholesaleProductServiceProvider);
  return service.getProductsByShop(user.id);
});
