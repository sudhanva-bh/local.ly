import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/home_page.dart';
import 'package:locally/features/wholesale_seller/profile_page/pages/profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WholesaleNavPage extends ConsumerStatefulWidget {
  const WholesaleNavPage({super.key});

  @override
  ConsumerState<WholesaleNavPage> createState() => _WholesaleNavPageState();
}

class _WholesaleNavPageState extends ConsumerState<WholesaleNavPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    Center(child: Text('Orders')),
    Center(child: Text('Products')),
    Center(child: Text('Products')),
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
      backgroundColor: Colors.white,
      extendBody: true, // Ensures nav bar floats nicely over blurred background
      body: _pages[_currentIndex],
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
