import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_detail_components.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_tracker.dart';
import 'package:locally/features/consumer/view_orders/widgets/realtime_order_item_row.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SellerOrderDetailsScreen extends ConsumerWidget {
  final OrderModel initialOrder;

  const SellerOrderDetailsScreen({super.key, required this.initialOrder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to the stream
    final orderAsync = ref.watch(sellerOrderDetailsProvider(initialOrder.id));

    // 2. Use .when to handle the 3 states (Data, Loading, Error)
    return orderAsync.when(
      // ⏳ STATE: LOADING
      loading: () => Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(title: const Text("Loading Order...")),
        body: const Center(child: CircularProgressIndicator()),
      ),

      // ❌ STATE: ERROR
      error: (error, stack) => Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text("Error loading order: $error")),
      ),

      // ✅ STATE: DATA READY (The stream has loaded)
      data: (order) {
        // Now 'order' is the full object from the stream.
        // It should have the correct sellerId and consumerId.

        final String qrData =
            "${order.id}|${order.sellerId}|${order.consumerId}";

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: AppBar(
            title: const Text("Manage Order"),
            centerTitle: true,
            backgroundColor: context.colors.surface,
            actions: [
              IconButton(
                tooltip: "Show QR Code",
                icon: const Icon(Icons.qr_code_2),
                onPressed: () => _showQrDialog(context, qrData),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderHeaderCard(
                  orderId: order.id,
                  date: DateFormat('MMM dd, yyyy').format(order.createdAt),
                  time: DateFormat('hh:mm a').format(order.createdAt),
                  status: order.status,
                  sellerId: order.sellerId,
                  child: OrderTracker(status: order.status),
                ),
                const SizedBox(height: 20),
                SectionLabel(label: "Customer Details"),
                const SizedBox(height: 8),
                AddressCard(address: order.deliveryAddress),
                const SizedBox(height: 24),
                SectionLabel(label: "Items to Pack"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.colors.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (order.items != null)
                        ...order.items!.map(
                          (item) => RealtimeOrderItemRow(
                            item: item,
                            isEmbedded: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                BillSummaryCard(totalAmount: order.totalAmount),
                const SizedBox(height: 80),
              ],
            ),
          ),
          bottomNavigationBar: _buildManagementBar(
            context,
            ref,
            order,
            qrData,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🕹️ ACTION BUTTONS
  // ---------------------------------------------------------------------------
  Widget _buildManagementBar(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    String qrData,
  ) {
    // If delivered or cancelled, hide bar
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 🖨️ PRINT BUTTON
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _printShippingLabel(order, qrData),
                icon: const Icon(Icons.print),
                label: const Text("Print Label"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // ✅ ACCEPT BUTTON
            // Because 'order' is realtime, this button will automatically
            // disappear when the status changes to 'accepted' in the DB.
            if (order.status == OrderStatus.pending) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    // 1. Call Service
                    final result = await ref
                        .read(orderServiceProvider)
                        .receiveOrder(order.id);

                    // 2. Handle Error (Success is handled by Stream update)
                    result.fold(
                      (error) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed: $error")),
                      ),
                      (success) {
                        // Optional: Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order Accepted")),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Accept Order"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🖨️ PDF & QR HELPERS (Kept exactly as you had them)
  // ---------------------------------------------------------------------------
  Future<void> _printShippingLabel(OrderModel order, String qrData) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Center(
                  child: pw.Text(
                    'SHIPPING LABEL',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('FROM: Seller ID #${order.sellerId}'),
                pw.SizedBox(height: 5),
                pw.Text(
                  'TO:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(order.deliveryAddress.toString()),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'ORDER DETAILS:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Order ID: ${order.id}'),
                pw.Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(order.createdAt)}',
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 100,
                    height: 100,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    order.id,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Shipping-Label-${order.id}',
    );
  }

  void _showQrDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text("Scan for Verification"),
        content: SizedBox(
          height: 250,
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                "Seller | Consumer | Order",
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
