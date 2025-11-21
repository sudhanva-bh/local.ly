import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';

class InvoiceService {
  /// Generates the PDF and opens the native share/print dialog
  static Future<void> generateAndOpenInvoice(OrderModel order) async {
    final doc = pw.Document();

    // Load a font that supports the Rupee symbol (e.g., Roboto or Noto Sans)
    // Using PdfGoogleFonts requires internet on first run to cache the font.
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // Formatters
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    // Company Info (Static for now, replace with real app data)
    const companyName = "Locally";
    const companyAddress =
        "BITS Pilani Hyderabad Campus\nShamirpet\nHyderabad 500078";
    const companyEmail = "support@locally.app";

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
          margin: const pw.EdgeInsets.all(40),
        ),
        header: (context) => _buildHeader(context, companyName, companyAddress),
        footer: (context) => _buildFooter(context, companyEmail),
        build: (context) => [
          pw.SizedBox(height: 20),

          // Order Info & Customer Info Row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Invoice Details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "INVOICE",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _buildKeyValue(
                    "Invoice #",
                    order.id.substring(0, 8).toUpperCase(),
                  ),
                  _buildKeyValue("Date", dateFormat.format(order.createdAt)),
                  _buildKeyValue("Time", timeFormat.format(order.createdAt)),
                  _buildKeyValue("Status", order.status.name.toUpperCase()),
                ],
              ),
              // Bill To
              pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(maxWidth: 200),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "BILL TO",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      order.deliveryAddress,
                      textAlign: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Items Table
          pw.TableHelper.fromTextArray(
            context: context,
            border: null,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['Description', 'Qty', 'Unit Price', 'Amount'],
            data:
                order.items?.map((item) {
                  final total = item.priceAtPurchase * item.quantity;
                  return [
                    item.productName ?? "Product ID: ${item.productId}",
                    item.quantity.toString(),
                    currencyFormat.format(item.priceAtPurchase),
                    currencyFormat.format(total),
                  ];
                }).toList() ??
                [],
          ),

          pw.Divider(color: PdfColors.grey300),

          // Totals
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildTotalRow(
                  "Subtotal",
                  currencyFormat.format(order.totalAmount),
                ), // Assuming totalAmount is subtotal for now
                _buildTotalRow(
                  "Delivery Fee",
                  "Free",
                  color: PdfColors.green700,
                ),
                _buildTotalRow(
                  "Tax (Included 18%)",
                  "₹${(order.totalAmount * 0.18).toStringAsFixed(2)}",
                ),
                pw.Divider(height: 10),
                _buildTotalRow(
                  "Grand Total",
                  currencyFormat.format(order.totalAmount),
                  isBold: true,
                  fontSize: 16,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Terms / Notes
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              "Thank you for shopping with locally! If you have any questions about this invoice, please contact support.",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    // Open the preview/share sheet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice_${order.id.substring(0, 8)}.pdf',
    );
  }

  // --- Helper Widgets for PDF ---

  static pw.Widget _buildHeader(
    pw.Context context,
    String name,
    String address,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // You can load an image logo here if you have one
            pw.Text(
              name.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              address,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, String email) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Center(
          child: pw.Text(
            "Registered Office: $email | Generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildKeyValue(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: "$key: ",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
    PdfColor? color,
  }) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
