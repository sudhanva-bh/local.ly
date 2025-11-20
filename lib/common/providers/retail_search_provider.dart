// -----------------------------------------------------------------------------
// 📦 Providers
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/services/search/retail_search_service.dart';

final retailSearchServiceProvider = Provider<RetailSearchService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RetailSearchService(client);
});
