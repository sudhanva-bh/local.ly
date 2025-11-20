// lib/features/consumer/profile/pages/consumer_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/features/consumer/profile_page/controllers/consumer_profile_controller.dart';
import 'package:locally/features/consumer/profile_page/widgets/consumer_profile_body.dart';

class ConsumerProfilePage extends ConsumerWidget {
  final String? consumerId;

  const ConsumerProfilePage({super.key, this.consumerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = consumerId == null;

    final profileAsync = isCurrentUser
        ? ref.watch(consumerProfileControllerProvider)
        : ref.watch(getConsumerProfileByIdProvider(consumerId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (consumer) {
          if (consumer == null) {
            return const Center(child: Text('No profile found'));
          }
          return ConsumerProfileBody(
            consumer: consumer,
            isCurrentUser: isCurrentUser,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }
}
