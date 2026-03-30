import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
class StockAdjustmentsScreen extends ConsumerStatefulWidget {
  const StockAdjustmentsScreen({super.key});

  @override
  ConsumerState<StockAdjustmentsScreen> createState() =>
      _StockAdjustmentsScreenState();
}

class _StockAdjustmentsScreenState
    extends ConsumerState<StockAdjustmentsScreen> {
  void _showAdjustDialog() {
    final products = ref.read(productsProvider);
    String? selectedProductId;
    final qtyCtrl = TextEditingController();
    String reason = 'Damage';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Stock Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Product *'),
                items: products
                    .map((p) => DropdownMenuItem(
                        value: p.id, child: Text('${p.name} (${p.stockQuantity.toStringAsFixed(0)} in stock)')))
                    .toList(),
                onChanged: (v) => setDlg(() => selectedProductId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Qty (+ or -)',
                  hintText: 'e.g. -5 or +10',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: ['Damage', 'Theft', 'Received', 'Return', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setDlg(() => reason = v ?? 'Damage'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedProductId != null && qtyCtrl.text.isNotEmpty) {
                  final delta = double.tryParse(qtyCtrl.text) ?? 0;
                  ref
                      .read(productsProvider.notifier)
                      .adjustStock(selectedProductId!, delta);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Stock adjusted by ${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}')),
                  );
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final lowStock = products.where((p) => p.isLowStock).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Stock Adjustment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAdjustDialog,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Adjust Stock'),
              ),
            ],
          ),
        ),
        if (lowStock.isNotEmpty)
          Container(
            color: AppColors.error.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Text('${lowStock.length} product(s) below alert quantity',
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text('Current Stock',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${products.length} products',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                title: Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('SKU: ${p.sku}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.isLowStock
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.stockQuantity.toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.isLowStock
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('/ ${p.alertQuantity.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
