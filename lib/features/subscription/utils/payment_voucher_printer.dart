import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_formatter.dart';
import '../providers/subscription_provider.dart';

class PaymentVoucherPrinter {
  const PaymentVoucherPrinter._();

  static Future<void> printVoucher(PaymentRequestItem request) async {
    await printChalan(request);
  }

  static Future<void> printChalan(PaymentRequestItem request) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final issueTime = request.reviewedAt ?? now;
    final dateText = DateFormat('dd MMMM yyyy').format(issueTime);
    final timeText = DateFormat('hh:mm a').format(issueTime);
    final businessCode = IdFormatter.numericCode(request.businessId);
    final challanNo =
        'CH-$businessCode-${request.id.substring(0, 8).toUpperCase()}';
    final businessName = request.businessName.trim().isEmpty
        ? 'Business'
        : request.businessName.trim();
    final businessPhone = request.businessPhone.trim().isEmpty
        ? '+880 1000-000000'
        : request.businessPhone.trim();
    final businessEmail = request.businessEmail.trim().isEmpty
        ? 'business@example.com'
        : request.businessEmail.trim();
    final businessAddress = request.businessAddress.trim().isEmpty
        ? 'Address not provided'
        : request.businessAddress.trim();
    final requestedByName = request.requestedByName.trim().isEmpty
        ? request.requestedBy
        : request.requestedByName.trim();
    final reviewedByName = (request.reviewedByName ?? '').trim().isEmpty
        ? (request.reviewedBy ?? '-')
        : request.reviewedByName!.trim();
    final unitPrice = request.amount.toStringAsFixed(2);
    final totalPrice = request.amount.toStringAsFixed(2);
    const currency = AppConstants.defaultCurrencyCode;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(22),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'SOFTWARE SELLING/DELIVERY CHALLAN',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                AppConstants.appName.toUpperCase(),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              pw.Text('Seller ID: $businessCode'),
                              pw.Text('Phone: +880 1000-000000'),
                              pw.Text('Email: support@customerp.app'),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Challan No: $challanNo',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text('Date: $dateText'),
                            pw.Text('Time: $timeText'),
                            pw.Text('Status: ${request.status.toUpperCase()}'),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(height: 1, thickness: 0.7),
                    pw.SizedBox(height: 8),
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
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(businessName),
                              pw.Text('Business Code: $businessCode'),
                              pw.Text('Phone: $businessPhone'),
                              pw.Text('Email: $businessEmail'),
                              pw.Text('Address: $businessAddress'),
                              pw.Text('Business UID: ${request.businessId}'),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Buyer Information:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text('Contact Person: $requestedByName'),
                              pw.Text('Approved By: $reviewedByName'),
                              pw.Text('Transaction: ${request.transactionRef}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      color: PdfColors.grey300,
                      child: pw.Center(
                        child: pw.Text(
                          'SOFTWARE & DELIVERY DETAILS',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                        color: PdfColors.black,
                        width: 0.6,
                      ),
                      columnWidths: const {
                        0: pw.FixedColumnWidth(28),
                        1: pw.FlexColumnWidth(3.0),
                        2: pw.FlexColumnWidth(1.9),
                        3: pw.FlexColumnWidth(1.1),
                        4: pw.FlexColumnWidth(0.8),
                        5: pw.FlexColumnWidth(1.4),
                        6: pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        _tableHeaderRow(),
                        pw.TableRow(
                          children: [
                            _tableCell('1', align: pw.TextAlign.center),
                            _tableCell(
                              '${request.planName}\n(${request.durationDays} days access)',
                            ),
                            _tableCell(
                              'PKG-${request.planId.toUpperCase().replaceAll('_', '-')}',
                            ),
                            _tableCell(
                              request.paymentMethod.toUpperCase(),
                              align: pw.TextAlign.center,
                            ),
                            _tableCell('1', align: pw.TextAlign.center),
                            _tableCell(unitPrice, align: pw.TextAlign.right),
                            _tableCell(totalPrice, align: pw.TextAlign.right),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            _tableCell(''),
                            _tableCell(''),
                            _tableCell(''),
                            _tableCell(''),
                            _tableCell(''),
                            _tableCell(
                              'GRAND TOTAL:',
                              align: pw.TextAlign.right,
                              bold: true,
                            ),
                            _tableCell(
                              totalPrice,
                              align: pw.TextAlign.right,
                              bold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Mode of Delivery: [X] Digital Delivery/Email   [ ] Printed Copy',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Terms & Conditions:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Bullet(
                        text:
                            'This challan confirms delivery of the software subscription listed above.'),
                    pw.Bullet(
                        text:
                            'Invoice and accounting entries may be issued separately.'),
                    pw.Bullet(
                        text:
                            'Please verify the package details at the time of receipt.'),
                    if ((request.note ?? '').trim().isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text('Note: ${request.note!.trim()}'),
                      ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Signatures and Acceptance:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _signatureBox(
                            title: 'For ${AppConstants.appName} (Seller)',
                            signLabel: 'Authorized Signature',
                            line1: 'Name: $reviewedByName',
                            line2: 'Designation: Super Admin',
                            line3: 'Date: $dateText',
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: _signatureBox(
                            title: 'Received by $businessName (Buyer)',
                            signLabel: 'Receiver Signature',
                            line1: 'Name: $requestedByName',
                            line2: 'Designation: Business Owner',
                            line3: 'Date & Time: $dateText $timeText',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'This is a system-generated challan for package licensing. Currency: $currency.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name:
          'payment-chalan-${request.businessId}-${request.id.substring(0, 8)}.pdf',
    );
  }

  static pw.TableRow _tableHeaderRow() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('S.No', bold: true, align: pw.TextAlign.center),
        _tableCell(
          'Description of Software / License',
          bold: true,
          align: pw.TextAlign.center,
        ),
        _tableCell('SKU / License Key', bold: true, align: pw.TextAlign.center),
        _tableCell('Version', bold: true, align: pw.TextAlign.center),
        _tableCell('Qty', bold: true, align: pw.TextAlign.center),
        _tableCell('Unit Price', bold: true, align: pw.TextAlign.center),
        _tableCell('Total Amount', bold: true, align: pw.TextAlign.center),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _signatureBox({
    required String title,
    required String signLabel,
    required String line1,
    required String line2,
    required String line3,
  }) {
    return pw.Container(
      height: 120,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Center(child: pw.Text('__________________________')),
          pw.Center(
              child:
                  pw.Text(signLabel, style: const pw.TextStyle(fontSize: 9))),
          pw.SizedBox(height: 6),
          pw.Text(line1, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(line2, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(line3, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
