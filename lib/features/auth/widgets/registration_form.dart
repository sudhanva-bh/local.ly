import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/theme/app_colors.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/features/auth/widgets/custom_text_field.dart';
import 'package:locally/common/routes/app_routes.dart';

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

  void _handleSignUp() {
    final controller = ref.read(authControllerProvider.notifier);
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

    controller.signUp(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    // ✅ Single place for side effects
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      // Show any errors
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        CustomSnackbar.error(context, next.errorMessage!);
      }

      // Navigate after successful registration
      if (previous?.user == null && next.user != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.appGate,
          (route) => false,
        );
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

          // ✅ Terms and Privacy Policy Checkbox
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
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: "Terms ",
                        style: TextStyle(
                          color: AppColors.dark.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: "and "),
                      TextSpan(
                        text: "Privacy Policy.",
                        style: TextStyle(
                          color: AppColors.dark.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ Register Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
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

          // ✅ Toggle to Sign In
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
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
