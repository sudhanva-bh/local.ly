import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/providers/background_image_provider.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/features/auth/widgets/registration_form.dart';
import 'package:locally/features/auth/widgets/sign_in_form.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  @override
  // Pre-caches background image to avoid frame drops and flickering
  // when the screen first renders
  void initState() {
    super.initState();

    // PRE-CACHE BACKGROUND IMAGE → removes lag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final img = ref.read(bgImageProvider);
      precacheImage(img, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Detects if keyboard is open to adjust UI visibility dynamically
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Riverpod auth form selector
    // Watches authentication state to toggle between Sign In and Sign Up forms
    final showSignUp = ref.watch(
      authControllerProvider.select((s) => s.showSignUp),
    );
    // Controller used to switch between authentication modes
    final controller = ref.read(authControllerProvider.notifier);

    // READ drag offset from provider
    final dragOffset = ref.watch(dragOffsetProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ref.watch(bgImageProvider),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // --- Header Text ---
            Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: (keyboardOpen || dragOffset > 20) ? 0 : 1,
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
            ),

            // --- Bottom Sheet Form ---
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  ref.read(dragOffsetProvider.notifier).state =
                      (dragOffset + details.primaryDelta!).clamp(0, 120);
                },
                onVerticalDragEnd: (_) {
                  ref.read(dragOffsetProvider.notifier).state = 0;
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  height: showSignUp
                      ? screenHeight * 0.6 - dragOffset
                      : screenHeight * 0.45 - dragOffset,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(800),
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
