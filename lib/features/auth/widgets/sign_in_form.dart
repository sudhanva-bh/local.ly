import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/features/auth/widgets/custom_text_field.dart';

class SignInForm extends ConsumerStatefulWidget {
  final VoidCallback toggleForm;
  const SignInForm({super.key, required this.toggleForm});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    // Use ref.listen for side effects
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        CustomSnackbar.error(context, next.errorMessage!);
      }
      // No navigation logic here!
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
          const SizedBox(height: 24),
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
              onPressed: state.loading
                  ? null
                  : () {
                      // Just call the controller.
                      controller.signIn(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                    },
              child: state.loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don’t have an account? ",
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: widget.toggleForm,
                child: Text(
                  "Sign Up",
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