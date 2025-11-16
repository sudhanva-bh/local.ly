// lib/features/products/providers/product_filter_provider.dart
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoryProvider = StateProvider<ProductCategories?>((ref) => null);
