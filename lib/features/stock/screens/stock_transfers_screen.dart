import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_provider.dart';
import '../../products/providers/product_provider.dart';
import '../models/stock_transfer.dart';
import '../providers/stock_transfer_provider.dart';

class StockTransfersScreen extends ConsumerWidget {
  const StockTransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(stockTransfersProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Stock Transfers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showNewTransferDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Transfer'),
              ),
            ],
          ),
        ),
        Expanded(
          child: transfers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 64, color: AppColors.textLight),
                      SizedBox(height: 16),
                      Text('No stock transfers yet',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textSecondary)),
                      SizedBox(height: 8),
                      Text('Transfer stock between branches',
                          style: TextStyle(color: AppColors.textLight)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transfers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = transfers[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.cardBlue.withOpacity(0.15),
                          child: const Icon(Icons.swap_horiz,
                              color: AppColors.cardBlue),
                        ),
                        title: Text(
                          t.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t.fromLocationName} -> ${t.toLocationName}',
                            ),
                            Text(
                              DateFormatter.formatDate(t.transferDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (t.note.trim().isNotEmpty)
                              Text(
                                t.note,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '${t.qty.toStringAsFixed(0)} unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showNewTransferDialog(
      BuildContext context, WidgetRef ref) async {
    final products = ref.read(productsProvider);
    final locations = ref.read(locationsProvider);
    final currentBusiness = ref.read(currentBusinessProvider);
    final currentUser = ref.read(authProvider);
    final qtyCtrl = TextEditingController(text: '1');
    final noteCtrl = TextEditingController();
    String? productId;
    String? fromLocationId;
    String? toLocationId;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDlg) {
          final selectedProduct = productId == null
              ? null
              : _firstWhereOrNull(products, (p) => p.id == productId);
          final available = selectedProduct == null || fromLocationId == null
              ? 0.0
              : selectedProduct.stockForLocation(fromLocationId);

          return AlertDialog(
            title: const Text('New Stock Transfer'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: productId,
                    decoration: const InputDecoration(labelText: 'Product *'),
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDlg(() => productId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: fromLocationId,
                    decoration:
                        const InputDecoration(labelText: 'From Branch *'),
                    items: locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDlg(() => fromLocationId = v),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Available in source: ${available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: toLocationId,
                    decoration: const InputDecoration(labelText: 'To Branch *'),
                    items: locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDlg(() => toLocationId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx2, <String, dynamic>{
                  'productId': productId,
                  'fromLocationId': fromLocationId,
                  'toLocationId': toLocationId,
                  'qty': double.tryParse(qtyCtrl.text.trim()) ?? 0.0,
                  'note': noteCtrl.text.trim(),
                }),
                child: const Text('Transfer'),
              ),
            ],
          );
        },
      ),
    );

    qtyCtrl.dispose();
    noteCtrl.dispose();

    if (payload == null) return;
    final pId = payload['productId'] as String?;
    final fromId = payload['fromLocationId'] as String?;
    final toId = payload['toLocationId'] as String?;
    final qty = (payload['qty'] as double?) ?? 0.0;
    final note = (payload['note'] as String?) ?? '';

    if (pId == null || fromId == null || toId == null || qty <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete transfer fields.')),
        );
      }
      return;
    }

    final product = _firstWhereOrNull(products, (p) => p.id == pId);
    final fromLoc = _firstWhereOrNull(locations, (l) => l.id == fromId);
    final toLoc = _firstWhereOrNull(locations, (l) => l.id == toId);
    if (product == null || fromLoc == null || toLoc == null) return;

    try {
      await ref.read(productsProvider.notifier).transferStock(
            productId: pId,
            fromLocationId: fromId,
            toLocationId: toId,
            qty: qty,
          );

      await ref.read(stockTransfersProvider.notifier).add(
            StockTransfer(
              id: '',
              businessId: currentBusiness?.id ?? product.businessId,
              productId: pId,
              productName: product.name,
              fromLocationId: fromId,
              fromLocationName: fromLoc.name,
              toLocationId: toId,
              toLocationName: toLoc.name,
              qty: qty,
              transferDate: DateTime.now(),
              note: note,
              createdBy: currentUser?.uid ?? '',
            ),
          );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transferred ${qty.toStringAsFixed(0)} unit '
            'from ${fromLoc.name} to ${toLoc.name}.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer failed: $e')),
      );
    }
  }

  T? _firstWhereOrNull<T>(List<T> list, bool Function(T item) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }
}
