import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/services/notification/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});