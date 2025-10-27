import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class SellerTypeButton extends StatefulWidget {
  const SellerTypeButton({
    super.key,
    required this.imagePath,
    required this.isSelected,
  });

  final String imagePath;
  final bool isSelected;

  @override
  State<SellerTypeButton> createState() => _SellerTypeButtonState();
}

class _SellerTypeButtonState extends State<SellerTypeButton> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSelected
              ? context.colors.primary
              : context.colors.outline,
        ),
      ),
      child: Image.asset(widget.imagePath),
    );
  }
}
