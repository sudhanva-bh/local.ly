import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/products/retail_product_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/product_service_providers.dart';

// 1️⃣ StateProvider to hold the current search text
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// 2️⃣ FutureProvider to fetch results based on the query
final searchResultsProvider = FutureProvider.autoDispose<List<RetailProduct>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);

  // If query is empty, return empty list (UI will show history instead)
  if (query.trim().isEmpty) return [];

  final retailService = ref.watch(retailProductServiceProvider);

  // Calls your existing Edge Function via the service
  return await retailService.searchProducts(
    query: query,
    searchColumn:
        'product_name', // Assuming 'name' is the column, change to 'description' or relevant text column
  );
});

// 3️⃣ Controller to manage Search History (Add/Remove/Clear)
class SearchHistoryController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SearchHistoryController(this._ref) : super(const AsyncData(null));

  /// Adds a term to history and saves to Supabase
  Future<void> addToHistory(String term) async {
    if (term.trim().isEmpty) return;

    final userProfile = _ref.read(currentConsumerProfileProvider).value;
    if (userProfile == null) return;

    // Logic: Remove duplicates, add to top, limit to 10 items
    List<String> history = List.from(userProfile.searchHistory ?? []);
    history.remove(term);
    history.insert(0, term);
    if (history.length > 10) history = history.sublist(0, 10);

    // Update Model
    final updatedProfile = userProfile.copyWith(searchHistory: history);

    // Call Service
    state = const AsyncLoading();
    final result = await _ref
        .read(consumerProfileServiceProvider)
        .updateProfile(updatedProfile);

    result.fold(
      (l) => state = AsyncError(l, StackTrace.current),
      (r) => state = const AsyncData(null),
    );
  }

  /// Remove a single term
  Future<void> removeFromHistory(String term) async {
    final userProfile = _ref.read(currentConsumerProfileProvider).value;
    if (userProfile == null) return;

    List<String> history = List.from(userProfile.searchHistory ?? []);
    history.remove(term);

    final updatedProfile = userProfile.copyWith(searchHistory: history);

    await _ref
        .read(consumerProfileServiceProvider)
        .updateProfile(updatedProfile);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    final userProfile = _ref.read(currentConsumerProfileProvider).value;
    if (userProfile == null) return;

    final updatedProfile = userProfile.copyWith(searchHistory: []);
    await _ref
        .read(consumerProfileServiceProvider)
        .updateProfile(updatedProfile);
  }
}

final searchHistoryControllerProvider =
    StateNotifierProvider<SearchHistoryController, AsyncValue<void>>((ref) {
      return SearchHistoryController(ref);
    });
