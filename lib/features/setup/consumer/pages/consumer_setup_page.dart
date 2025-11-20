import 'dart:ui'; // For ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/account_type.dart';
import 'package:locally/common/models/users/consumer_model.dart'; // Import Consumer Model
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/notification_provider.dart';
import 'package:locally/common/routes/app_routes.dart';
import 'package:locally/features/setup/consumer/widgets/consumer_personal_details_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/common/providers/auth_providers.dart';

class ConsumerSetupPage extends ConsumerStatefulWidget {
  const ConsumerSetupPage({
    super.key,
  });

  @override
  ConsumerState<ConsumerSetupPage> createState() => _ConsumerSetupPageState();
}

class _ConsumerSetupPageState extends ConsumerState<ConsumerSetupPage> {
  late final TextEditingController phoneNumberController;
  late final TextEditingController fullNameController; // Changed from shopName
  late final TextEditingController addressController;
  final _formKey = GlobalKey<FormState>();

  double? latitude;
  double? longitude;
  String? address;

  bool _isUploading = false;

  @override
  void initState() {
    phoneNumberController = TextEditingController();
    fullNameController = TextEditingController();
    addressController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    fullNameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _onFinishPressed() async {
    // 1. Validate Form
    if (_formKey.currentState?.validate() != true) {
      CustomSnackbar.show(
        context,
        message: "Please fill in all required details",
      );
      return;
    }

    // 2. Validate Location
    if (latitude == null || longitude == null) {
      CustomSnackbar.show(
        context,
        message: "Please select your delivery location on the map",
      );
      return;
    }

    // 3. Proceed to Setup
    await _completeSetup();
  }

  Future<void> _completeSetup() async {
    setState(() => _isUploading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        CustomSnackbar.show(context, message: "User not logged in!");
        return;
      }

      // --- Get FCM Token ---
      final notificationService = ref.read(notificationServiceProvider);
      String? fcmToken;
      try {
        fcmToken = await notificationService.requestPermissionAndGetToken();
      } catch (e) {
        debugPrint("Could not get FCM token during setup: $e");
      }

      // Create Consumer object
      final consumer = ConsumerModel(
        uid: user.id,
        email: user.email ?? '',
        fcmToken: fcmToken,
        phoneNumber: phoneNumberController.text.trim(),
        profileImageUrl: null,
        fullName: fullNameController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        address: addressController.text.trim(),
        // Initialize lists as empty or null based on preference
        favouriteSellerIds: [],
        cartItemIds: [],
        recentlyViewedProductIds: [],
        searchHistory: [],
        purchasedCategories: [],
      );

      // Upload to Supabase
      // Note: Ensure your profileService.createProfile handles Consumer objects
      final profileService = ref.read(consumerProfileServiceProvider);
      final result = await profileService.createProfile(consumer);

      await result.fold(
        (failure) async {
          CustomSnackbar.show(
            context,
            message: "Failed to create profile: $failure",
          );
        },
        (_) async {
          // Init listener
          ref.read(notificationServiceProvider).initTokenRefreshListener();

          CustomSnackbar.show(
            context,
            message: "Profile created successfully!",
          );

          // Navigate to AppGate
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.appGate,
              (route) => false,
            );
          }
        },
      );

      // Update Auth Metadata
      final authService = ref.read(authServiceProvider);
      await authService.updateUserMetadata(
        accountType: AccountType.consumer,
        onboarded: true,
      );
    } catch (e) {
      CustomSnackbar.show(context, message: "Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Stack(
      children: [
        // --- BACKGROUND GRADIENTS (Kept identical for consistency) ---
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
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 1.4,
              colors: [
                Color.fromARGB(255, 232, 182, 74),
                Color.fromARGB(182, 202, 16, 16),
              ],
              center: Alignment(0.9, -0.4),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
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

        // --- PAGE CONTENT ---
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: BackButton(color: colorScheme.onPrimary),
            title: Text(
              "LOCAL.LY",
              style: context.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // HEADER
                    Text(
                      "Tell us about yourself",
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    8.heightBox,
                    Text(
                      "Enter the details below to set up your profile.",
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                    32.heightBox,

                    // --- FORM CONTAINER (Glassmorphism style) ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        // The blur effect
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            // White-ish gradient with opacity
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            // Subtle white border for edge definition
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: ConsumerPersonalDetails(
                            formKey: _formKey,
                            phoneNumberController: phoneNumberController,
                            fullNameController: fullNameController,
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
                        ),
                      ),
                    ),

                    32.heightBox,

                    // NOTIFICATIONS DISCLAIMER
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onPrimary.withOpacity(0.7),
                            size: 18,
                          ),
                          12.widthBox,
                          Expanded(
                            child: Text(
                              'By tapping "Finish Setup", you agree to receive notifications about your orders.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    24.heightBox,

                    // FINISH BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _onFinishPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.onPrimary,
                          foregroundColor: colorScheme.primary,
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                          disabledBackgroundColor: colorScheme.onPrimary
                              .withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isUploading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Text(
                                "Finish Setup",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    40.heightBox,
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
