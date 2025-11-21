import 'package:flutter/material.dart';
import 'package:locally/features/consumer/view_orders/pages/order_details_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryScanAction extends StatefulWidget {
  const DeliveryScanAction({super.key});

  @override
  State<DeliveryScanAction> createState() => _DeliveryScanActionState();
}

class _DeliveryScanActionState extends State<DeliveryScanAction> {
  bool _isProcessing = false;

  Future<void> _handleScan(String rawCode, BuildContext dialogContext) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    Navigator.of(dialogContext).pop();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing QR Code...')),
      );

      // Call RPC → now returns orderId (uuid)
      final orderId = await Supabase.instance.client.rpc(
        'receive_delivery_scan',
        params: {'qr_data_input': rawCode},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order $orderId delivered!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to OrderDetailsScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId),
        ),
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database Error: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showScannerDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Scan Delivery QR",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      controller: MobileScannerController(
                        detectionSpeed: DetectionSpeed.noDuplicates,
                        returnImage: false,
                      ),
                      onDetect: (capture) {
                        final code = capture.barcodes.first.rawValue;
                        if (code != null) _handleScan(code, ctx);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: _isProcessing ? null : _showScannerDialog,
      tooltip: "Scan Delivery",
    );
  }
}
