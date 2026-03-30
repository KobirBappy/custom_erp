import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../contacts/providers/contact_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../purchases/providers/purchase_provider.dart';
import '../../sales/models/sale.dart';
import '../../sales/providers/sale_provider.dart';
import '../utils/ledger_export_printer.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ReportGrid(),
          const SizedBox(height: 24),
          _QuickSummary(),
        ],
      ),
    );
  }
}

// ── Report grid ───────────────────────────────────────────────────────────────

class _ReportGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _ReportItem('Purchase & Sale', Icons.bar_chart_outlined,
          AppColors.cardBlue, () => _openSheet(context, _PurchaseSaleReport())),
      _ReportItem('Tax Report', Icons.percent_outlined, AppColors.cardGreen,
          () => _openSheet(context, _TaxReport())),
      _ReportItem('Contact Reports', Icons.contacts_outlined,
          AppColors.cardOrange, () => _openSheet(context, _ContactReport())),
      _ReportItem('Stock Reports', Icons.inventory_2_outlined,
          AppColors.cardPurple, () => _openSheet(context, _StockReport())),
      _ReportItem('Expense Report', Icons.receipt_long_outlined,
          AppColors.cardRed, () => _openSheet(context, _ExpenseReport())),
      _ReportItem(
          'Trending Products',
          Icons.trending_up_outlined,
          AppColors.cardCyan,
          () => _openSheet(context, _TrendingProductsReport())),
      _ReportItem('Cash Register', Icons.point_of_sale_outlined,
          AppColors.cardTeal, () => _openSheet(context, _CashRegisterReport())),
      _ReportItem(
          'Sales Register',
          Icons.list_alt_outlined,
          AppColors.cardYellow,
          () => _openSheet(context, _SalesRegisterReport())),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: item.color.withOpacity(0.15),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _openSheet(BuildContext context, Widget report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ProviderScope(
            child: _ReportSheetShell(scrollCtrl: ctrl, body: report)),
      ),
    );
  }
}

class _ReportSheetShell extends StatelessWidget {
  const _ReportSheetShell({required this.scrollCtrl, required this.body});
  final ScrollController scrollCtrl;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: body,
          ),
        ),
      ],
    );
  }
}

class _ReportItem {
  const _ReportItem(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

// ── Quick Summary ─────────────────────────────────────────────────────────────

class _QuickSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    final purchases = ref.watch(purchasesProvider);
    final expenses = ref.watch(expensesProvider);
    final products = ref.watch(productsProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    final totalSales = sales
        .where((s) => s.status == SaleStatus.final_)
        .fold(0.0, (acc, s) => acc + s.grandTotal);
    final totalPurchases = purchases.fold(0.0, (acc, p) => acc + p.grandTotal);
    final totalExpenses = expenses.fold(0.0, (acc, e) => acc + e.amount);
    final profit = totalSales - totalPurchases - totalExpenses;
    final lowStock = products.where((p) => p.isLowStock).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow('Total Sales', totalSales, sym, AppColors.success),
                const Divider(height: 20),
                _SummaryRow(
                    'Total Purchases', totalPurchases, sym, AppColors.error),
                const Divider(height: 20),
                _SummaryRow(
                    'Total Expenses', totalExpenses, sym, AppColors.warning),
                const Divider(height: 20),
                _SummaryRow('Net Profit', profit, sym,
                    profit >= 0 ? AppColors.success : AppColors.error),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Low Stock Products',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            (lowStock > 0 ? AppColors.error : AppColors.success)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$lowStock items',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: lowStock > 0
                                  ? AppColors.error
                                  : AppColors.success)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount, this.sym, this.color);
  final String label;
  final double amount;
  final String sym;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          CurrencyFormatter.formatSimple(amount, symbol: sym),
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Individual Report Widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Purchase & Sale Report ────────────────────────────────────────────────────

class _PurchaseSaleReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref
        .watch(salesProvider)
        .where((s) => s.status == SaleStatus.final_)
        .toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    final purchases = ref.watch(purchasesProvider)
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    const sym = AppConstants.defaultCurrencySymbol;

