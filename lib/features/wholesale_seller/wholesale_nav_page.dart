import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/wholesale_seller/create_product/pages/create_page.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/home_page.dart';
import 'package:locally/features/wholesale_seller/orders/pages/orders_page.dart';
import 'package:locally/features/retail_seller/products/pages/products_page.dart';
import 'package:locally/features/wholesale_seller/profile_page/pages/profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WholesaleNavPage extends ConsumerStatefulWidget {
  /// Optional initial page index. Defaults to 0 (Dashboard)
  final int initialIndex;

  const WholesaleNavPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<WholesaleNavPage> createState() => _WholesaleNavPageState();
}

class _WholesaleNavPageState extends ConsumerState<WholesaleNavPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Initialize with provided starting index
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    HomePage(),
    ProductsPage(),
    CreatePageUI(),
    WholesaleOrdersPage(),
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
      label: 'Products',
    ),
    BottomNavItem(
      icon: LucideIcons.circlePlus,
      activeIcon: LucideIcons.circlePlus,
      label: 'Create',
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

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
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
