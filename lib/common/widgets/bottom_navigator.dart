import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 16.0, right: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              color: context.colors.surface.withAlpha(120),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.15),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: context.colors.primary,
                unselectedItemColor: context.colors.onSurface.withAlpha(155),
                currentIndex: currentIndex,
                onTap: onTap,
                type: BottomNavigationBarType.fixed,

                // 👇 These two lines make text visible only for the selected item
                showUnselectedLabels: false,
                showSelectedLabels: true,

                items: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
