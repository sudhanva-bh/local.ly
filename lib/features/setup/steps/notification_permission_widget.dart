import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/notification_provider.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';
import 'package:velocity_x/velocity_x.dart'; // Using context.textTheme

class NotificationPermissionStep extends ConsumerWidget {
  final VoidCallback onGranted;

  const NotificationPermissionStep({
    super.key,
    required this.onGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added padding for better spacing
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "We’d like to send you notifications for new orders and updates.",
            textAlign: TextAlign.center,
            // Using theme-aware text styling
            style: context.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final service = ref.read(notificationServiceProvider);
                await service.init();

                CustomSnackbar.show(
                  context,
                  message: "Notifications enabled ✅",
                );
                onGranted();
              } catch (e) {
                CustomSnackbar.show(
                  context,
                  message: "Failed to enable notifications: $e",
                );
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text("Grant Notifications Permission"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              // Added text style for consistency
              textStyle: context.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
