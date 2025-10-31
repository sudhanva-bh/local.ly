import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/routes/app_routes.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';

class RetailHomePage extends ConsumerWidget {
  const RetailHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Call signout from your auth controller
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.authPage, // route name
                (route) => false, // remove all previous routes
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome! You are logged in.'),
      ),
    );
  }
}
