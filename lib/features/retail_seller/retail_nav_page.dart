import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/chat/pages/retailer_chat_list_page.dart';
import 'package:locally/features/retail_seller/home/pages/home_page.dart';
import 'package:locally/features/retail_seller/orders/my_orders.dart';
import 'package:locally/features/retail_seller/place_orders/pages/wholesale_search_page.dart';
import 'package:locally/features/retail_seller/products/pages/my_retail_products_page.dart';
import 'package:locally/features/retail_seller/profile_page/pages/profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ------------------------------------------------------------
/// RIVERPOD PROVIDER — GLOBAL NAVIGATION STATE
/// ------------------------------------------------------------
final retailNavIndexProvider = StateProvider<int>((ref) => 0);

/// ------------------------------------------------------------
/// MAIN NAVIGATION PAGE
/// ------------------------------------------------------------
class RetailNavPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const RetailNavPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<RetailNavPage> createState() => _RetailNavPageState();
}

class _RetailNavPageState extends ConsumerState<RetailNavPage> {
  @override
  void initState() {
    super.initState();

    // Set initial index safely after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        ref.read(retailNavIndexProvider.notifier).state = widget.initialIndex;
      }
    });
  }

  final List<Widget> _pages = const [
    RetailHomePage(),
    MyRetailProductsPage(),
    MyOrdersPage(),
    WholesaleSearchPage(),
    ProfilePage(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    BottomNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'My Products',
    ),
    BottomNavItem(
      icon: LucideIcons.shoppingBag,
      activeIcon: LucideIcons.shoppingBag,
      label: 'My Orders',
    ),
    BottomNavItem(
      icon: LucideIcons.plus,
      activeIcon: LucideIcons.plus,
      label: 'Place Order',
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _onNavTap(int index) {
    ref.read(retailNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(retailNavIndexProvider);

    return PopScope(
      canPop: false, // block automatic popping
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // system already popped, do nothing

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
              MaterialPageRoute(builder: (_) => const SellerChatListPage()),
            );
          },
          child: const Icon(Icons.chat),
        ),
      
        // Fade transition IndexedStack
        body: FadeIndexedStack(
          index: currentIndex,
          children: _pages,
        ),
      
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: currentIndex,
          onTap: _onNavTap,
          items: _navItems
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

/// ------------------------------------------------------------
/// CUSTOM FADE INDEXED STACK
/// ------------------------------------------------------------
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
        final bool isActive = i == widget.index;

        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            duration: widget.duration,
            curve: Curves.easeInOut,
            opacity: isActive ? 1.0 : 0.0,
            child: child,
          ),
        );
      }).toList(),
    );
  }
}
