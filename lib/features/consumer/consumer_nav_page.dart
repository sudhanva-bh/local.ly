import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/widgets/bottom_navigator.dart';
import 'package:locally/features/chat/pages/chat_list_page.dart';
import 'package:locally/features/consumer/cart/cart_page.dart';
import 'package:locally/features/consumer/order/pages/consumer_order_screen.dart';
import 'package:locally/features/consumer/profile_page/pages/consumer_profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConsumerNavPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const ConsumerNavPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ConsumerNavPage> createState() => _ConsumerNavPageState();
}

class _ConsumerNavPageState extends ConsumerState<ConsumerNavPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    Center(child: Text('Consumer Home Feed')), // Index 0
  ConsumerOrderScreen(), // Index 
    CartPage(), // Index 2
    Center(child: Text('My Orders')), // Index 3
    ConsumerProfilePage(), // Index 4
  ];

  final List<BottomNavItem> _navItems = [
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

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Optional: Consumers also need to chat with sellers
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListPage()),
          );
        },
        child: const Icon(Icons.chat_bubble_outline),
      ),

      // Custom Fade Stack
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

// --- FADE INDEXED STACK (Reused) ---

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
          // Prevent clicking on invisible pages
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
