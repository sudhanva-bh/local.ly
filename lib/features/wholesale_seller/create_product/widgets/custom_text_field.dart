import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, color: context.colors.primary)
              : null,
          labelText: label,
          labelStyle: TextStyle(color: context.colors.onSurface.withAlpha(155)),
          filled: true,
          fillColor: context.colors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
