import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';

// Renamed to be specific to retail
final retailSearchQueryProvider = StateProvider<String>((ref) => '');

final retailSelectedCategoryProvider = StateProvider<ProductCategories?>(
  (ref) => null,
);
