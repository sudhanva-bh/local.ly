
// --- SIMULATION DIALOGS ---

import 'package:flutter/material.dart';

class OtpDialog extends StatefulWidget {
  const OtpDialog({super.key});

  @override
  State<OtpDialog> createState() => OtpDialogState();
}

class OtpDialogState extends State<OtpDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter OTP"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("A dummy OTP has been sent to your mobile number."),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "OTP",
              hintText: "1234",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.pop(context, false), // Cancel
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_otpController.text.isNotEmpty) {
                    setState(() => _isLoading = true);
                    await Future.delayed(
                      const Duration(seconds: 2),
                    ); // Verify simulation
                    if (context.mounted) {
                      Navigator.pop(context, true); // Success
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }
}
