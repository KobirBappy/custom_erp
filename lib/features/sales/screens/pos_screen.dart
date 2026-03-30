import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_provider.dart';
import '../../contacts/models/contact.dart';
import '../../contacts/providers/contact_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sale_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({
    super.key,
    this.embedded = false,
    this.onSaleCompleted,
  });

  final bool embedded;
  final VoidCallback? onSaleCompleted;

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _productSearch = '';

  Future<void> _checkout() async {
    try {
      final cart = ref.read(cartProvider);
      if (cart.isEmpty) return;

      final payment = await showDialog<_PaymentResult>(
        context: context,
        builder: (_) => _PaymentDialog(cart: cart),
      );

      if (payment == null || !mounted) return;

      ref.read(cartProvider.notifier).setPaymentMethod(payment.method);
      final updatedCart = ref.read(cartProvider);
      final currentBusiness = ref.read(currentBusinessProvider);
      final currentLocation = ref.read(currentLocationProvider);
      final currentUser = ref.read(authProvider);

      final businessId = currentBusiness?.id ?? AppConstants.demoBusinessId;
      final locationId = currentLocation?.id ?? AppConstants.demoLocationId;
      final cashierId = currentUser?.uid ?? AppConstants.demoUserId;
      final locationPrefix = currentLocation?.invoicePrefix.isNotEmpty == true
          ? currentLocation!.invoicePrefix
          : 'BL0001';

      final sale = await ref.read(salesProvider.notifier).finalizeSale(
            cart: updatedCart,
            businessId: businessId,
            locationId: locationId,
            cashierId: cashierId,
            locationPrefix: locationPrefix,
            transportCost: updatedCart.transportCost,
            paidAmount: payment.paidAmount,
          );

      for (final line in updatedCart.toSaleLines()) {
        await ref.read(productsProvider.notifier).adjustStock(
              line.productId,
              -line.qty,
              locationId: locationId,
            );
      }

      if (updatedCart.transportCost > 0) {
        try {
          await ref.read(expensesProvider.notifier).addTransportExpense(
                businessId: businessId,
                locationId: locationId,
                amount: updatedCart.transportCost,
                date: sale.saleDate,
                paymentMethod: payment.method,
                note: 'Transport from POS sale ${sale.invoiceNo}',
              );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sale saved, but transport expense log failed. Check expense permission/settings.',
                ),
              ),
            );
          }
        }
      }

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sale saved (${payment.label}). Due: ${AppConstants.defaultCurrencySymbol}${sale.dueAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSaleCompleted?.call();
      if (!widget.embedded) {
        context.go('/sell');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('POS checkout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final currentLocationId = currentLocation?.id;
    const symbol = AppConstants.defaultCurrencySymbol;

    final filtered = _productSearch.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(_productSearch.toLowerCase()) ||
                p.sku.toLowerCase().contains(_productSearch.toLowerCase()))
            .toList();

    final isWide = MediaQuery.of(context).size.width >= 800;

    final body = isWide
        ? Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildCatalog(filtered, symbol, currentLocationId),
              ),
              const VerticalDivider(width: 1),
              SizedBox(width: 380, child: _buildCart(cart, symbol)),
            ],
          )
        : Column(
            children: [
              Expanded(
                child: _buildCatalog(filtered, symbol, currentLocationId),
              ),
              const Divider(height: 1),
              SizedBox(height: 360, child: _buildCart(cart, symbol)),
            ],
          );

    if (widget.embedded) {
      return Card(
        margin: EdgeInsets.zero,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/sell'),
        ),
        actions: [
          if (cart.totalQty > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${cart.totalQty} items - $symbol${cart.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildCatalog(
    List filteredProducts,
    String symbol,
    String? locationId,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _productSearch = v),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (_, i) {
              final p = filteredProducts[i];
              final inCart = ref
                  .watch(cartProvider)
                  .items
                  .where((item) => item.product.id == p.id)
                  .isNotEmpty;

              return Card(
                color:
                    inCart ? AppColors.primary.withOpacity(0.05) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: inCart ? AppColors.primary : AppColors.cardBorder,
                    width: inCart ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => ref.read(cartProvider.notifier).addProduct(p),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$symbol${p.sellingPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Stk: ${p.stockForLocation(locationId).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildCart(CartState cart, String symbol) {
    final customers = ref.watch(contactsProvider.notifier).customers;
    Contact? selectedCustomer;
    if (cart.customerId.isNotEmpty) {
      for (final c in customers) {
        if (c.id == cart.customerId) {
          selectedCustomer = c;
          break;
        }
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cart.customerName,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (selectedCustomer != null &&
                        (selectedCustomer.phone.isNotEmpty ||
                            selectedCustomer.email.isNotEmpty))
                      Text(
                        selectedCustomer.phone.isNotEmpty &&
                                selectedCustomer.email.isNotEmpty
                            ? '${selectedCustomer.phone} | ${selectedCustomer.email}'
                            : selectedCustomer.phone.isNotEmpty
                                ? selectedCustomer.phone
                                : selectedCustomer.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickCustomer,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: const Text('Change', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const Center(
                  child: Text(
                    'Cart is empty\nTap a product to add',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: cart.items.length,
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$symbol${item.unitPrice.toStringAsFixed(0)} each',
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (item.transportPerUnit > 0)
                            Text(
                              'Transport: $symbol${item.transportPerUnit.toStringAsFixed(2)} / unit',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.local_shipping_outlined,
                                size: 18),
                            tooltip: 'Set transport per unit',
                            onPressed: () =>
                                _editProductTransport(item, symbol),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateQty(item.product.id, item.qty - 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${item.qty.toInt()}',
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.add_circle_outline, size: 18),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .addProduct(item.product),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 72,
                            child: Text(
                              '$symbol${item.lineTotal.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _TotalRow(
                  'Subtotal', '$symbol${cart.subTotal.toStringAsFixed(2)}'),
              if (cart.totalTax > 0)
                _TotalRow('Tax', '$symbol${cart.totalTax.toStringAsFixed(2)}'),
              if (cart.globalDiscount > 0)
                _TotalRow('Discount',
                    '-$symbol${cart.globalDiscount.toStringAsFixed(2)}'),
              _TotalRow('Line Transport',
                  '$symbol${cart.lineTransportCost.toStringAsFixed(2)}'),
              _TotalRow(
                'Additional Transport',
                '$symbol${cart.manualTransportCost.toStringAsFixed(2)}',
                trailing: TextButton(
                  onPressed: () =>
                      _editManualTransport(cart.manualTransportCost, symbol),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  child: const Text('Set'),
                ),
              ),
              _TotalRow('Total Transport Expense',
                  '$symbol${cart.transportCost.toStringAsFixed(2)}'),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '$symbol${cart.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cart.isEmpty
                          ? null
                          : () => ref.read(cartProvider.notifier).clear(),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: cart.isEmpty ? null : _checkout,
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickCustomer() {
    final customers = ref.read(contactsProvider.notifier).customers;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Customer'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(cartProvider.notifier)
                  .setCustomer(id: '', name: 'Walk-In Customer');
              Navigator.pop(ctx);
            },
            child: const Text('Walk-In Customer'),
          ),
          ...customers.map(
            (c) => SimpleDialogOption(
              onPressed: () {
                ref
                    .read(cartProvider.notifier)
                    .setCustomer(id: c.id, name: c.name);
                Navigator.pop(ctx);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.phone.isNotEmpty
                        ? c.phone
                        : c.email.isNotEmpty
                            ? c.email
                            : 'No contact info',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editManualTransport(double current, String symbol) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(2) : '',
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Additional Transport Cost'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter additional transport cost',
            prefixText: symbol,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(ctx, parsed < 0 ? 0 : parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null) {
      ref.read(cartProvider.notifier).setTransportCost(value);
    }
  }

  Future<void> _editProductTransport(CartItem item, String symbol) async {
    final controller = TextEditingController(
      text: item.transportPerUnit > 0
          ? item.transportPerUnit.toStringAsFixed(2)
          : '',
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Transport for ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Per-unit transport cost',
            prefixText: symbol,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(ctx, parsed < 0 ? 0 : parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value != null) {
      ref
          .read(cartProvider.notifier)
          .updateProductTransport(item.product.id, value);
    }
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontSize: 13)),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentResult {
  const _PaymentResult({
    required this.method,
    required this.paidAmount,
    required this.label,
  });

  final String method;
  final double paidAmount;
  final String label;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.cart});

  final CartState cart;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _method = 'cash';
  String _paymentType = 'full';
  final TextEditingController _partialCtrl = TextEditingController();

  @override
  void dispose() {
    _partialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const symbol = AppConstants.defaultCurrencySymbol;
    final total = widget.cart.grandTotal;
    final paidPreview = _calculatePaidAmount(total);
    final duePreview = total - paidPreview;

    return AlertDialog(
      title: const Text('Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '$symbol${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Payment Type:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'full', label: Text('Full')),
                ButtonSegment(value: 'partial', label: Text('Partial')),
                ButtonSegment(value: 'credit', label: Text('Credit')),
              ],
              selected: {_paymentType},
              onSelectionChanged: (s) => setState(() => _paymentType = s.first),
            ),
            if (_paymentType == 'partial') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _partialCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Paid amount now',
                  prefixText: symbol,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Payment Method:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cash', label: Text('Cash')),
                ButtonSegment(value: 'card', label: Text('Card')),
                ButtonSegment(value: 'mobile', label: Text('Mobile')),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            const SizedBox(height: 12),
            Text(
              'Paid: $symbol${paidPreview.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'Due: $symbol${duePreview.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final paidAmount = _calculatePaidAmount(total);
            if (paidAmount < 0 || paidAmount > total) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Invalid paid amount for partial payment.')),
              );
              return;
            }

            final label = _paymentType == 'full'
                ? 'Full paid'
                : _paymentType == 'partial'
                    ? 'Partial paid'
                    : 'Credit sale';

            Navigator.pop(
              context,
              _PaymentResult(
                method: _method,
                paidAmount: paidAmount,
                label: label,
              ),
            );
          },
          child: const Text('Confirm Sale'),
        ),
      ],
    );
  }

  double _calculatePaidAmount(double total) {
    if (_paymentType == 'full') return total;
    if (_paymentType == 'credit') return 0;
    final partial = double.tryParse(_partialCtrl.text.trim()) ?? 0;
    return partial;
  }
}
