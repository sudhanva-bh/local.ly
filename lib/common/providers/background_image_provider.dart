import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Background image provider
final bgImageProvider = Provider<ImageProvider>((ref) {
  return const AssetImage('assets/images/carrot.webp');
});

/// Pre-cache image and return true when ready
final bgImagePrecacheProvider = FutureProvider<bool>((ref) async {
  final image = ref.read(bgImageProvider);

  // Need a fake BuildContext substitute -> use ImageConfiguration
  final config = const ImageConfiguration();

  final Completer<bool> c = Completer();

  final stream = image.resolve(config);

  ImageStreamListener? listener;
  listener = ImageStreamListener(
    (_, __) {
      c.complete(true);
      stream.removeListener(listener!);
    },
    onError: (e, _) {
      c.complete(true);
      stream.removeListener(listener!);
    },
  );

  stream.addListener(listener);

  return c.future;
});

/// State for dragOffset (moved out of widget)
final dragOffsetProvider = StateProvider<double>((ref) => 0);
