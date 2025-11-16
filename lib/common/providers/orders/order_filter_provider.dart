import 'package:flutter_riverpod/legacy.dart';

/// Holds the current text in the order search bar
final orderSearchQueryProvider = StateProvider<String>((ref) => '');

/// Holds the currently selected order status filter (e.g., "Pending")
/// null means "All"
final selectedOrderStatusProvider = StateProvider<String?>((ref) => null);