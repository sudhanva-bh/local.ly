import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.colors.surfaceDim,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
