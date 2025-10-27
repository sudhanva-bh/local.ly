import 'package:flutter/material.dart';
import 'package:locally/common/constants/file_paths.dart';
import 'package:locally/features/setup/widgets/seller_type_button.dart';
import 'package:velocity_x/velocity_x.dart';

class SellerType extends StatelessWidget {
  const SellerType({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SellerTypeButton(imagePath: FilePaths.retailSellerImage, isSelected: true),
        24.heightBox,
        SellerTypeButton(imagePath: FilePaths.retailSellerImage, isSelected: true)
      ],
    );
  }
}