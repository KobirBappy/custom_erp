import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/return_entry.dart';
import '../providers/return_provider.dart';

enum _ReturnFilterType { all, sale, purchase }

class ReturnsScreen extends ConsumerStatefulWidget {
  const ReturnsScreen({super.key});

  @override
  ConsumerState<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends ConsumerState<ReturnsScreen> {
  _ReturnFilterType _type = _ReturnFilterType.all;
  String _search = '';
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final saleReturns = ref.watch(saleReturnsProvider);
    final purchaseReturns = ref.watch(purchaseReturnsProvider);
    final user = ref.watch(authProvider);
    final canManage = user != null && user.role != 'cashier';
    const sym = AppConstants.defaultCurrencySymbol;

    final rows = <_ReturnRow>[
      ...saleReturns.map((e) => _ReturnRow(entry: e, isSale: true)),
      ...purchaseReturns.map((e) => _ReturnRow(entry: e, isSale: false)),
    ]..sort((a, b) => b.entry.date.compareTo(a.entry.date));

    final filtered = rows.where((r) {
      if (_type == _ReturnFilterType.sale && !r.isSale) return false;
      if (_type == _ReturnFilterType.purchase && r.isSale) return false;
      if (_search.trim().isNotEmpty) {
        final q = _search.toLowerCase();
        final match = r.entry.referenceNo.toLowerCase().contains(q) ||
            r.entry.partyName.toLowerCase().contains(q) ||
            r.entry.reason.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_range != null) {
        final d = DateTime(
          r.entry.date.year,
          r.entry.date.month,
          r.entry.date.day,
        );
        final from = DateTime(
          _range!.start.year,
          _range!.start.month,
          _range!.start.day,
        );
        final to = DateTime(
          _range!.end.year,
          _range!.end.month,
          _range!.end.day,
        );
        if (d.isBefore(from) || d.isAfter(to)) return false;
      }
      return true;
    }).toList();

    final totalAmount =
        filtered.fold<double>(0.0, (sum, r) => sum + r.entry.amount);
    final totalPaid =
        filtered.fold<double>(0.0, (sum, r) => sum + r.entry.paidAmount);
    final totalDue =
        filtered.fold<double>(0.0, (sum, r) => sum + r.entry.dueAmount);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Returns',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _SummaryChip(
                    label: 'Amount',
                    value: CurrencyFormatter.formatSimple(totalAmount,
                        symbol: sym),
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Paid',
                    value:
                        CurrencyFormatter.formatSimple(totalPaid, symbol: sym),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Due',
                    value:
                        CurrencyFormatter.formatSimple(totalDue, symbol: sym),
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by reference, party, reason...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SegmentedButton<_ReturnFilterType>(
                    segments: const [
                      ButtonSegment(
                        value: _ReturnFilterType.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: _ReturnFilterType.sale,
                        label: Text('Sale'),
                      ),
                      ButtonSegment(
                        value: _ReturnFilterType.purchase,
                        label: Text('Purchase'),
                      ),
                    ],
                    selected: <_ReturnFilterType>{_type},
                    onSelectionChanged: (v) => setState(() => _type = v.first),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_outlined, size: 16),
                    label: Text(
                      _range == null
                          ? 'Date range'
                          : '${DateFormatter.formatDate(_range!.start)} - ${DateFormatter.formatDate(_range!.end)}',
                    ),
                  ),
                  if (_range != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Clear date filter',
                      onPressed: () => setState(() => _range = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No return records found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final row = filtered[i];
                    final e = row.entry;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: row.isSale
                              ? AppColors.warning.withOpacity(0.15)
                              : AppColors.cardBlue.withOpacity(0.15),
                          child: Icon(
                            row.isSale
                                ? Icons.assignment_return_outlined
                                : Icons.assignment_returned_outlined,
                            color: row.isSale
                                ? AppColors.warning
                                : AppColors.cardBlue,
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${row.isSale ? 'Sale Return' : 'Purchase Return'} - ${e.referenceNo}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            _Tag(
                              label: row.isSale ? 'Sale' : 'Purchase',
                              color: row.isSale
                                  ? AppColors.warning
                                  : AppColors.cardBlue,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.partyName} - ${DateFormatter.formatDate(e.date)}',
                            ),
                            if (e.reason.trim().isNotEmpty)
                              Text(
                                'Reason: ${e.reason}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.formatSimple(
                                    e.amount,
                                    symbol: sym,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Due ${CurrencyFormatter.formatSimple(e.dueAmount, symbol: sym)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            if (canManage)
                              IconButton(
                                tooltip: 'Edit Return',
                                onPressed: () => _editReturn(row),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            if (canManage)
                              IconButton(
                                tooltip: 'Delete Return',
                                onPressed: () => _deleteReturn(row),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked);
  }

  Future<void> _editReturn(_ReturnRow row) async {
    final amountCtrl =
        TextEditingController(text: row.entry.amount.toStringAsFixed(2));
    final paidCtrl =
        TextEditingController(text: row.entry.paidAmount.toStringAsFixed(2));
    final reasonCtrl = TextEditingController(text: row.entry.reason);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Return'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: paidCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Paid Amount'),
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
            child: const Text('Save'),
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

    final updated = row.entry.copyWith(
      amount: amount,
      paidAmount: paid < 0 ? 0 : paid,
      reason: (result['reason'] as String?) ?? '',
    );

    try {
      if (row.isSale) {
        await ref.read(saleReturnsProvider.notifier).update(updated);
      } else {
        await ref.read(purchaseReturnsProvider.notifier).update(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update return: $e')),
      );
    }
  }

  Future<void> _deleteReturn(_ReturnRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Return'),
        content: const Text('Delete this return record?'),
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
      if (row.isSale) {
        await ref.read(saleReturnsProvider.notifier).delete(row.entry.id);
      } else {
        await ref.read(purchaseReturnsProvider.notifier).delete(row.entry.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete return: $e')),
      );
    }
  }
}

class _ReturnRow {
  const _ReturnRow({required this.entry, required this.isSale});
  final ReturnEntry entry;
  final bool isSale;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
