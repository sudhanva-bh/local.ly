import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/wholesale_seller/profile_page/pages/profile_page.dart';

class WholesaleNavPage extends ConsumerStatefulWidget {
  const WholesaleNavPage({super.key});

  @override
  ConsumerState<WholesaleNavPage> createState() => _WholesaleNavPageState();
}

class _WholesaleNavPageState extends ConsumerState<WholesaleNavPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('Dashboard')),
    Center(child: Text('Orders')),
    Center(child: Text('Products')),
    ProfilePage(),
  ];

  final List<BottomNavItem> _navItems = const [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    BottomNavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      label: 'Orders',
    ),
    BottomNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Products',
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
      extendBodyBehindAppBar: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}

    // final themeMode = ref.watch(themeProvider);
    // final isDark = themeMode == ThemeMode.dark;
// actions: [
//           IconButton(
//             icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
//             onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               ref.read(authControllerProvider.notifier).signOut();
//               Navigator.of(context).pushNamedAndRemoveUntil(
//                 AppRoutes.authPage,
//                 (route) => false,
//               );
//             },
//           ),
//         ],