    final totalSales = sales.fold(0.0, (acc, s) => acc + s.grandTotal);
    final totalPurchases = purchases.fold(0.0, (acc, p) => acc + p.grandTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Purchase & Sale Report', Icons.bar_chart_outlined),
        _SummaryChips([
          _Chip(
              'Sales',
              CurrencyFormatter.formatSimple(totalSales, symbol: sym),
              AppColors.success),
          _Chip(
              'Purchases',
              CurrencyFormatter.formatSimple(totalPurchases, symbol: sym),
              AppColors.error),
          _Chip(
              'Profit',
              CurrencyFormatter.formatSimple(totalSales - totalPurchases,
                  symbol: sym),
              totalSales >= totalPurchases
                  ? AppColors.success
                  : AppColors.error),
        ]),
        const SizedBox(height: 16),
        const Text('Sales',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (sales.isEmpty)
          const _EmptyState('No sales recorded.')
        else
          _table(
            headers: const ['Invoice', 'Customer', 'Date', 'Amount', 'Status'],
            rows: sales
                .take(30)
                .map((s) => [
                      s.invoiceNo,
                      s.customerName,
                      _fmt(s.saleDate),
                      CurrencyFormatter.formatSimple(s.grandTotal, symbol: sym),
                      s.paymentStatus.name,
                    ])
                .toList(),
            colors: sales
                .take(30)
                .map((s) => s.paymentStatus == PaymentStatus.paid
                    ? AppColors.success
                    : AppColors.warning)
                .toList(),
          ),
        const SizedBox(height: 20),
        const Text('Purchases',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (purchases.isEmpty)
          const _EmptyState('No purchases recorded.')
        else
          _table(
            headers: const ['Ref', 'Supplier', 'Date', 'Amount', 'Status'],
            rows: purchases
                .take(30)
                .map((p) => [
                      p.referenceNo.isEmpty
                          ? p.id.substring(0, 6)
                          : p.referenceNo,
                      p.supplierName,
                      _fmt(p.purchaseDate),
                      CurrencyFormatter.formatSimple(p.grandTotal, symbol: sym),
                      p.paymentStatus.name,
                    ])
                .toList(),
            colors: purchases
                .take(30)
                .map((p) => p.paymentStatus == PaymentStatus.paid
                    ? AppColors.success
                    : AppColors.warning)
                .toList(),
          ),
      ],
    );
  }
}

// ── Tax Report ────────────────────────────────────────────────────────────────

class _TaxReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref
        .watch(salesProvider)
        .where((s) => s.status == SaleStatus.final_)
        .toList();
    final purchases = ref.watch(purchasesProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    final taxCollected = sales.fold(0.0, (acc, s) => acc + s.taxAmount);
    final taxPaid = purchases.fold(0.0, (acc, p) => acc + p.taxAmount);
    final netTax = taxCollected - taxPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Tax Report', Icons.percent_outlined),
        _SummaryChips([
          _Chip(
              'Tax Collected',
              CurrencyFormatter.formatSimple(taxCollected, symbol: sym),
              AppColors.success),
          _Chip(
              'Tax Paid',
              CurrencyFormatter.formatSimple(taxPaid, symbol: sym),
              AppColors.error),
          _Chip(
              'Net Tax Liability',
              CurrencyFormatter.formatSimple(netTax, symbol: sym),
              netTax >= 0 ? AppColors.cardBlue : AppColors.success),
        ]),
        const SizedBox(height: 16),
        const Text('Sales Tax Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (sales.where((s) => s.taxAmount > 0).isEmpty)
          const _EmptyState('No tax-bearing sales.')
        else
          _table(
            headers: const ['Invoice', 'Date', 'Subtotal', 'Tax', 'Total'],
            rows: sales
                .where((s) => s.taxAmount > 0)
                .take(30)
                .map((s) => [
                      s.invoiceNo,
                      _fmt(s.saleDate),
                      CurrencyFormatter.formatSimple(s.subTotal, symbol: sym),
                      CurrencyFormatter.formatSimple(s.taxAmount, symbol: sym),
                      CurrencyFormatter.formatSimple(s.grandTotal, symbol: sym),
                    ])
                .toList(),
          ),
        const SizedBox(height: 20),
        const Text('Purchase Tax Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (purchases.where((p) => p.taxAmount > 0).isEmpty)
          const _EmptyState('No tax-bearing purchases.')
        else
          _table(
            headers: const ['Ref', 'Date', 'Subtotal', 'Tax', 'Total'],
            rows: purchases
                .where((p) => p.taxAmount > 0)
                .take(30)
                .map((p) => [
                      p.referenceNo.isEmpty
                          ? p.id.substring(0, 6)
                          : p.referenceNo,
                      _fmt(p.purchaseDate),
                      CurrencyFormatter.formatSimple(p.subTotal, symbol: sym),
                      CurrencyFormatter.formatSimple(p.taxAmount, symbol: sym),
                      CurrencyFormatter.formatSimple(p.grandTotal, symbol: sym),
                    ])
                .toList(),
          ),
      ],
    );
  }
}

