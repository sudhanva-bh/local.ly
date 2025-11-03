import 'dart:io';
import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';

class ImagePickerGrid extends StatelessWidget {
  final List<File> pickedImages;
  final VoidCallback onPickImages;
  final void Function(int) onRemoveImage;

  const ImagePickerGrid({
    super.key,
    required this.pickedImages,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            GestureDetector(
              onTap: onPickImages,
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.outline),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            ...pickedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: FileImage(file),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
