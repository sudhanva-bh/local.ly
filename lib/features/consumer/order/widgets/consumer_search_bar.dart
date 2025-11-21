import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/features/consumer/order/controller/consumer_search_controller.dart';
import 'package:locally/features/consumer/order/widgets/search_filters_modal.dart';

class SearchHeader extends ConsumerStatefulWidget {
  const SearchHeader({super.key});

  @override
  ConsumerState<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends ConsumerState<SearchHeader> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await ref
          .watch(supabaseClientProvider)
          .rpc(
            'add_search_history_entry',
            params: {
              'search_term': query,
            },
          );
      ref.read(searchFilterProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.colors.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          SizedBox(width: 12),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const SearchFiltersModal(),
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}
