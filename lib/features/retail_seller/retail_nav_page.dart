import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/chat/pages/chat_list_page.dart';
import 'package:locally/features/retail_seller/orders/pages/orders_page.dart';
import 'package:locally/features/retail_seller/place_orders/pages/wholesale_search_page.dart';
import 'package:locally/features/retail_seller/products/pages/my_retail_products_page.dart';
import 'package:locally/features/retail_seller/profile_page/pages/profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RetailNavPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const RetailNavPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<RetailNavPage> createState() => _RetailNavPageState();
}

class _RetailNavPageState extends ConsumerState<RetailNavPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    Center(child: Text('Home')),
    MyRetailProductsPage(),
    RetailOrdersPage(),
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
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
        },
        child: const Icon(Icons.chat),
      ),
      // 1. Replaced IndexedStack with our custom FadeIndexedStack
      body: FadeIndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
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
    );
  }
}

// --- ADD THIS CLASS BELOW ---

/// A custom Stack that keeps state alive (like IndexedStack)
/// but animates opacity when switching index.
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250), // Adjust speed here
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
          // Prevent clicking on invisible pages
          ignoring: !active, 
          child: AnimatedOpacity(
            duration: widget.duration,
            opacity: active ? 1.0 : 0.0,
            curve: Curves.easeInOut, // Smooth easing
            child: child,
          ),
        );
      }).toList(),
    );
  }
}