// ── Contact Report ────────────────────────────────────────────────────────────

class _ContactReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    final purchases = ref.watch(purchasesProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    // Build per-customer sales total
    final customerTotals = <String, double>{};
    for (final s in sales.where((s) => s.status == SaleStatus.final_)) {
      customerTotals[s.customerName] =
          (customerTotals[s.customerName] ?? 0) + s.grandTotal;
    }

    // Build per-supplier purchases total
    final supplierTotals = <String, double>{};
    for (final p in purchases) {
      supplierTotals[p.supplierName] =
          (supplierTotals[p.supplierName] ?? 0) + p.grandTotal;
    }

    final customers = ref.watch(contactsProvider.notifier).customers;
    final suppliers = ref.watch(contactsProvider.notifier).suppliers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Contact Reports', Icons.contacts_outlined),
        _SummaryChips([
          _Chip('Customers', '${customers.length}', AppColors.cardBlue),
          _Chip('Suppliers', '${suppliers.length}', AppColors.cardOrange),
          _Chip(
              'Total Receivable',
              CurrencyFormatter.formatSimple(
                  customers.fold(0.0, (acc, c) => acc + c.balance),
                  symbol: sym),
              AppColors.success),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: customers.isEmpty
                  ? null
                  : () => LedgerExportPrinter.printCustomerLedger(
                        customers: customers,
                        sales: sales,
                      ),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export Customer Ledger'),
            ),
            OutlinedButton.icon(
              onPressed: suppliers.isEmpty
                  ? null
                  : () => LedgerExportPrinter.printSupplierLedger(
                        suppliers: suppliers,
                        purchases: purchases,
                      ),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export Supplier Ledger'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Customers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (customers.isEmpty)
          const _EmptyState('No customers found.')
        else
          _table(
            headers: const ['Name', 'Phone', 'Total Sales', 'Balance'],
            rows: customers
                .map((c) => [
                      c.name,
                      c.phone,
                      CurrencyFormatter.formatSimple(
                          customerTotals[c.name] ?? 0,
                          symbol: sym),
                      CurrencyFormatter.formatSimple(c.balance, symbol: sym),
                    ])
                .toList(),
            colors: customers
                .map((c) =>
                    c.balance > 0 ? AppColors.warning : AppColors.success)
                .toList(),
          ),
        const SizedBox(height: 20),
        const Text('Suppliers',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (suppliers.isEmpty)
          const _EmptyState('No suppliers found.')
        else
          _table(
            headers: const ['Name', 'Phone', 'Total Purchased', 'Balance'],
            rows: suppliers
                .map((s) => [
                      s.name,
                      s.phone,
                      CurrencyFormatter.formatSimple(
                          supplierTotals[s.name] ?? 0,
                          symbol: sym),
                      CurrencyFormatter.formatSimple(s.balance, symbol: sym),
                    ])
                .toList(),
          ),
      ],
    );
  }
}

// ── Stock Report ──────────────────────────────────────────────────────────────

class _StockReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider)
      ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
    const sym = AppConstants.defaultCurrencySymbol;

    final totalValue =
        products.fold(0.0, (acc, p) => acc + p.stockQuantity * p.purchasePrice);
    final lowStock = products.where((p) => p.isLowStock).toList();
    final outOfStock = products.where((p) => p.stockQuantity <= 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Stock Reports', Icons.inventory_2_outlined),
        _SummaryChips([
          _Chip('Total Products', '${products.length}', AppColors.cardBlue),
          _Chip('Low Stock', '${lowStock.length}', AppColors.warning),
          _Chip('Out of Stock', '${outOfStock.length}', AppColors.error),
          _Chip(
              'Stock Value',
              CurrencyFormatter.formatSimple(totalValue, symbol: sym),
              AppColors.success),
        ]),
        const SizedBox(height: 16),
        if (lowStock.isNotEmpty) ...[
          const Text('Low Stock Alert',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.warning)),
          const SizedBox(height: 8),
          _table(
            headers: const ['Product', 'SKU', 'Stock', 'Alert At'],
            rows: lowStock
                .map((p) => [
                      p.name,
                      p.sku,
                      '${p.stockQuantity.toStringAsFixed(0)} units',
                      '${p.alertQuantity.toStringAsFixed(0)} units',
                    ])
                .toList(),
            colors: lowStock.map((_) => AppColors.warning).toList(),
          ),
          const SizedBox(height: 20),
        ],
        const Text('All Stock',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        _table(
          headers: const ['Product', 'SKU', 'Stock', 'Cost Price', 'Value'],
          rows: products
              .map((p) => [
                    p.name,
                    p.sku,
                    p.stockQuantity.toStringAsFixed(0),
                    CurrencyFormatter.formatSimple(p.purchasePrice,
                        symbol: sym),
                    CurrencyFormatter.formatSimple(
                        p.stockQuantity * p.purchasePrice,
                        symbol: sym),
                  ])
              .toList(),
          colors: products
              .map((p) =>
                  p.isLowStock ? AppColors.warning : AppColors.textSecondary)
              .toList(),
        ),
      ],
    );
  }
}

