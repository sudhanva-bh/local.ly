import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/features/wholesale_seller/products/providers/product_filter_provider.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // 👈 for context.colors

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: ProductCategories.values.length,
        itemBuilder: (context, index) {
          final category = ProductCategories.values[index];
          final isSelected = category == selected;

          return ChoiceChip(
            label: Text(
              categoryDisplayName(category),
              style: textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colors.onPrimary
                    : colors.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (value) {
              ref.read(selectedCategoryProvider.notifier).state = value
                  ? category
                  : null;
            },
            selectedColor: colors.primary,
            backgroundColor: colors.surfaceVariant.withOpacity(0.5),
            pressElevation: 0,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), // 👈 Rounded chips
              side: BorderSide(
                color: isSelected
                    ? colors.primary
                    : colors.outline.withOpacity(0.4),
              ),
            ),
          );
        },
      ),
    );
  }
}
