import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/chat/pages/retailer_chat_list_page.dart';
import 'package:locally/features/wholesale_seller/create_product/pages/create_page.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/home_page.dart';
import 'package:locally/features/wholesale_seller/orders/pages/orders_page.dart';
import 'package:locally/features/wholesale_seller/products/pages/products_page.dart';
import 'package:locally/features/wholesale_seller/profile_page/pages/profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// 1. DEFINE THE PROVIDER
// This holds the state of the current tab index globally.
final wholesaleNavIndexProvider = StateProvider<int>((ref) => 0);

class WholesaleNavPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const WholesaleNavPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<WholesaleNavPage> createState() => _WholesaleNavPageState();
}

class _WholesaleNavPageState extends ConsumerState<WholesaleNavPage> {
  @override
  void initState() {
    super.initState();
    // 2. INITIALIZE STATE
    // We use addPostFrameCallback to ensure we don't modify the provider
    // in the middle of a build cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        ref.read(wholesaleNavIndexProvider.notifier).state =
            widget.initialIndex;
      }
    });
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
    // 3. UPDATE PROVIDER ON TAP
    ref.read(wholesaleNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    // 4. WATCH THE PROVIDER
    // This rebuilds the widget whenever the index changes (externally or via tap)
    final currentIndex = ref.watch(wholesaleNavIndexProvider);

    return Scaffold(
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
      body: FadeIndexedStack(
        index: currentIndex, // Use the provider value
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex, // Use the provider value
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

// ... [Keep your FadeIndexedStack implementation exactly as it was] ...
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
