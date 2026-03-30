import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../businesses/providers/business_provider.dart';
import '../models/purchase.dart';
import '../providers/purchase_provider.dart';
import '../../contacts/providers/contact_provider.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key, this.purchaseId});
  final String? purchaseId;

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _refCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _shippingCtrl = TextEditingController(text: '0');
  final _paidCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  String? _supplierId;
  String _supplierName = '';
  DateTime _purchaseDate = DateTime.now();
  PurchaseStatus _status = PurchaseStatus.received;
  final List<_LineItem> _lines = [];
  bool _loading = false;
  Purchase? _existing;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _tryPrefillFromState());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _refCtrl,
      _discountCtrl,
      _shippingCtrl,
      _paidCtrl,
      _notesCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _tryPrefillFromState() {
    if (_prefilled || widget.purchaseId == null) return;
    final purchases = ref.read(purchasesProvider);
    Purchase? found;
    for (final p in purchases) {
      if (p.id == widget.purchaseId) {
        found = p;
        break;
      }
    }
    if (found == null) return;
    _populateFromPurchase(found);
  }

  void _populateFromPurchase(Purchase purchase) {
    _existing = purchase;
    _prefilled = true;
    _refCtrl.text = purchase.referenceNo;
    _discountCtrl.text = purchase.discountAmount.toString();
    _shippingCtrl.text = purchase.shippingCost.toString();
    _paidCtrl.text = purchase.paidAmount.toString();
    _notesCtrl.text = purchase.notes;

    _supplierId = purchase.supplierId;
    _supplierName = purchase.supplierName;
    _purchaseDate = purchase.purchaseDate;
    _status = purchase.status;

    _lines
      ..clear()
      ..addAll(
        purchase.lines.map(
          (l) => _LineItem(
            productId: l.productId,
            productName: l.productName,
            sku: l.sku,
            qty: l.qty,
            unitCost: l.unitCost,
          ),
        ),
      );

    if (mounted) {
      setState(() {});
    }
  }

  void _goBackToPurchases() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/purchases');
  }

  double get _subTotal =>
      _lines.fold(0.0, (sum, l) => sum + l.qty * l.unitCost);
  double get _grandTotal =>
      _subTotal +
      (double.tryParse(_shippingCtrl.text) ?? 0) -
      (double.tryParse(_discountCtrl.text) ?? 0);

  void _addLine() {
    final products = ref.read(productsProvider);
    showDialog(
      context: context,
      builder: (_) => _ProductPickerDialog(
        products: products,
        onSelect: (product) {
          setState(() {
            final existingIndex =
                _lines.indexWhere((line) => line.productId == product.id);
            if (existingIndex >= 0) {
              _lines[existingIndex].qty = _lines[existingIndex].qty + 1;
              return;
            }

            _lines.add(
              _LineItem(
                productId: product.id,
                productName: product.name,
                sku: product.sku,
                qty: 1,
                unitCost: product.purchasePrice,
              ),
            );
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _loading = true);

    try {
      final paid = double.tryParse(_paidCtrl.text) ?? 0;
      final currentBusiness = ref.read(currentBusinessProvider);
      final currentLocation = ref.read(currentLocationProvider);
      final purchase = Purchase(
        id: _existing?.id ?? '',
        businessId: _existing?.businessId ??
            currentBusiness?.id ??
            AppConstants.demoBusinessId,
        locationId: _existing?.locationId ??
            currentLocation?.id ??
            AppConstants.demoLocationId,
        supplierId: _supplierId!,
        supplierName: _supplierName,
        purchaseDate: _purchaseDate,
        referenceNo: _refCtrl.text.trim(),
        status: _status,
        paymentStatus: paid >= _grandTotal
            ? PaymentStatus.paid
            : paid > 0
                ? PaymentStatus.partial
                : PaymentStatus.due,
        lines: _lines
            .map((l) => PurchaseLine(
                  productId: l.productId,
                  productName: l.productName,
                  sku: l.sku,
                  qty: l.qty,
                  unitCost: l.unitCost,
                ))
            .toList(),
        discountAmount: double.tryParse(_discountCtrl.text) ?? 0,
        shippingCost: double.tryParse(_shippingCtrl.text) ?? 0,
        paidAmount: paid,
        notes: _notesCtrl.text.trim(),
      );

      if (_existing != null) {
        await ref.read(purchasesProvider.notifier).update(purchase);
      } else {
        await ref.read(purchasesProvider.notifier).add(purchase);
      }

      if (!mounted) return;
      context.go('/purchases');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save purchase: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.purchaseId != null && !_prefilled) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _tryPrefillFromState());
    }
    final suppliers = ref.watch(contactsProvider.notifier).suppliers;
    const sym = AppConstants.defaultCurrencySymbol;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.purchaseId == null ? 'Add Purchase' : 'Edit Purchase'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: _goBackToPurchases),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving...' : 'Save',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _supplierId,
                      decoration:
                          const InputDecoration(labelText: 'Supplier *'),
                      items: suppliers
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _supplierId = v;
                          _supplierName =
                              suppliers.firstWhere((s) => s.id == v).name;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _refCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Reference No'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) setState(() => _purchaseDate = d);
                          },
                          child: InputDecorator(
                            decoration:
                                const InputDecoration(labelText: 'Date'),
                            child: Text(
                                '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<PurchaseStatus>(
                          value: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: PurchaseStatus.values
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.name)))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _status = v ?? PurchaseStatus.received),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Line items
            Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text('Items',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                  ),
                  if (_lines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No items added yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ..._lines.asMap().entries.map((e) {
                    final idx = e.key;
                    final line = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('${line.productName}\n${line.sku}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: line.qty.toString(),
                              decoration: const InputDecoration(
                                  labelText: 'Qty', isDense: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (v) => setState(() =>
                                  _lines[idx].qty = double.tryParse(v) ?? 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: line.unitCost.toString(),
                              decoration: const InputDecoration(
                                  labelText: 'Cost', isDense: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (v) => setState(() => _lines[idx]
                                  .unitCost = double.tryParse(v) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '$sym ${(line.qty * line.unitCost).toStringAsFixed(0)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _lines.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        controller: _discountCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Discount'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextFormField(
                        controller: _shippingCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Shipping'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextFormField(
                        controller: _paidCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Paid Amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      )),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '$sym ${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _LineItem {
  _LineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitCost,
  });
  final String productId;
  final String productName;
  final String sku;
  double qty;
  double unitCost;
}

class _ProductPickerDialog extends StatefulWidget {
  const _ProductPickerDialog({required this.products, required this.onSelect});
  final List<Product> products;
  final void Function(Product) onSelect;

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? widget.products
        : widget.products
            .where((p) =>
                p.name.toLowerCase().contains(_q.toLowerCase()) ||
                p.sku.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  hintText: 'Search...', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('SKU: ${p.sku}'),
                    trailing: Text(
                        '${AppConstants.defaultCurrencySymbol} ${p.purchasePrice}'),
                    onTap: () {
                      widget.onSelect(p);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ],
    );
  }
}
