import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/services/search/retail_search_service.dart';
import 'package:locally/features/consumer/order/controller/consumer_search_controller.dart';

class ActiveFiltersList extends ConsumerWidget {
  const ActiveFiltersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFilterProvider);
    bool hasFilters = filters.category != null || 
                      filters.sortBy != SearchSortOption.relevance;

    if (!hasFilters) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (filters.sortBy != SearchSortOption.relevance)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filters.sortBy.label),
                onDeleted: () => ref
                    .read(searchFilterProvider.notifier)
                    .setSortBy(SearchSortOption.relevance),
                backgroundColor: context.colors.primaryContainer,
                side: BorderSide.none,
              ),
            ),
          if (filters.category != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filters.category!.name.toUpperCase()),
                onDeleted: () =>
                    ref.read(searchFilterProvider.notifier).setCategory(null),
                backgroundColor: context.colors.secondaryContainer,
                side: BorderSide.none,
              ),
            ),
        ],
      ),
    );
  }
}