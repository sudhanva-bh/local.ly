// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:locally/common/providers/profile_provider.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // 📦 For UI QR
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw; // 📦 For PDF Generation
// import 'package:printing/printing.dart'; // 📦 For Printing

// import 'package:locally/common/extensions/content_extensions.dart';
// import 'package:locally/common/models/orders/consumer_order_model.dart';
// import 'package:locally/common/services/orders/consumer_order_service.dart';

// // ⬇️ Import your UI components
// import 'package:locally/features/consumer/view_orders/consumer_orders_page.dart';

// class SellerOrderDetailsScreen extends ConsumerWidget {
//   final OrderModel order;

//   const SellerOrderDetailsScreen({super.key, required this.order});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // 🔑 Generate the composite ID for the QR Code
//     final String? currentUserProfile = ref
//         .watch(currentUserProfileProvider)
//         .value
//         ?.uid;
//     final String qrData = "${order.id}|$currentUserProfile";
//     // order.id;

//     return Scaffold(
//       backgroundColor: context.colors.surface,
//       appBar: AppBar(
//         title: const Text("Manage Order"),
//         centerTitle: true,
//         backgroundColor: context.colors.surface,
//         actions: [
//           // -------------------- 🆕 SHOW QR BUTTON --------------------
//           IconButton(
//             tooltip: "Show QR Code",
//             icon: const Icon(Icons.qr_code_2),
//             onPressed: () => _showQrDialog(context, qrData),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             OrderHeaderCard(
//               orderId: order.id,
//               date: DateFormat('MMM dd, yyyy').format(order.createdAt),
//               time: DateFormat('hh:mm a').format(order.createdAt),
//               status: order.status,
//               sellerId: order.sellerId,
//               child: OrderTracker(status: order.status),
//             ),
//             const SizedBox(height: 20),
//             SectionLabel(label: "Customer Details"),
//             const SizedBox(height: 8),
//             AddressCard(address: order.deliveryAddress),
//             const SizedBox(height: 24),
//             SectionLabel(label: "Items to Pack"),
//             const SizedBox(height: 8),
//             Container(
//               decoration: BoxDecoration(
//                 color: context.colors.surfaceContainerLow,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: context.colors.outlineVariant.withOpacity(0.3),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   if (order.items != null)
//                     ...order.items!.map(
//                       (item) => RealtimeOrderItemRow(
//                         item: item,
//                         isEmbedded: true,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
//             BillSummaryCard(totalAmount: order.totalAmount),
//             const SizedBox(height: 80),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildManagementBar(
//         context,
//         ref,
//         order,
//         qrData,
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // 🖨️ PDF GENERATION LOGIC
//   // ---------------------------------------------------------------------------
//   Future<void> _printShippingLabel(OrderModel order, String qrData) async {
//     final doc = pw.Document();

//     // 📦 Load a standard font (prevents crashes with special chars like ₹)
//     // If you don't want to add the google_fonts dependency, you can remove the 'font' and 'bold' properties below,
//     // but your app might crash if the address contains non-standard characters.
//     final font = await PdfGoogleFonts.robotoRegular();
//     final bold = await PdfGoogleFonts.robotoBold();

//     doc.addPage(
//       pw.Page(
//         // ⚠️ If you want a fixed sticker size (e.g., 4x6 inch), use PdfPageFormat(101.6 * PdfPageFormat.mm, 152.4 * PdfPageFormat.mm)
//         pageFormat: PdfPageFormat.roll80,
//         theme: pw.ThemeData.withFont(base: font, bold: bold),
//         build: (pw.Context context) {
//           return pw.Container(
//             padding: const pw.EdgeInsets.all(10),
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(width: 2),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               mainAxisSize: pw.MainAxisSize.min, // Important for rolls
//               children: [
//                 pw.Center(
//                   child: pw.Text(
//                     'SHIPPING LABEL',
//                     style: pw.TextStyle(
//                       fontSize: 20,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 pw.Divider(),
//                 pw.SizedBox(height: 10),
//                 pw.Text('FROM: Seller ID #${order.sellerId}'),
//                 pw.SizedBox(height: 5),
//                 pw.Text(
//                   'TO:',
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 ),

//                 // ⚠️ Ensure this string doesn't contain NULLs or strictly unsupported chars
//                 pw.Text(order.deliveryAddress.toString()),

//                 pw.SizedBox(height: 10),
//                 pw.Divider(),
//                 pw.SizedBox(height: 10),
//                 pw.Text(
//                   'ORDER DETAILS:',
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 ),
//                 pw.Text('Order ID: ${order.id}'),
//                 pw.Text(
//                   'Date: ${DateFormat('yyyy-MM-dd').format(order.createdAt)}',
//                 ),
//                 pw.SizedBox(height: 10),
//                 // pw.Text('ITEMS:'),

//                 // 💡 Tip: Use item.name instead of item.id if available for better readability
//                 // if (order.items != null)
//                 //   ...order.items!.map(
//                 //     (e) => pw.Text('- ${e.name ?? e.id} (x${e.quantity})'),
//                 //   ),

//                 // ❌ REMOVED: pw.Spacer() (Caused the crash on infinite height pages)
//                 pw.SizedBox(height: 20), // ✅ Use fixed spacing instead
//                 // -------------------- PDF QR CODE --------------------
//                 pw.Center(
//                   child: pw.BarcodeWidget(
//                     barcode: pw.Barcode.qrCode(),
//                     data: qrData,
//                     width: 100,
//                     height: 100,
//                   ),
//                 ),
//                 pw.SizedBox(height: 5),
//                 pw.Center(
//                   child: pw.Text(
//                     order.id,
//                     style: const pw.TextStyle(fontSize: 8),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => doc.save(),
//       name: 'Shipping-Label-${order.id}',
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // 📱 UI QR DIALOG
//   // ---------------------------------------------------------------------------
//   void _showQrDialog(BuildContext context, String qrData) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: context.colors.surface,
//         title: const Text("Scan for Verification"),
//         content: SizedBox(
//           height: 250,
//           width: 250,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               QrImageView(
//                 data: qrData,
//                 version: QrVersions.auto,
//                 size: 200.0,
//                 backgroundColor: Colors.white, // Ensure contrast
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "Seller | Consumer | Order",
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: context.colors.onSurfaceVariant,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildManagementBar(
//     BuildContext context,
//     WidgetRef ref,
//     OrderModel order,
//     String qrData,
//   ) {
//     if (order.status == OrderStatus.delivered ||
//         order.status == OrderStatus.cancelled) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: context.colors.surface,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           children: [
//             // -------------------- SHIPPING LABEL BUTTON --------------------
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: () async {
//                   // ⚡ Trigger Print Logic
//                   await _printShippingLabel(order, qrData);
//                 },
//                 icon: const Icon(Icons.print),
//                 label: const Text("Print Label"),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 12),

//             // -------------------- DYNAMIC ACTION BUTTON --------------------
//             if (order.status == OrderStatus.pending)
//               Expanded(
//                 child: FilledButton.icon(
//                   onPressed: () async {
//                     await ref.read(orderServiceProvider).receiveOrder(order.id);
//                   },
//                   icon: const Icon(Icons.check),
//                   label: const Text("Accept Order"),
//                   style: FilledButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
