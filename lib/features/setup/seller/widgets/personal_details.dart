import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:locally/common/widgets/location_picker.dart';

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

  // --- UPDATED GLASS STYLE DECORATION ---
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
      // White icons to stand out on glass
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
      filled: true,
      // Semi-transparent white fill
      fillColor: Colors.white.withOpacity(0.1),
      isDense: dense,
      contentPadding: dense
          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
          : const EdgeInsets.symmetric(vertical: 18, horizontal: 20),

      // --- BORDERS (Subtle white strokes) ---
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), // Matching parent radius style
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),

      // Light text for readability on dark/gradient backgrounds
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define a white text style for the input text itself
    const TextStyle whiteTextStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📞 Phone number
            IntlPhoneField(
              style: whiteTextStyle, // Input text color
              dropdownTextStyle: whiteTextStyle, // Country code color
              dropdownIcon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.7),
              ),
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
            const SizedBox(height: 12),

            // 🏪 Shop name
            TextFormField(
              style: whiteTextStyle, // Input text color
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
            // Note: Ensure LocationPickerField also accepts/uses these styles
            // or wraps its internal button in similar glass styles.
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

            const SizedBox(height: 16),

            // 🏡 Address
            TextFormField(
              style: whiteTextStyle, // Input text color
              textCapitalization: TextCapitalization.sentences,
              controller: widget.addressController,
              decoration:
                  _inputDecoration(
                    label: 'Address',
                    icon: Icons.home,
                  ).copyWith(
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
