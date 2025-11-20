import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/models/products/wholesale_product_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/products/retail_product_service.dart';
import 'package:locally/common/services/products/supabase_image_service.dart';
import 'package:locally/common/services/products/wholesale_product_service.dart';

final retailProductServiceProvider = Provider<RetailProductService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final imageService = ref.watch(supabaseImageServiceProvider);
  return RetailProductService(client, imageService);
});

final wholesaleProductServiceProvider = Provider<WholesaleProductService>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  final imageService = ref.watch(supabaseImageServiceProvider);
  return WholesaleProductService(client, imageService);
});

final userWholesaleProductsProvider =
    StreamProvider.autoDispose<List<WholesaleProduct>>((ref) {
      final authState = ref.watch(authStateProvider);
      final user = authState.value;
      if (user == null) return const Stream.empty();

      final service = ref.watch(wholesaleProductServiceProvider);
      return service.streamProductsForCurrentSeller();
    });

/// Stream a single wholesale product (auto updates in real-time)
final wholesaleProductByIdProvider = StreamProvider.autoDispose
    .family<WholesaleProduct?, String>((ref, productId) {
      final service = ref.watch(wholesaleProductServiceProvider);
      return service.streamProductById(productId);
    });

/// 🪣 Provides a singleton instance of SupabaseImageService
final supabaseImageServiceProvider = Provider<SupabaseImageService>((ref) {
  return SupabaseImageService();
});

// ------------------------------------------------------------------
// 🌟 NEW RETAIL PROVIDERS APPENDED BELOW 🌟
// ------------------------------------------------------------------

/// Provides a stream of products for the currently logged-in retail seller.
final userRetailProductsProvider =
    StreamProvider.autoDispose<List<RetailProduct>>((ref) {
      final authState = ref.watch(authStateProvider);
      final user = authState.value;
      if (user == null) return const Stream.empty();

      final service = ref.watch(retailProductServiceProvider);
      return service.streamProductsForCurrentSeller();
    });

/// Stream a single retail product (auto updates in real-time)
final retailProductByIdProvider = StreamProvider.autoDispose
    .family<RetailProduct?, String>((ref, productId) {
      final service = ref.watch(retailProductServiceProvider);
      return service.streamProductById(productId);
    });

/// Stream all retail products that were sourced from a specific wholesale shop ID.
final retailProductsByWholesaleSourceProvider = StreamProvider.autoDispose
    .family<List<RetailProduct>, String>((ref, wholesaleShopId) {
      final service = ref.watch(retailProductServiceProvider);
      return service.getProductsByWholesaleSource(wholesaleShopId);
    });
