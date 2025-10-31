import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/retail_seller/home/presentation/pages/retail_home_page.dart';
import 'package:locally/features/wholesale_seller/home/presentation/pages/wholesale_nav_page.dart';

class SellerTypeGate extends ConsumerStatefulWidget {
  const SellerTypeGate({super.key});

  @override
  ConsumerState<SellerTypeGate> createState() => _SellerTypeGateState();
}

class _SellerTypeGateState extends ConsumerState<SellerTypeGate> {
  Timer? _retryTimer;

  void _scheduleRetry() {
    // Avoid multiple timers running simultaneously
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        ref.invalidate(currentUserProfileProvider);
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      data: (seller) {
        if (seller == null) {
          // Retry until a seller is available
          _scheduleRetry();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in and has a seller type
        switch (seller.sellerType) {
          case SellerType.wholesaleSeller:
            return const WholesaleNavPage();
          case SellerType.retailSeller:
            return const RetailHomePage();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }
}
