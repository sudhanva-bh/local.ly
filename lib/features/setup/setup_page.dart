import 'package:flutter/material.dart';
import 'package:locally/common/models/users/account_type.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/features/setup/consumer/pages/consumer_setup_page.dart';
import 'package:locally/features/setup/seller/pages/seller_setup_page.dart';
import 'package:locally/features/setup/widgets/seller_type_button.dart';
import 'package:velocity_x/velocity_x.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  AccountType? _selectedType;

  void _onTypeSelected(AccountType type) {
    setState(() {
      _selectedType = type;
    });
  }

  void _onSubmit() {
    if (_selectedType == null) {
      CustomSnackbar.show(context, message: "Please select an account type.");
      return;
    }

    switch (_selectedType) {
      case AccountType.wholesaleSeller:
      case AccountType.retailSeller:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerSetupPage(accountType: _selectedType!),
          ),
        );
        break;
      case AccountType.consumer:
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConsumerSetupPage(),
          ),
        );
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- BACKGROUND GRADIENTS (Matching SetupPage) ---
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                Color.fromARGB(255, 253, 121, 6),
                Color.fromARGB(186, 128, 6, 38),
              ],
              center: Alignment(-0.8, -0.8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.4,
              colors: [
                const Color.fromARGB(255, 232, 182, 74),
                Color.fromARGB(182, 202, 16, 16),
              ],
              center: Alignment(0.9, -0.4),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.3,
              colors: [
                Color.fromARGB(255, 227, 23, 23),
                Color(0x00000000),
              ],
              center: Alignment(-0.4, 0.9),
            ),
          ),
        ),

        // --- CONTENT ---
        Scaffold(
          backgroundColor: context.colors.primary.withAlpha(40),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              "LOCAL.LY",
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colors.onPrimary,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "How will you use Locally?",
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    10.heightBox,
                    Text(
                      "Choose the account type that fits you best.",
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onPrimary.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    40.heightBox,

                    // Wholesale Option
                    AccountTypeButton(
                      accountType: AccountType.wholesaleSeller,
                      isSelected: _selectedType == AccountType.wholesaleSeller,
                      onTapped: () =>
                          _onTypeSelected(AccountType.wholesaleSeller),
                    ),
                    20.heightBox,

                    // Retail Option
                    AccountTypeButton(
                      accountType: AccountType.retailSeller,
                      isSelected: _selectedType == AccountType.retailSeller,
                      onTapped: () => _onTypeSelected(AccountType.retailSeller),
                    ),
                    20.heightBox,

                    // Consumer Option
                    AccountTypeButton(
                      accountType: AccountType.consumer,
                      isSelected: _selectedType == AccountType.consumer,
                      onTapped: () => _onTypeSelected(AccountType.consumer),
                    ),
                    60.heightBox,

                    // Submit / Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedType != null ? _onSubmit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.onPrimary,
                          foregroundColor: context.colors.primary,
                          disabledBackgroundColor: context.colors.onPrimary
                              .withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
