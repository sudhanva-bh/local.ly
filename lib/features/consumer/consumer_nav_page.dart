import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/chat/pages/consumer_chat_list_page.dart';
import 'package:locally/features/consumer/cart/pages/cart_page.dart';
import 'package:locally/features/consumer/home/pages/consumer_home_page.dart';
import 'package:locally/features/consumer/order/pages/consumer_order_screen.dart';
import 'package:locally/features/consumer/profile_page/pages/consumer_profile_page.dart';
import 'package:locally/features/consumer/view_orders/pages/consumer_orders_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- Provider ---
// This is now the Single Source of Truth for navigation
final consumerNavIndexProvider = StateProvider<int>((ref) => 0);

class ConsumerNavPage extends ConsumerWidget {
  const ConsumerNavPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the provider. Rebuilds whenever the index changes.
    final currentIndex = ref.watch(consumerNavIndexProvider);

    // Page Definitions
    const List<Widget> pages = [
      ConsumerHomePage(),
      ConsumerOrderScreen(), // Search (assuming this is search based on icon)
      CartPage(),
      ConsumerOrdersPage(),
      ConsumerProfilePage(),
    ];

    // Nav Item Definitions
    final List<BottomNavItem> navItems = [
      BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      BottomNavItem(
        icon: LucideIcons.search,
        activeIcon: LucideIcons.search,
        label: 'Search',
      ),
      BottomNavItem(
        icon: LucideIcons.shoppingCart,
        activeIcon: LucideIcons.shoppingCart,
        label: 'Cart',
      ),
      BottomNavItem(
        icon: LucideIcons.shoppingBag,
        activeIcon: LucideIcons.shoppingBag,
        label: 'Orders',
      ),
      BottomNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];

    return PopScope(
      canPop: false, // block automatic popping
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;

        if (confirm == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsumerChatListPage()),
            );
          },
          child: const Icon(Icons.chat_bubble_outline),
        ),

        // 2. Pass the provider value to the Stack
        body: FadeIndexedStack(
          index: currentIndex,
          children: pages,
        ),

        // 3. Pass the provider value to the Bar
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            // 4. Update the provider. ref.watch triggers the rebuild above.
            ref.read(consumerNavIndexProvider.notifier).state = index;
          },
          items: navItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: item.activeIcon != null
                      ? Icon(item.activeIcon)
                      : Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// --- FADE INDEXED STACK ---

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: widget.children.asMap().entries.map((entry) {
        final int i = entry.key;
        final Widget child = entry.value;
        final bool active = i == widget.index;

        return IgnorePointer(
          ignoring: !active,
          child: AnimatedOpacity(
            duration: widget.duration,
            opacity: active ? 1.0 : 0.0,
            curve: Curves.easeInOut,
            child: child,
          ),
        );
      }).toList(),
    );
  }
}
