// lib/features/profile/widgets/profile_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/users/account_type.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/features/auth/controllers/auth_controller.dart';
import 'package:locally/common/widgets/location_picker.dart';
import 'package:locally/features/retail_seller/profile_page/controllers/profile_controller.dart';
import 'package:locally/features/welcome/pages/welcome_screen.dart';
import 'editable_info_tile.dart';
import 'shop_location_map.dart';

class ProfileBody extends ConsumerWidget {
  final Seller seller;
  final bool isCurrentUser;

  const ProfileBody({
    super.key,
    required this.seller,
    required this.isCurrentUser,
  });

  // --- Constants for modern UI ---
  static const double _cardElevation = 2.0;
  static const double _cardBorderRadius = 16.0;
  static const double _sectionSpacing = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasLocation =
        seller.latitude != null &&
        seller.longitude != null &&
        seller.address != null;
    final productCount = seller.productIds?.length ?? 0;

    // Consistent card shape
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
    );
    // Consistent shadow
    final shadowColor = colors.shadow.withOpacity(0.1);

    return RefreshIndicator(
      onRefresh: () async =>
          await ref.read(profileControllerProvider.notifier).refreshProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🏪 Profile image with shadow
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
                  backgroundImage: seller.profileImageUrl != null
                      ? NetworkImage(seller.profileImageUrl!)
                      : null,
                  child: seller.profileImageUrl == null
                      ? const Icon(Icons.store, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // 🏷️ Shop name
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCurrentUser ? 48.0 : 0.0,
                    ),
                    child: Text(
                      seller.shopName,
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
                          title: "Edit Shop Name",
                          initialValue: seller.shopName,
                          onSave: (val) async {
                            await ref
                                .read(profileControllerProvider.notifier)
                                .updateShopName(val);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                seller.accountType.toWords(),
                style: TextStyle(color: colors.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),

              // 📦 Product count
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text("Products"),
                  subtitle: Text('$productCount total'),
                ),
              ),
              const SizedBox(height: _sectionSpacing),

              // 📞 Contact Info Group
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                child: Column(
                  children: [
                    EditableInfoTile(
                      title: 'Phone Number',
                      value: seller.phoneNumber ?? 'Not provided',
                      icon: Icons.phone_outlined,
                      editable: isCurrentUser,
                      onEdit: () => _editField(
                        context,
                        ref: ref,
                        title: "Edit Phone Number",
                        initialValue: seller.phoneNumber ?? '',
                        keyboardType: TextInputType.phone,
                        onSave: (val) async {
                          await ref
                              .read(profileControllerProvider.notifier)
                              .updatePhoneNumber(val);
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Email',
                      value: seller.email,
                      icon: Icons.email_outlined,
                      editable: false,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Address',
                      value: seller.address ?? 'No address set',
                      icon: Icons.location_on_outlined,
                      editable: isCurrentUser,
                      onEdit: () => _editField(
                        context,
                        ref: ref,
                        title: "Edit Address",
                        initialValue: seller.address ?? '',
                        onSave: (val) async {
                          final updatedSeller = seller.copyWith(address: val);
                          await ref
                              .read(profileControllerProvider.notifier)
                              .updateProfile(updatedSeller);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionSpacing),

              // 🗺️ Map display
              Card(
                elevation: _cardElevation,
                shadowColor: shadowColor,
                shape: cardShape,
                clipBehavior: Clip.antiAlias, // Important for map
                child: hasLocation
                    ? ShopLocationMap(seller: seller)
                    : Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text('No location set'),
                      ),
              ),
              if (isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("Set Location"),
                    onPressed: () async {
                      // ... (rest of the map logic)
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
                              "Do you also want to update your address from this location?",
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
                            .read(profileControllerProvider.notifier)
                            .updateShopLocation(
                              latitude: lat,
                              longitude: lon,
                              address:
                                  shouldUpdateAddress == true && address != null
                                  ? address
                                  : seller.address ?? '',
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
                      value: _formatDate(seller.createdAt),
                      icon: Icons.calendar_today_outlined,
                      editable: false,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    EditableInfoTile(
                      title: 'Last Updated',
                      value: _formatDate(seller.updatedAt),
                      icon: Icons.history_outlined,
                      editable: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionSpacing),

              // ⭐ Ratings
              if (seller.ratings != null && seller.ratings!.isNotEmpty)
                Card(
                  elevation: _cardElevation,
                  shadowColor: shadowColor,
                  shape: cardShape,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                          child: Text(
                            'Ratings',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ...seller.ratings!
                            .take(3)
                            .map(
                              (r) => ListTile(
                                leading: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                title: Text('${r.stars}/5'),
                                subtitle: Text(r.description ?? ''),
                              ),
                            ),
                      ],
                    ),
                  ),
                )
              else
                const Text('No ratings yet'),
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.errorContainer,
                        foregroundColor: colors.onErrorContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      label: const Text('Delete Account'),
                      onPressed: () =>
                          _confirmDeleteProfile(context, ref, seller.uid),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- (Helper methods remain unchanged) ---

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }
    try {
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (e) {
      return date.toIso8601String();
    }
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    String sellerId,
  ) async {
    // ... (This method remains unchanged)
    final controller = TextEditingController();
    final focusNode = FocusNode();
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // user must explicitly act
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "This action cannot be undone.\n\n"
                "To confirm, please type DELETE below:",
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Type DELETE",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  confirmed = val.trim().toUpperCase() == "DELETE";
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text("Confirm Delete"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (confirmed) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please type DELETE exactly to confirm."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    ).then((value) async {
      if (value == true) {
        await ref
            .read(profileControllerProvider.notifier)
            .deleteProfile(sellerId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile deleted successfully."),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WelcomeScreen()),
          );
        }
      }
    });
  }

  Future<void> _editField(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    // ... (This method remains unchanged)
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

              // 📞 PHONE FIELD
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

              // 🏠 MULTILINE ADDRESS FIELD
              if (isAddressField)
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    alignLabelWithHint: true,
                    hintText: 'Enter your full address here...',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              // 📝 REGULAR SINGLE-LINE FIELD
              if (!isPhoneField && !isAddressField)
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
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
