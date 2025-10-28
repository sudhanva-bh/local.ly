import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/auth_gate.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/notification_provider.dart';
import 'package:locally/features/home/presentation/pages/home_page.dart';
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

      // Create Seller object
      final seller = Seller(
        uid: user.id,
        email: user.email ?? '',
        fcmToken: null, // will be updated by NotificationService later
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
          // Update FCM token
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.init();

          CustomSnackbar.show(
            context,
            message: "Profile created successfully!",
          );

          // Navigate to AuthGate
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
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
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_isStepValid(_currentStep)) {
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
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
            return Row(
              children: [
                ElevatedButton(
                  onPressed: _isUploading ? null : details.onStepContinue,
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_currentStep == 3 ? 'Finish' : 'Next'),
                ),
                const SizedBox(width: 10),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
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
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Seller Type: ${sellerType?.toWords() ?? '-'}"),
                  Text("Shop Name: ${shopNameController.text}"),
                  Text("Phone: ${phoneNumberController.text}"),
                  Text("Address: ${addressController.text}"),
                  if (latitude != null && longitude != null)
                    Text(
                      "Location: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}",
                    ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),

            // Step 4: Notifications
            Step(
              title: const Text('Notifications'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We use notifications to keep you updated about orders and messages.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Grant Notification Permission'),
                    onPressed: () async {
                      final notificationService = ref.read(
                        notificationServiceProvider,
                      );
                      try {
                        await notificationService.init();
                        CustomSnackbar.show(
                          context,
                          message:
                              "Notification permission granted successfully!",
                        );
                      } catch (e) {
                        CustomSnackbar.show(
                          context,
                          message: "Failed to enable notifications: $e",
                        );
                      }
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }
}
