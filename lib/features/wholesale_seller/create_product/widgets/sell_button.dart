import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class SellButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SellButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 150,
        height: 55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colors.primary, context.colors.primaryFixedDim],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Sell",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
