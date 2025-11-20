import 'package:flutter/material.dart';
import 'package:locally/common/constants/file_paths.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/users/account_type.dart';

class AccountTypeButton extends StatefulWidget {
  const AccountTypeButton({
    super.key,
    required this.isSelected,
    required this.onTapped,
    required this.accountType,
  });

  final AccountType accountType;
  final bool isSelected;
  final VoidCallback onTapped;

  @override
  State<AccountTypeButton> createState() => _AccountTypeButtonState();
}

class _AccountTypeButtonState extends State<AccountTypeButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.98);
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTapped();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    // --- Styles based on selection ---
    // Unselected: Glassy/Transparent white to let gradient show
    // Selected: Solid surface color (usually white)
    final backgroundColor = widget.isSelected
        ? Colors.white.withOpacity(0.75)
        : Colors.white.withOpacity(0.15);

    final borderColor = widget.isSelected
        ? Colors.white.withOpacity(0.75)
        : Colors.white.withOpacity(0.3);

    final titleColor = widget.isSelected ? Colors.black : Colors.white;

    final subtitleColor = widget.isSelected
        ? Colors.black45
        : Colors.white.withOpacity(0.7);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, // Full width for column layout
          height: 90, // Taller to accommodate description
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // --- ICON CONTAINER ---
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: _buildTypeIcon(colorScheme),
              ),
              SizedBox(
                width: 16,
              ),

              // --- TEXT CONTENT ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.accountType.toWords(),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      _getDescription(widget.accountType),
                      style: context.text.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // --- CHECKMARK ---
              if (widget.isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 26,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ColorScheme colors) {
    // Use Image.asset for known paths, fallback to Icons for others
    switch (widget.accountType) {
      case AccountType.retailSeller:
        return Image.asset(
          FilePaths.retailSellerImage,
          fit: BoxFit.contain,
          // Fallback icon if image fails to load/is missing in preview
          errorBuilder: (c, e, s) => Icon(
            Icons.storefront,
            color: widget.isSelected ? colors.primary : Colors.white,
          ),
        );
      case AccountType.wholesaleSeller:
        return Image.asset(
          FilePaths.wholesaleSellerImage,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Icon(
            Icons.warehouse,
            color: widget.isSelected ? colors.primary : Colors.white,
          ),
        );
      case AccountType.consumer:
        // Using a standard icon for Consumer since path wasn't provided
        return Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white,
        );
    }
  }

  String _getDescription(AccountType type) {
    switch (type) {
      case AccountType.wholesaleSeller:
        return "Sell items in bulk quantities";
      case AccountType.retailSeller:
        return "Sell individual items locally";
      case AccountType.consumer:
        return "Shop for items in your area";
    }
  }
}
