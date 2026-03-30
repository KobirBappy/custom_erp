import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../contacts/models/contact.dart';
import '../../purchases/models/purchase.dart';
import '../../sales/models/sale.dart';

class LedgerExportPrinter {
  const LedgerExportPrinter._();

  static Future<void> printCustomerLedger({
    required List<Contact> customers,
    required List<Sale> sales,
  }) async {
    const sym = AppConstants.defaultCurrencySymbol;
    final doc = pw.Document();
    final rows = customers.map((c) {
      final totalSales = sales
          .where(
              (s) => s.customerName == c.name && s.status == SaleStatus.final_)
          .fold<double>(0.0, (sum, s) => sum + s.grandTotal);
      final paid = sales
          .where(
              (s) => s.customerName == c.name && s.status == SaleStatus.final_)
          .fold<double>(0.0, (sum, s) => sum + s.paidAmount);
      final due = totalSales - paid;
      return <String>[
        c.name,
        c.phone.isEmpty ? '-' : c.phone,
        c.email.isEmpty ? '-' : c.email,
        '$sym${totalSales.toStringAsFixed(2)}',
        '$sym${paid.toStringAsFixed(2)}',
        '$sym${due.toStringAsFixed(2)}',
      ];
    }).toList();

    _buildLedgerDoc(
      doc: doc,
      title: 'Customer Ledger',
      headers: const ['Name', 'Phone', 'Email', 'Sales', 'Paid', 'Due'],
      rows: rows,
    );
    await Printing.layoutPdf(
      name:
          'customer-ledger-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      onLayout: (_) async => doc.save(),
    );
  }

  static Future<void> printSupplierLedger({
    required List<Contact> suppliers,
    required List<Purchase> purchases,
  }) async {
    const sym = AppConstants.defaultCurrencySymbol;
    final doc = pw.Document();
    final rows = suppliers.map((s) {
      final totalPurchase = purchases
          .where((p) => p.supplierName == s.name)
          .fold<double>(0.0, (sum, p) => sum + p.grandTotal);
      final paid = purchases
          .where((p) => p.supplierName == s.name)
          .fold<double>(0.0, (sum, p) => sum + p.paidAmount);
      final due = totalPurchase - paid;
      return <String>[
        s.name,
        s.phone.isEmpty ? '-' : s.phone,
        s.email.isEmpty ? '-' : s.email,
        '$sym${totalPurchase.toStringAsFixed(2)}',
        '$sym${paid.toStringAsFixed(2)}',
        '$sym${due.toStringAsFixed(2)}',
      ];
    }).toList();

    _buildLedgerDoc(
      doc: doc,
      title: 'Supplier Ledger',
      headers: const ['Name', 'Phone', 'Email', 'Purchases', 'Paid', 'Due'],
      rows: rows,
    );
    await Printing.layoutPdf(
      name:
          'supplier-ledger-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      onLayout: (_) async => doc.save(),
    );
  }

  static void _buildLedgerDoc({
    required pw.Document doc,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
          ),
        ],
      ),
    );
  }
}
