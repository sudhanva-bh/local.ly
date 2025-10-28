import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/features/setup/steps/seller_type.dart';
import 'package:velocity_x/velocity_x.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  SellerType? sellerType;

  void switchSellerType(SellerType newSellerType) {
    setState(() {
      sellerType = newSellerType;
    });
  }

  int _currentStep = 0;

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return sellerType != null;
      case 1:
        return false;
      default:
        return true;
    }
  }

  void _showError(int step) {
    switch (step) {
      case 0:
        CustomSnackbar.show(context, message: "Please select an option");
        return;
      case 1:
        CustomSnackbar.show(context, message: step.toString());
        return;
      default:
        CustomSnackbar.show(context, message: step.toString());
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colors.primary,
        title: Text(
          "LOCAL.LY",
          style: TextStyle(fontSize: 20, color: context.colors.onPrimary),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Stepper(
          steps: [
            Step(
              title: const Text('Seller Type'),
              content: SellerTypeWidget(
                sellerType: sellerType,
                switchSeller: switchSellerType,
              ),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Permissions'),
              content: Placeholder(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Details'),
              content: const Text('Review your details before submitting.'),
              isActive: _currentStep >= 2,
            ),
          ],
          currentStep: _currentStep,
          onStepContinue: () {
            // 👇 Validate before continuing
            if (_isStepValid(_currentStep)) {
              if (_currentStep < 2) {
                setState(() => _currentStep += 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All steps completed ✅')),
                );
              }
            } else {
              _showError(_currentStep);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
        ),
      ),
    );
  }
}
