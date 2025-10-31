// lib/features/setup/setup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/notification_provider.dart';
import 'package:locally/common/routes/app_routes.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/features/setup/steps/personal_details.dart';
import 'package:locally/features/setup/steps/seller_type.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  SellerType? sellerType;
  late final TextEditingController phoneNumberController;
  late final TextEditingController shopNameController;
  late final TextEditingController addressController;
  final _formKey = GlobalKey<FormState>();

  double? latitude;
  double? longitude;
  String? address;

  int _currentStep = 0;
  bool _isUploading = false;

  @override
  void initState() {
    phoneNumberController = TextEditingController();
    shopNameController = TextEditingController();
    addressController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    shopNameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void switchSellerType(SellerType newSellerType) {
    setState(() => sellerType = newSellerType);
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return sellerType != null;
      case 1:
        return _formKey.currentState?.validate() == true &&
            latitude != null &&
            longitude != null;
      default:
        // Steps 2 (Review) and 3 (Notifications) don't need validation
        // as they just display info.
        return true;
    }
  }

  void _showError(int step) {
    switch (step) {
      case 0:
        CustomSnackbar.show(context, message: "Please select an option");
        break;
      case 1:
        if (_formKey.currentState?.validate() != true) {
          CustomSnackbar.show(
            context,
            message: "Please fill in all required details",
          );
        } else if (latitude == null || longitude == null) {
          CustomSnackbar.show(
            context,
            message: "Please select your shop location on the map",
          );
        }
        break;
      default:
        CustomSnackbar.show(context, message: "Error in step $step");
    }
  }

  /// Called after the final step is complete
  Future<void> _completeSetup() async {
    setState(() => _isUploading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        CustomSnackbar.show(context, message: "User not logged in!");
        return;
      }

      // --- NEW: Get FCM Token BEFORE creating profile ---
      final notificationService = ref.read(notificationServiceProvider);
      String? fcmToken;
      try {
        fcmToken = await notificationService.requestPermissionAndGetToken();
      } catch (e) {
        print("Could not get FCM token during setup: $e");
        // Don't block setup, just proceed without a token
      }
      // --- END NEW ---

      // Create Seller object
      final seller = Seller(
        uid: user.id,
        email: user.email ?? '',
        fcmToken: fcmToken, // ✅ Use the token here
        phoneNumber: phoneNumberController.text.trim(),
        profileImageUrl: null,
        shopName: shopNameController.text.trim(),
        productIds: [],
        sellerType: sellerType!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        address: addressController.text.trim(),
        ratings: [],
      );

      // Upload to Supabase
      final profileService = ref.read(profileServiceProvider);
      final result = await profileService.createProfile(seller);

      await result.fold(
        (failure) async {
          CustomSnackbar.show(
            context,
            message: "Failed to create profile: $failure",
          );
        },
        (_) async {
          // --- MODIFIED: Set up the refresh listener ---
          // The token is already saved, just listen for future updates.
          ref.read(notificationServiceProvider).initTokenRefreshListener();
          // --- END MODIFIED ---

          CustomSnackbar.show(
            context,
            message: "Profile created successfully!",
          );

          // Navigate to AuthGate
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.sellerTypeGate, // route name
              (route) => false, // remove all previous routes
            );
          }
        },
      );
    } catch (e) {
      CustomSnackbar.show(context, message: "Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Helper widget for a consistent review row
  Widget _buildReviewRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: context.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colors.primary,
        // Use theme-aware text styling
        title: Text(
          "LOCAL.LY",
          style: context.textTheme.titleLarge?.copyWith(
            color: context.colors.onPrimary,
          ),
        ),
        centerTitle: true,
        // Add flat aesthetic
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        elevation: 0, // Flatter look for the stepper
        onStepContinue: () {
          if (_isStepValid(_currentStep)) {
            if (_currentStep < 3) {
              setState(() => _currentStep += 1);
            } else {
              // This is the "Finish" button on the last step
              _completeSetup();
            }
          } else {
            _showError(_currentStep);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          // Consistent styling for control buttons
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isUploading ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: context.textTheme.labelLarge,
                  ),
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            // Ensure progress indicator is visible on button
                            color: context.colors.onPrimary,
                          ),
                        )
                      : Text(_currentStep == 3 ? 'Finish' : 'Next'),
                ),
                const SizedBox(width: 10),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isUploading ? null : details.onStepCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: context.textTheme.labelLarge,
                    ),
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Seller Type
          Step(
            title: const Text('Seller Type'),
            content: SellerTypeWidget(
              sellerType: sellerType,
              switchSeller: switchSellerType,
            ),
            isActive: _currentStep >= 0,
          ),

          // Step 2: Shop Details
          Step(
            title: const Text('Shop Details'),
            content: PersonalDetails(
              formKey: _formKey,
              phoneNumberController: phoneNumberController,
              shopNameController: shopNameController,
              addressController: addressController,
              onLocationPicked:
                  ({
                    required double latitude,
                    required double longitude,
                    required String address,
                  }) {
                    setState(() {
                      this.latitude = latitude;
                      this.longitude = longitude;
                      this.address = address;
                    });
                  },
            ),
            isActive: _currentStep >= 1,
          ),

          // Step 3: Review
          Step(
            title: const Text('Review'),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              // Added a summary card for better visual grouping
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewRow(
                      context,
                      "Seller Type",
                      sellerType?.toWords() ?? '-',
                    ),
                    _buildReviewRow(
                      context,
                      "Shop Name",
                      shopNameController.text,
                    ),
                    _buildReviewRow(
                      context,
                      "Phone",
                      phoneNumberController.text,
                    ),
                    _buildReviewRow(
                      context,
                      "Address",
                      addressController.text,
                    ),
                    if (latitude != null && longitude != null)
                      _buildReviewRow(
                        context,
                        "Location",
                        "${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}",
                      ),
                  ],
                ),
              ),
            ),
            isActive: _currentStep >= 2,
          ),

          // Step 4: Notifications
          Step(
            title: const Text('Notifications'),
            content: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 8.0,
              ),
              child: Text(
                'We use notifications to keep you updated about orders and messages. We will ask for permission when you click "Finish".',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
            ),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }
}
