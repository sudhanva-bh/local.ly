import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📞 Phone number
          IntlPhoneField(
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
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
          const SizedBox(height: 16),

          // 🏪 Shop name
          TextFormField(
            textCapitalization: TextCapitalization.words,
            controller: widget.shopNameController,
            decoration: const InputDecoration(
              labelText: 'Shop Name',
              prefixIcon: Icon(Icons.store),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your shop name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 🏡 Address
          TextFormField(
            textCapitalization: TextCapitalization.sentences,
            controller: widget.addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 📍 Mini Map Preview
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
        ],
      ),
    );
  }
}
