import 'package:flutter/material.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/features/setup/widgets/seller_type_button.dart';
import 'package:velocity_x/velocity_x.dart';

class SellerTypeWidget extends StatelessWidget {
  const SellerTypeWidget({
    super.key,
    required this.sellerType,
    required this.switchSeller,
  });
  final SellerType? sellerType;
  final Function(SellerType) switchSeller;

  @override
  Widget build(BuildContext context) {
    // Added padding for better spacing within the step
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SellerTypeButton(
              sellerType: SellerType.wholesaleSeller,
              isSelected: sellerType == SellerType.wholesaleSeller,

              onTapped: () {
                switchSeller(SellerType.wholesaleSeller);
              },
            ),
            24.widthBox,
            SellerTypeButton(
              sellerType: SellerType.retailSeller,
              isSelected: sellerType == SellerType.retailSeller,
              onTapped: () {
                switchSeller(SellerType.retailSeller);
              },
            ),
          ],
        ),
      ),
    );
  }
}
