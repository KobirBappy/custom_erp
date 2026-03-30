import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_formatter.dart';
import '../../businesses/models/business.dart';
import '../models/sale.dart';

class SaleChalanPrinter {
  const SaleChalanPrinter._();

  static Future<void> print({
    required Sale sale,
    Business? business,
  }) async {
    final doc = pw.Document();
    final businessName =
        business?.name.isNotEmpty == true ? business!.name : 'Business';
    final businessCode = IdFormatter.numericCode(sale.businessId);
    final date = DateFormat('dd MMM yyyy').format(sale.saleDate);
    final time = DateFormat('hh:mm a').format(sale.saleDate);
    final businessPhone = (business?.phone ?? '').trim().isEmpty
        ? '+880 1000-000000'
        : business!.phone;
    final businessEmail = (business?.email ?? '').trim().isEmpty
        ? 'business@example.com'
        : business!.email;
    final businessAddress = (business?.address ?? '').trim().isEmpty
        ? 'Address not provided'
        : business!.address;

    await Printing.layoutPdf(
      name: 'sale-chalan-${sale.invoiceNo}.pdf',
      onLayout: (pageFormat) async {
        _buildDocument(
          doc: doc,
          pageFormat: pageFormat,
          sale: sale,
          businessName: businessName,
          businessCode: businessCode,
          date: date,
          time: time,
          businessPhone: businessPhone,
          businessEmail: businessEmail,
          businessAddress: businessAddress,
        );
        return doc.save();
      },
    );
  }

