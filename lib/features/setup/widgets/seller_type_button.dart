import 'package:flutter/material.dart';
import 'package:locally/common/constants/file_paths.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/users/seller_model.dart';

class SellerTypeButton extends StatefulWidget {
  const SellerTypeButton({
    super.key,
    required this.isSelected,
    required this.onTapped,
    required this.sellerType,
  });

  final SellerType sellerType;
  final bool isSelected;
  final VoidCallback onTapped;

  @override
  State<SellerTypeButton> createState() => _SellerTypeButtonState();
}

class _SellerTypeButtonState extends State<SellerTypeButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.96);
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTapped();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: 150,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainer, // Changed for better contrast
            borderRadius: BorderRadius.circular(12), // Softer radius
            border: Border.all(
              color: widget.isSelected
                  ? colorScheme.primary.withAlpha(155)
                  : colorScheme.outlineVariant,
              width: 1.2,
            ),
            // Added subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.sellerType == SellerType.retailSeller
                      ? FilePaths.retailSellerImage
                      : FilePaths.wholesaleSellerImage,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ),
              ),
              // Corrected SizedBox from width to height
              const SizedBox(height: 12),
              Text(
                widget.sellerType.toWords(),
                // Added center alignment
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: widget.isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
