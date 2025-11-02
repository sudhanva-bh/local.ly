import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/theme/app_colors.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/features/auth/widgets/registration_form.dart';
import 'package:locally/features/auth/widgets/sign_in_form.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  double dragOffset = 0;

  // You can re-add your animation logic here if you wish
  // bool animate = false;
  // @override
  // void initState() {
  //   super.initState();
  //   Future.delayed(const Duration(milliseconds: 800), () {
  //     if (mounted) setState(() => animate = true);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Read the form state and controller actions from Riverpod
    final showSignUp = ref.watch(
      authControllerProvider.select((s) => s.showSignUp),
    );
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppColors.dark.primaryGradient
              : AppColors.light.primaryGradient,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // --- Header Text ---
            Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    showSignUp
                        ? "Create your\nAccount"
                        : "Sign In to your\nAccount",
                    style: TextStyle(
                      color: context.colors.onPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    showSignUp
                        ? "Get started by creating your account."
                        : "Welcome back! Sign in to continue.",
                    style: TextStyle(
                      color: context.colors.onPrimary.withAlpha(150),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // --- Bottom Sheet Form ---
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    dragOffset = (dragOffset + details.primaryDelta!).clamp(
                      0,
                      120,
                    );
                  });
                },
                onVerticalDragEnd: (_) => setState(() => dragOffset = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  height:
                      showSignUp // This now comes from the controller
                      ? screenHeight * 0.65 - dragOffset
                      : screenHeight * 0.45 - dragOffset,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(45),
                      topRight: Radius.circular(45),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: showSignUp
                      ? RegistrationForm(toggleForm: controller.toggleForm)
                      : SignInForm(toggleForm: controller.toggleForm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