  static void _buildDocument({
    required pw.Document doc,
    required PdfPageFormat pageFormat,
    required Sale sale,
    required String businessName,
    required String businessCode,
    required String date,
    required String time,
    required String businessPhone,
    required String businessEmail,
    required String businessAddress,
  }) {
    final usableWidth = pageFormat.availableWidth;
    final scale = (usableWidth / PdfPageFormat.a4.availableWidth)
        .clamp(0.78, 1.12)
        .toDouble();

    final titleSize = 20.0 * scale;
    final textSize = 9.0 * scale;
    final headingSize = 10.0 * scale;
    final smallSize = 8.0 * scale;
    final padding = 22.0 * scale;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(padding),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              'SOFTWARE SELLING/DELIVERY CHALLAN',
              style: pw.TextStyle(
                fontSize: titleSize,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10 * scale),
          pw.Container(
            padding: pw.EdgeInsets.all(10 * scale),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            businessName.toUpperCase(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: headingSize,
                            ),
                          ),
                          pw.Text('Business Code: $businessCode',
                              style: pw.TextStyle(fontSize: textSize)),
                          pw.Text('Phone: $businessPhone',
                              style: pw.TextStyle(fontSize: textSize)),
                          pw.Text('Email: $businessEmail',
                              style: pw.TextStyle(fontSize: textSize)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8 * scale),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Challan No: ${sale.invoiceNo}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: textSize,
                          ),
                        ),
                        pw.Text('Date: $date',
                            style: pw.TextStyle(fontSize: textSize)),
                        pw.Text('Time: $time',
                            style: pw.TextStyle(fontSize: textSize)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6 * scale),
                pw.Divider(height: 1, thickness: 0.7),
                pw.SizedBox(height: 6 * scale),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bill To / Consignee:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: textSize,
                            ),
                          ),
                          pw.Text(sale.customerName,
                              style: pw.TextStyle(fontSize: textSize)),
                          pw.Text(
                            'Customer ID: ${sale.customerId.isEmpty ? '-' : sale.customerId}',
                            style: pw.TextStyle(fontSize: textSize),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 10 * scale),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Seller Information:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: textSize,
                            ),
                          ),
                          pw.Text(businessName,
                              style: pw.TextStyle(fontSize: textSize)),
                          pw.Text('Address: $businessAddress',
                              style: pw.TextStyle(fontSize: textSize)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10 * scale),
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.symmetric(vertical: 4 * scale),
                  color: PdfColors.grey300,
                  child: pw.Center(
                    child: pw.Text(
                      'SOFTWARE & DELIVERY DETAILS',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: textSize,
                      ),
                    ),
                  ),
                ),
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.black, width: 0.6),
                  columnWidths: {
                    0: pw.FixedColumnWidth(28 * scale),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(0.8),
                    4: const pw.FlexColumnWidth(1.3),
                    5: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    _headerRow(scale),
                    ...sale.lines.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final line = entry.value;
                      return pw.TableRow(
                        children: [
                          _cell('$index', scale, center: true),
                          _cell(line.productName, scale),
                          _cell(line.sku, scale, center: true),
                          _cell(line.qty.toStringAsFixed(0), scale,
                              center: true),
                          _cell(line.unitPrice.toStringAsFixed(2), scale,
                              right: true),
                          _cell(line.lineTotal.toStringAsFixed(2), scale,
                              right: true),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 8 * scale),
                _amountRow('Sub Total', sale.subTotal.toStringAsFixed(2), scale,
                    bold: false),
                if (sale.taxAmount > 0)
                  _amountRow('Tax', sale.taxAmount.toStringAsFixed(2), scale),
                if (sale.discountAmount > 0)
                  _amountRow('Discount',
                      '-${sale.discountAmount.toStringAsFixed(2)}', scale),
                if (sale.transportCost > 0)
                  _amountRow('Transport', sale.transportCost.toStringAsFixed(2),
                      scale),
                _amountRow(
                  'Grand Total',
                  sale.grandTotal.toStringAsFixed(2),
                  scale,
                  bold: true,
                ),
                _amountRow(
                    'Paid Amount', sale.paidAmount.toStringAsFixed(2), scale),
                _amountRow(
                  'Due Amount',
                  sale.dueAmount.toStringAsFixed(2),
                  scale,
                  bold: sale.dueAmount > 0,
                ),
                pw.SizedBox(height: 6 * scale),
                pw.Text(
                  'Payment: ${sale.paymentStatus.name.toUpperCase()} (${sale.paymentMethod.toUpperCase()})',
                  style: pw.TextStyle(fontSize: textSize),
                ),
                pw.SizedBox(height: 8 * scale),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _signBox(
                        'For $businessName (Seller)',
                        'Authorized Signature',
                        scale,
                      ),
                    ),
                    pw.SizedBox(width: 10 * scale),
                    pw.Expanded(
                      child: _signBox(
                        'Received By (Buyer)',
                        'Receiver Signature',
                        scale,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6 * scale),
                pw.Text(
                  'Generated by ${AppConstants.appName}',
                  style: pw.TextStyle(
                    fontSize: smallSize,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _headerRow(double scale) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell('S.No', scale, center: true, bold: true),
        _cell('Description', scale, center: true, bold: true),
        _cell('SKU', scale, center: true, bold: true),
        _cell('Qty', scale, center: true, bold: true),
        _cell('Unit Price', scale, center: true, bold: true),
        _cell('Total', scale, center: true, bold: true),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    double scale, {
    bool center = false,
    bool right = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(4 * scale),
      child: pw.Text(
        text,
        textAlign: right
            ? pw.TextAlign.right
            : center
                ? pw.TextAlign.center
                : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9 * scale,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _amountRow(
    String label,
    String value,
    double scale, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 2 * scale),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 120 * scale,
            child: pw.Text(
              '$label:',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9 * scale,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 10 * scale),
          pw.SizedBox(
            width: 80 * scale,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9 * scale,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signBox(String title, String signLabel, double scale) {
    return pw.Container(
      height: 95 * scale,
      padding: pw.EdgeInsets.all(8 * scale),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9 * scale,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Spacer(),
          pw.Center(child: pw.Text('__________________________')),
          pw.Center(
            child: pw.Text(
              signLabel,
              style: pw.TextStyle(fontSize: 9 * scale),
            ),
          ),
        ],
      ),
    );
  }
}
