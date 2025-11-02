import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:locally/common/widgets/location_picker.dart';
import 'package:locally/common/extensions/content_extensions.dart'; // assuming this gives context.colors

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({
    super.key,
    required this.formKey,
    required this.phoneNumberController,
    required this.shopNameController,
    required this.addressController,
    required this.onLocationPicked,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneNumberController;
  final TextEditingController shopNameController;
  final TextEditingController addressController;
  final void Function({
    required double latitude,
    required double longitude,
    required String address,
  })
  onLocationPicked;

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  String _countryCode = '+91';
  double? _latitude;
  double? _longitude;
  String? _address;

  InputDecoration _inputDecoration({
    String? label,
    String? hint,
    required IconData icon,
    bool dense = false,
    bool floatingLabel = true,
  }) {
    return InputDecoration(
      labelText: floatingLabel ? label : null,
      hintText: floatingLabel ? null : hint,
      floatingLabelBehavior: floatingLabel
          ? FloatingLabelBehavior.auto
          : FloatingLabelBehavior.never,
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      filled: true,
      fillColor: context.colors.surface, // ✅ Applied theme surface color
      isDense: dense,
      contentPadding: dense
          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
          : const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(23),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(23),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(23),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[600]),
      labelStyle: TextStyle(color: Colors.grey[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📞 Phone number (static hint, no floating label)
            IntlPhoneField(
              decoration: _inputDecoration(
                hint: 'Phone Number',
                icon: Icons.phone,
                dense: true,
                floatingLabel: false,
              ),
              initialCountryCode: 'IN',
              onChanged: (phone) {
                _countryCode = phone.countryCode;
                widget.phoneNumberController.text =
                    "$_countryCode${phone.number}";
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
            const SizedBox(height: 4),

            // 🏪 Shop name
            TextFormField(
              textCapitalization: TextCapitalization.words,
              controller: widget.shopNameController,
              decoration: _inputDecoration(
                label: 'Shop Name',
                icon: Icons.store,
                dense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your shop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 📍 Location picker
            LocationPickerField(
              latitude: _latitude,
              longitude: _longitude,
              address: _address,
              onLocationPicked:
                  ({
                    required double latitude,
                    required double longitude,
                    required String address,
                    required bool updateAddressField,
                  }) {
                    setState(() {
                      _latitude = latitude;
                      _longitude = longitude;
                      _address = address;
                    });
                    if (updateAddressField) {
                      widget.addressController.text = address;
                    }
                    widget.onLocationPicked(
                      latitude: latitude,
                      longitude: longitude,
                      address: address,
                    );
                  },
            ),

            const SizedBox(height: 14),
            // 🏡 Address
            TextFormField(
              textCapitalization: TextCapitalization.sentences,
              controller: widget.addressController,
              decoration:
                  _inputDecoration(
                    label: 'Address',
                    icon: Icons.home,
                  ).copyWith(
                    fillColor:
                        context.colors.surface, // ✅ Ensure consistent fill
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                  ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}