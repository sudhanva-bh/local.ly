import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/constants/terms_and_conditions.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/theme/app_colors.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/features/auth/widgets/custom_text_field.dart';
import 'package:locally/common/routes/app_routes.dart';
import 'package:locally/features/auth/widgets/terms_conditions_popup.dart';

class RegistrationForm extends ConsumerStatefulWidget {
  final VoidCallback toggleForm;
  const RegistrationForm({super.key, required this.toggleForm});

  @override
  ConsumerState<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  bool isChecked = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // ... (Keep existing _showOtpDialog code here) ...
  Future<void> _showOtpDialog(String email, String password) async {
    // Note: I'm hiding the dialog code for brevity in this answer,
    // but keep your existing _showOtpDialog implementation exactly as it was.
    final otpController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Verification",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter the OTP sent to $email",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.white10,
                        hintText: "••••••",
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          letterSpacing: 4,
                          fontSize: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark.info,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Verify",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 1));
    final controller = ref.read(authControllerProvider.notifier);
    controller.signUp(email: email, password: password);
  }

  void _handleSignUp() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (!isChecked) {
      CustomSnackbar.show(
        context,
        message: "Please agree to Terms & Privacy Policy",
      );
      return;
    }
    if (password != confirm) {
      CustomSnackbar.error(context, "Passwords do not match");
      return;
    }
    _showOtpDialog(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        CustomSnackbar.error(context, next.errorMessage!);
      }
      if (previous?.user == null && next.user != null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.appGate, (route) => false);
      }
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          CustomTextField(label: "Email", controller: emailController),
          const SizedBox(height: 16),
          CustomTextField(
            label: "Password",
            controller: passwordController,
            isPassword: true,
            obscureText: !showPassword,
            onToggleVisibility: () =>
                setState(() => showPassword = !showPassword),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: "Confirm Password",
            controller: confirmController,
            isPassword: true,
            obscureText: !showConfirmPassword,
            onToggleVisibility: () =>
                setState(() => showConfirmPassword = !showConfirmPassword),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (v) => setState(() => isChecked = v ?? false),
                activeColor: AppColors.dark.info,
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: "I agree to ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            TermsConditionsPopup.show(
                              context,
                              "Terms & Conditions",
                              localLyTermsText,
                            );
                          },
                          child: Text(
                            "Terms ",
                            style: TextStyle(
                              color: AppColors.dark.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: "and "),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            TermsConditionsPopup.show(
                              context,
                              "Privacy Policy",
                              localLyPrivacyPolicyText,
                            );
                          },
                          child: Text(
                            "Privacy Policy.",
                            style: TextStyle(
                              color: AppColors.dark.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Main Register Button ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: state.loading ? null : _handleSignUp,
              child: state.loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // --- OR Divider ---
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "OR",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
            ],
          ),

          const SizedBox(height: 24),

          // --- Dummy Google Button ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                // Dummy action - does nothing
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replace this Icon with Image.asset('assets/google_logo.png')
                  Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                  SizedBox(width: 12),
                  Text(
                    "Sign in with Google",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Already have an account? ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: widget.toggleForm,
                child: Text(
                  "Sign In",
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