// ── Expense Report ────────────────────────────────────────────────────────────

class _ExpenseReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider)
      ..sort((a, b) => b.date.compareTo(a.date));
    final categories = ref.watch(expenseCategoriesProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    final total = expenses.fold(0.0, (acc, e) => acc + e.amount);

    // Group by category
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
    }

    final categoryMap = {for (final c in categories) c.id: c.name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Expense Report', Icons.receipt_long_outlined),
        _SummaryChips([
          _Chip(
              'Total Expenses',
              CurrencyFormatter.formatSimple(total, symbol: sym),
              AppColors.error),
          _Chip('Transactions', '${expenses.length}', AppColors.cardBlue),
          _Chip(
              'Categories', '${byCategory.keys.length}', AppColors.cardOrange),
        ]),
        const SizedBox(height: 16),
        const Text('By Category',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...byCategory.entries.map((e) {
          final name = categoryMap[e.key] ?? e.key;
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(CurrencyFormatter.formatSimple(e.value, symbol: sym),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.cardBorder,
                  color: AppColors.error,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        const Text('All Expenses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (expenses.isEmpty)
          const _EmptyState('No expenses recorded.')
        else
          _table(
            headers: const ['Date', 'Category', 'Note', 'Method', 'Amount'],
            rows: expenses
                .take(50)
                .map((e) => [
                      _fmt(e.date),
                      categoryMap[e.categoryId] ?? e.categoryId,
                      e.note.isEmpty ? '-' : e.note,
                      e.paymentMethod,
                      CurrencyFormatter.formatSimple(e.amount, symbol: sym),
                    ])
                .toList(),
          ),
      ],
    );
  }
}

// ── Trending Products ─────────────────────────────────────────────────────────

class _TrendingProductsReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref
        .watch(salesProvider)
        .where((s) => s.status == SaleStatus.final_)
        .toList();
    const sym = AppConstants.defaultCurrencySymbol;

    // Aggregate qty and revenue per product
    final qtyMap = <String, double>{};
    final revenueMap = <String, double>{};
    final nameMap = <String, String>{};

    for (final s in sales) {
      for (final l in s.lines) {
        qtyMap[l.productId] = (qtyMap[l.productId] ?? 0) + l.qty;
        revenueMap[l.productId] = (revenueMap[l.productId] ?? 0) + l.lineTotal;
        nameMap[l.productId] = l.productName;
      }
    }

    final sorted = qtyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Trending Products', Icons.trending_up_outlined),
        _SummaryChips([
          _Chip('Products Sold', '${sorted.length}', AppColors.cardBlue),
          _Chip(
              'Total Revenue',
              CurrencyFormatter.formatSimple(
                  revenueMap.values.fold(0.0, (a, b) => a + b),
                  symbol: sym),
              AppColors.success),
        ]),
        const SizedBox(height: 16),
        if (sorted.isEmpty)
          const _EmptyState('No sales data yet.')
        else ...[
          const Text('Top Selling Products',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...sorted.take(10).map((e) {
            final maxQty = sorted.first.value;
            final pct = maxQty > 0 ? e.value / maxQty : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(nameMap[e.key] ?? e.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '${e.value.toStringAsFixed(0)} units · '
                        '${CurrencyFormatter.formatSimple(revenueMap[e.key] ?? 0, symbol: sym)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.cardCyan,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ── Cash Register Report ──────────────────────────────────────────────────────

class _CashRegisterReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref
        .watch(salesProvider)
        .where((s) => s.status == SaleStatus.final_)
        .toList();
    const sym = AppConstants.defaultCurrencySymbol;

    // Group by payment method
    final byMethod = <String, double>{};
    for (final s in sales) {
      byMethod[s.paymentMethod] =
          (byMethod[s.paymentMethod] ?? 0) + s.grandTotal;
    }

    final total = sales.fold(0.0, (acc, s) => acc + s.grandTotal);
    final totalDue = sales.fold(0.0, (acc, s) => acc + s.dueAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Cash Register', Icons.point_of_sale_outlined),
        _SummaryChips([
          _Chip(
              'Total Sales',
              CurrencyFormatter.formatSimple(total, symbol: sym),
              AppColors.success),
          _Chip(
              'Total Due',
              CurrencyFormatter.formatSimple(totalDue, symbol: sym),
              totalDue > 0 ? AppColors.error : AppColors.success),
          _Chip('Transactions', '${sales.length}', AppColors.cardBlue),
        ]),
        const SizedBox(height: 16),
        const Text('By Payment Method',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (byMethod.isEmpty)
          const _EmptyState('No transactions yet.')
        else ...[
          ...byMethod.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(CurrencyFormatter.formatSimple(e.value, symbol: sym),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.cardTeal,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
        const Text('Recent Sales',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        _table(
          headers: const ['Invoice', 'Customer', 'Method', 'Amount', 'Due'],
          rows: sales
              .take(30)
              .map((s) => [
                    s.invoiceNo,
                    s.customerName,
                    s.paymentMethod,
                    CurrencyFormatter.formatSimple(s.grandTotal, symbol: sym),
                    CurrencyFormatter.formatSimple(s.dueAmount, symbol: sym),
                  ])
              .toList(),
          colors: sales
              .take(30)
              .map((s) =>
                  s.dueAmount > 0 ? AppColors.warning : AppColors.success)
              .toList(),
        ),
      ],
    );
  }
}

// ── Sales Register ────────────────────────────────────────────────────────────

class _SalesRegisterReport extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider)
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    const sym = AppConstants.defaultCurrencySymbol;

    final finalSales =
        sales.where((s) => s.status == SaleStatus.final_).toList();
    final drafts = sales.where((s) => s.status == SaleStatus.draft).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReportHeader('Sales Register', Icons.list_alt_outlined),
        _SummaryChips([
          _Chip('Finalized', '${finalSales.length}', AppColors.success),
          _Chip('Drafts', '${drafts.length}', AppColors.warning),
          _Chip(
              'Total',
              CurrencyFormatter.formatSimple(
                  finalSales.fold(0.0, (acc, s) => acc + s.grandTotal),
                  symbol: sym),
              AppColors.cardBlue),
        ]),
        const SizedBox(height: 16),
        const Text('All Sales',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (sales.isEmpty)
          const _EmptyState('No sales recorded.')
        else
          _table(
            headers: const [
              'Invoice',
              'Date',
              'Customer',
              'Items',
              'Total',
              'Status'
            ],
            rows: sales
                .take(50)
                .map((s) => [
                      s.invoiceNo,
                      _fmt(s.saleDate),
                      s.customerName,
                      '${s.totalItems}',
                      CurrencyFormatter.formatSimple(s.grandTotal, symbol: sym),
                      s.status == SaleStatus.final_ ? 'Final' : 'Draft',
                    ])
                .toList(),
            colors: sales
                .take(50)
                .map((s) => s.status == SaleStatus.draft
                    ? AppColors.warning
                    : AppColors.success)
                .toList(),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Report Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _ReportHeader extends StatelessWidget {
  const _ReportHeader(this.title, this.icon);
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips(this.chips);
  final List<_Chip> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) => _buildChip(c)).toList(),
    );
  }

  Widget _buildChip(_Chip c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(c.label,
              style: TextStyle(
                  fontSize: 11, color: c.color, fontWeight: FontWeight.w500)),
          Text(c.value,
              style: TextStyle(
                  fontSize: 14, color: c.color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Chip {
  const _Chip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

// Simple responsive data table
Widget _table({
  required List<String> headers,
  required List<List<String>> rows,
  List<Color>? colors,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowHeight: 36,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 48,
      columnSpacing: 16,
      headingTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary),
      columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
      rows: rows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        final statusColor = colors != null && i < colors.length
            ? colors[i]
            : AppColors.textSecondary;
        return DataRow(
          cells: row.asMap().entries.map((cell) {
            final isLast = cell.key == row.length - 1;
            return DataCell(Text(
              cell.value,
              style: TextStyle(
                fontSize: 12,
                color: isLast ? statusColor : AppColors.textPrimary,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
              ),
            ));
          }).toList(),
        );
      }).toList(),
    ),
  );
}

String _fmt(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
