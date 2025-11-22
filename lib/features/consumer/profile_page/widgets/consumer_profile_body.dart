// lib/features/consumer/profile/widgets/consumer_profile_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/users/consumer_model.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/common/widgets/location_picker.dart';
import 'package:locally/features/consumer/profile_page/controllers/consumer_profile_controller.dart';
import 'package:locally/features/consumer/profile_page/widgets/consumer_location_map.dart';
import 'package:locally/features/retail_seller/profile_page/widgets/editable_info_tile.dart';

class ConsumerProfileBody extends ConsumerWidget {
  final ConsumerModel consumer;
  final bool isCurrentUser;

  const ConsumerProfileBody({
    super.key,
    required this.consumer,
    required this.isCurrentUser,
  });

  static const double _cardElevation = 2.0;
  static const double _cardBorderRadius = 16.0;
  static const double _sectionSpacing = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasLocation =
        consumer.latitude != null &&
        consumer.longitude != null &&
        consumer.address != null;

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
    );
    final shadowColor = colors.shadow.withOpacity(0.1);

    return RefreshIndicator(
      onRefresh: () async => await ref
          .read(consumerProfileControllerProvider.notifier)
          .refreshProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 👤 Profile image
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: consumer.profileImageUrl != null
                      ? NetworkImage(consumer.profileImageUrl!)
                      : null,
                  child: consumer.profileImageUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // 🏷️ Full Name
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCurrentUser ? 48.0 : 0.0,
                    ),
                    child: Text(
                      consumer.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (isCurrentUser)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editField(
                          context,
                          ref: ref,
                          title: "Edit Full Name",
                          initialValue: consumer.fullName,
                          onSave: (val) async {
                            await ref
                                .read(
                                  consumerProfileControllerProvider.notifier,
                                )
                                .updateFullName(val);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                "Consumer Account",
                style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),

              // 📞 Contact & Address Info Group
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: Column(
                  children: [
                    EditableInfoTile(
                      title: 'Phone Number',
                      value: consumer.phoneNumber ?? 'Not provided',
                      icon: Icons.phone_outlined,
                      editable: isCurrentUser,
                      onEdit: () => _editField(
                        context,
                        ref: ref,
                        title: "Edit Phone Number",
                        initialValue: consumer.phoneNumber ?? '',
                        keyboardType: TextInputType.phone,
                        onSave: (val) async {
                          await ref
                              .read(consumerProfileControllerProvider.notifier)
                              .updatePhoneNumber(val);
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Email',
                      value: consumer.email,
                      icon: Icons.email_outlined,
                      editable: false,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Delivery Address',
                      value: consumer.address ?? 'No address set',
                      icon: Icons.location_on_outlined,
                      editable: isCurrentUser,
                      onEdit: () => _editField(
                        context,
                        ref: ref,
                        title: "Edit Address",
                        initialValue: consumer.address ?? '',
                        onSave: (val) async {
                          final updated = consumer.copyWith(address: val);
                          await ref
                              .read(consumerProfileControllerProvider.notifier)
                              .updateProfile(updated);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionSpacing),

              // 🗺️ Map display (Delivery Location)
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                clipBehavior: Clip.antiAlias,
                child: hasLocation
                    ? ConsumerLocationMap(consumer: consumer)
                    : Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text('No delivery location set'),
                      ),
              ),
              if (isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("Set Delivery Location"),
                    onPressed: () async {
                      final result = await showLocationPicker(context);
                      if (result != null) {
                        final lat = result["latitude"] as double;
                        final lon = result["longitude"] as double;
                        final address = result["address"] as String?;

                        final shouldUpdateAddress = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Update Address"),
                            content: const Text(
                              "Do you also want to update your written address from this location?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("No"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Yes"),
                              ),
                            ],
                          ),
                        );

                        await ref
                            .read(consumerProfileControllerProvider.notifier)
                            .updateLocation(
                              latitude: lat,
                              longitude: lon,
                              address:
                                  shouldUpdateAddress == true && address != null
                                  ? address
                                  : consumer.address ?? '',
                            );
                      }
                    },
                  ),
                ),
              const SizedBox(height: _sectionSpacing),

              // ✨ Account Meta Group
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: Column(
                  children: [
                    EditableInfoTile(
                      title: 'Joined On',
                      value: _formatDate(consumer.createdAt),
                      icon: Icons.calendar_today_outlined,
                      editable: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ✅ --- Account Actions ---
              if (isCurrentUser)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface.withOpacity(0.7),
                        side: BorderSide(
                          color: colors.outline.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    try {
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (e) {
      return date.toIso8601String();
    }
  }

  Future<void> _editField(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final isPhoneField = title.toLowerCase().contains("phone");
    final isAddressField = title.toLowerCase().contains("address");

    String? fullNumber;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              if (isPhoneField)
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialCountryCode: 'IN',
                  initialValue: initialValue,
                  onChanged: (phone) {
                    fullNumber = "${phone.countryCode}${phone.number}";
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (phone.number.length < 6) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

              if (isAddressField)
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    alignLabelWithHint: true,
                    hintText: 'Enter your full delivery address here...',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              if (!isPhoneField && !isAddressField)
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Value',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final value = isPhoneField
                      ? fullNumber ?? initialValue
                      : controller.text.trim();
                  Navigator.pop(context, value);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await onSave(result);
    }
  }
}
