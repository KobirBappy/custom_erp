import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../returns/models/return_entry.dart';
import '../../returns/providers/return_provider.dart';
import '../models/sale.dart';
import '../providers/sale_provider.dart';
import '../utils/sale_chalan_printer.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    final sortedSales = [...sales]
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

    final recent = sortedSales.take(5).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Sell History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.pos),
                icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                label: const Text('Open POS'),
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Total Sales',
                value: CurrencyFormatter.formatSimple(
                  sales.fold(0.0, (s, e) => s + e.grandTotal),
                  symbol: sym,
                ),
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Due',
                value: CurrencyFormatter.formatSimple(
                  sales.fold(0.0, (s, e) => s + e.dueAmount),
                  symbol: sym,
                ),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Text(
                    'Latest 5 Sales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${recent.length} records',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'No sales yet. Complete a POS checkout to see records.'),
                  ),
                )
              else
                ...recent.map((sale) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SaleTile(sale: sale, symbol: sym),
                    )),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'All Sales',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${sortedSales.length} records',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (sortedSales.isEmpty)
                const SizedBox.shrink()
              else
                ...sortedSales.map((sale) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SaleTile(sale: sale, symbol: sym),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaleTile extends ConsumerWidget {
  const _SaleTile({required this.sale, required this.symbol});

  final Sale sale;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);
    final user = ref.watch(authProvider);
    final canDelete = user != null && user.role != 'cashier';
    final due = sale.dueAmount;

    return Card(
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                sale.invoiceNo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _StatusBadge(
              label: sale.status == SaleStatus.final_ ? 'Final' : 'Draft',
              color: sale.status == SaleStatus.final_
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(width: 6),
            if (canDelete)
              IconButton(
                tooltip: 'Delete Sale',
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _confirmDelete(context, ref),
              ),
            if (canDelete)
              IconButton(
                tooltip: 'Add Sale Return',
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                onPressed: () => _createSaleReturn(context, ref),
              ),
            IconButton(
              tooltip: 'Print Chalan',
              icon: const Icon(Icons.print_outlined, size: 18),
              onPressed: () async {
                await SaleChalanPrinter.print(sale: sale, business: business);
              },
            ),
          ],
        ),
        subtitle: Text(
          '${sale.customerName} - ${DateFormatter.formatDate(sale.saleDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatSimple(sale.grandTotal, symbol: symbol),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
            _StatusBadge(
              label: sale.paymentStatus == PaymentStatus.paid
                  ? 'Paid'
                  : sale.paymentStatus == PaymentStatus.partial
                      ? 'Partial'
                      : 'Due',
              color: sale.paymentStatus == PaymentStatus.paid
                  ? AppColors.success
                  : sale.paymentStatus == PaymentStatus.partial
                      ? AppColors.warning
                      : AppColors.error,
            ),
            if (due > 0)
              Text(
                'Due: ${CurrencyFormatter.formatSimple(due, symbol: symbol)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        onTap: () => _showSaleDetails(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sold Item'),
        content: Text('Delete sale "${sale.invoiceNo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await ref.read(salesProvider.notifier).voidSale(sale.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale deleted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete sale: $e')),
      );
    }
  }

  Future<void> _showSaleDetails(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sale ${sale.invoiceNo}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: ${sale.customerName}'),
                Text('Date: ${DateFormatter.formatDate(sale.saleDate)}'),
                Text('Payment: ${sale.paymentStatus.name.toUpperCase()}'),
                Text(
                    'Paid: ${CurrencyFormatter.formatSimple(sale.paidAmount, symbol: symbol)}'),
                Text(
                  'Due: ${CurrencyFormatter.formatSimple(sale.dueAmount, symbol: symbol)}',
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...sale.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${line.productName} (${line.sku})'),
                        ),
                        Text(
                          '${line.qty.toStringAsFixed(0)} x ${CurrencyFormatter.formatSimple(line.unitPrice, symbol: symbol)} = ${CurrencyFormatter.formatSimple(line.lineTotal, symbol: symbol)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSaleReturn(BuildContext context, WidgetRef ref) async {
    final amountCtrl =
        TextEditingController(text: sale.grandTotal.toStringAsFixed(2));
    final paidCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sale Return - ${sale.invoiceNo}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Return Amount'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: paidCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Refund Paid Now (optional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, <String, dynamic>{
              'amount': double.tryParse(amountCtrl.text.trim()) ?? 0.0,
              'paid': double.tryParse(paidCtrl.text.trim()) ?? 0.0,
              'reason': reasonCtrl.text.trim(),
            }),
            child: const Text('Save Return'),
          ),
        ],
      ),
    );

    amountCtrl.dispose();
    paidCtrl.dispose();
    reasonCtrl.dispose();

    if (result == null) return;
    final amount = (result['amount'] as double?) ?? 0.0;
    final paid = (result['paid'] as double?) ?? 0.0;
    if (amount <= 0) return;

    try {
      await ref.read(saleReturnsProvider.notifier).add(
            ReturnEntry(
              id: '',
              businessId: sale.businessId,
              locationId: sale.locationId,
              referenceId: sale.id,
              referenceNo: sale.invoiceNo,
              partyId: sale.customerId,
              partyName: sale.customerName,
              amount: amount,
              paidAmount: paid < 0 ? 0 : paid,
              date: DateTime.now(),
              reason: (result['reason'] as String?) ?? '',
            ),
          );

      for (final line in sale.lines) {
        await ref.read(productsProvider.notifier).adjustStock(
              line.productId,
              line.qty,
              locationId: sale.locationId,
            );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale return saved. Stock adjusted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save sale return: $e')),
      );
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
