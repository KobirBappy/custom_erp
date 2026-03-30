import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/providers/product_provider.dart';
import '../../returns/models/return_entry.dart';
import '../../returns/providers/return_provider.dart';
import '../models/purchase.dart';
import '../providers/purchase_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  String _search = '';

  Future<void> _createPurchaseReturn(Purchase purchase) async {
    final amountCtrl =
        TextEditingController(text: purchase.grandTotal.toStringAsFixed(2));
    final paidCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Purchase Return - ${purchase.referenceNo.isEmpty ? purchase.id : purchase.referenceNo}'),
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
                  labelText: 'Amount Received Now (optional)',
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
      await ref.read(purchaseReturnsProvider.notifier).add(
            ReturnEntry(
              id: '',
              businessId: purchase.businessId,
              locationId: purchase.locationId,
              referenceId: purchase.id,
              referenceNo: purchase.referenceNo.isEmpty
                  ? purchase.id
                  : purchase.referenceNo,
              partyId: purchase.supplierId,
              partyName: purchase.supplierName,
              amount: amount,
              paidAmount: paid < 0 ? 0 : paid,
              date: DateTime.now(),
              reason: (result['reason'] as String?) ?? '',
            ),
          );

      for (final line in purchase.lines) {
        await ref.read(productsProvider.notifier).adjustStock(
              line.productId,
              -line.qty,
              locationId: purchase.locationId,
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase return saved. Stock adjusted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save purchase return: $e')),
      );
    }
  }

  Future<void> _deletePurchase(String purchaseId, String referenceNo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase'),
        content: Text(
          'Delete purchase "${referenceNo.isEmpty ? 'No Reference' : referenceNo}"?',
        ),
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
      await ref.read(purchasesProvider.notifier).delete(purchaseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete purchase: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchases = ref.watch(purchasesProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    final filtered = _search.isEmpty
        ? purchases
        : purchases
            .where((p) =>
                p.referenceNo.toLowerCase().contains(_search.toLowerCase()) ||
                p.supplierName.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Purchases',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/purchases/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Purchase'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by reference or supplier...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No purchases found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  p.referenceNo.isEmpty
                                      ? 'No Reference'
                                      : p.referenceNo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            _StatusBadge(status: p.status),
                          ],
                        ),
                        subtitle: Text(
                            '${p.supplierName} · ${DateFormatter.formatDate(p.purchaseDate)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.formatSimple(
                                    p.grandTotal,
                                    symbol: sym,
                                  ),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                _PayBadge(status: p.paymentStatus),
                              ],
                            ),
                            IconButton(
                              tooltip: 'Edit Purchase',
                              onPressed: () => context.go('/purchases/${p.id}'),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Add Purchase Return',
                              onPressed: () => _createPurchaseReturn(p),
                              icon:
                                  const Icon(Icons.assignment_return_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete Purchase',
                              onPressed: () => _deletePurchase(
                                p.id,
                                p.referenceNo,
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        onTap: () => context.go('/purchases/${p.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final PurchaseStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case PurchaseStatus.received:
        color = AppColors.success;
        label = 'Received';
      case PurchaseStatus.pending:
        color = AppColors.warning;
        label = 'Pending';
      case PurchaseStatus.ordered:
        color = AppColors.info;
        label = 'Ordered';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PayBadge extends StatelessWidget {
  const _PayBadge({required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case PaymentStatus.paid:
        color = AppColors.success;
        label = 'Paid';
      case PaymentStatus.due:
        color = AppColors.error;
        label = 'Due';
      case PaymentStatus.partial:
        color = AppColors.warning;
        label = 'Partial';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
