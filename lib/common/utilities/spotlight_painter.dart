import 'package:flutter/material.dart';

class SpotlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.orange.withOpacity(0.25); // Bright cone color

    final Path path = Path()
      ..moveTo(size.width / 2 - 20, 100) // top-left of cone
      ..lineTo(size.width / 2 + 20, 100) // top-right of cone
      ..lineTo(size.width / 2 + 170, size.height) // bottom-right spread
      ..lineTo(size.width / 2 - 170, size.height) // bottom-left spread
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
