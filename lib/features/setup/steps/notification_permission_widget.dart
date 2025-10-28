import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/notification_provider.dart';
import 'package:locally/common/utilities/custom_snackbar.dart';

class NotificationPermissionStep extends ConsumerWidget {
  final VoidCallback onGranted;

  const NotificationPermissionStep({
    super.key,
    required this.onGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "We’d like to send you notifications for new orders and updates.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final service = ref.read(notificationServiceProvider);
              await service.init();

              CustomSnackbar.show(context, message: "Notifications enabled ✅");
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
          ),
        ),
      ],
    );
  }
}
