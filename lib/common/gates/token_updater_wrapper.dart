import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/notification_provider.dart';

class TokenUpdaterWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final bool isConsumer;

  const TokenUpdaterWrapper({
    super.key,
    required this.child,
    required this.isConsumer,
  });

  @override
  ConsumerState<TokenUpdaterWrapper> createState() => _TokenUpdaterWrapperState();
}

class _TokenUpdaterWrapperState extends ConsumerState<TokenUpdaterWrapper> {
  @override
  void initState() {
    super.initState();
    // We call the async function here.
    // We do NOT await it, because we want the UI to show up immediately.
    // The token update happens silently in the background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).updateUserFcmToken(widget.isConsumer);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return the actual page immediately
    return widget.child;
  }
}