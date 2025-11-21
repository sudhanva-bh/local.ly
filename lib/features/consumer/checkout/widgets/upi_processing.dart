
import 'package:flutter/material.dart';

class UpiProcessingDialog extends StatefulWidget {
  final double amount;
  const UpiProcessingDialog({super.key, required this.amount});

  @override
  State<UpiProcessingDialog> createState() => UpiProcessingDialogState();
}

class UpiProcessingDialogState extends State<UpiProcessingDialog> {
  @override
  void initState() {
    super.initState();
    _simulateUpiProcess();
  }

  Future<void> _simulateUpiProcess() async {
    // Simulate user switching to UPI app and approving
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pop(context, true); // Auto-close with Success after 4 seconds
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            "Waiting for confirmation...",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text("Please approve request of ₹${widget.amount} in your UPI app."),
        ],
      ),
    );
  }
}

