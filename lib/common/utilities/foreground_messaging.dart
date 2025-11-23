import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:overlay_support/overlay_support.dart';

void listenToForegroundMessages(BuildContext context) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? 'New notification';
    final body = message.notification?.body ?? '';

    // Using your extension getters:
    final bg = context.colors.surfaceContainerHigh;
    final titleColor = context.colors.onSurface;
    final subtitleColor = context.colors.onSurfaceVariant;

    showSimpleNotification(
      Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        body,
        style: TextStyle(color: subtitleColor),
      ),
      background: bg,
      position: NotificationPosition.top,
      slideDismissDirection: DismissDirection.up,
      autoDismiss: true,
      duration: const Duration(seconds: 3),
    );
  });
}
