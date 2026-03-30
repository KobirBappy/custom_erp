import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../businesses/providers/business_provider.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/unit.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _sellingPriceCtrl = TextEditingController(text: '0');
  final _stockCtrl = TextEditingController(text: '0');
  final _alertCtrl = TextEditingController(text: '5');
  final _taxCtrl = TextEditingController(text: '0');
  ProductType _type = ProductType.single;
  String? _locationId;
  String? _categoryId;
  String? _brandId;
  String? _unitId;
  Product? _existing;
  bool _loading = false;
  final List<_VariationInput> _variationInputs = <_VariationInput>[];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final products = ref.read(productsProvider);
        try {
          _existing = products.firstWhere((p) => p.id == widget.productId);
          _nameCtrl.text = _existing!.name;
          _skuCtrl.text = _existing!.sku;
          _descCtrl.text = _existing!.description;
          _purchasePriceCtrl.text = _existing!.purchasePrice.toString();
          _sellingPriceCtrl.text = _existing!.sellingPrice.toString();
          _stockCtrl.text = _existing!.stockQuantity.toString();
          _alertCtrl.text = _existing!.alertQuantity.toString();
          _taxCtrl.text = _existing!.taxPercent.toString();
          _variationInputs.clear();
          if (_existing!.variations.isNotEmpty) {
            _variationInputs.addAll(
              _existing!.variations.map(_VariationInput.fromVariation),
            );
          }
          setState(() {
            _type = _existing!.type;
            _locationId = _existing!.locationId;
            _categoryId = _existing!.categoryId;
            _brandId = _existing!.brandId;
            _unitId = _existing!.unitId;
          });
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _skuCtrl,
      _descCtrl,
      _purchasePriceCtrl,
      _sellingPriceCtrl,
      _stockCtrl,
      _alertCtrl,
      _taxCtrl,
    ]) {
      c.dispose();
    }
    for (final input in _variationInputs) {
      input.dispose();
    }
    super.dispose();
  }

  void _autoCalcSellingPrice() {
    final cost = double.tryParse(_purchasePriceCtrl.text) ?? 0;
    if (cost > 0 &&
        (_sellingPriceCtrl.text == '0' || _sellingPriceCtrl.text.isEmpty)) {
      _sellingPriceCtrl.text = (cost * 1.3).toStringAsFixed(2);
    }
  }

  void _addVariation() {
    setState(() {
      _variationInputs.add(_VariationInput());
    });
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _selectWhenAvailable({
    required String? id,
    required List<String> currentIds,
    required void Function(String?) assign,
  }) async {
    if (id == null || id.isEmpty) return;
    if (!mounted) return;
    if (currentIds.contains(id)) {
      setState(() => assign(id));
      return;
    }

    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      final categories = ref.read(categoriesProvider).map((e) => e.id).toSet();
      final brands = ref.read(brandsProvider).map((e) => e.id).toSet();
      final units = ref.read(unitsProvider).map((e) => e.id).toSet();
      if (categories.contains(id) ||
          brands.contains(id) ||
          units.contains(id)) {
        setState(() => assign(id));
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Saved, but list refresh is delayed. Please reopen dropdown.')),
    );
  }

  void _goBackToProducts() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/products');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(productsProvider.notifier);
    final currentBusiness = ref.read(currentBusinessProvider);
    final currentLocation = ref.read(currentLocationProvider);
    final parsedPurchase = double.tryParse(_purchasePriceCtrl.text) ?? 0;
    final parsedSelling = double.tryParse(_sellingPriceCtrl.text) ?? 0;
    final parsedStock = double.tryParse(_stockCtrl.text) ?? 0;
    final parsedAlert = double.tryParse(_alertCtrl.text) ?? 5;

    final variations = _type == ProductType.variable
        ? _variationInputs
            .map((v) => v.toVariation())
            .where((v) => v.name.trim().isNotEmpty)
            .toList()
        : <ProductVariation>[];

    if (_type == ProductType.variable && variations.isEmpty) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one variation.')),
      );
      return;
    }

    final variationStockTotal = variations.fold<double>(
      0,
      (sum, v) => sum + v.stockQuantity,
    );
    final variationAlertTotal = variations.fold<double>(
      0,
      (sum, v) => sum + v.alertQuantity,
    );
    final selectedLocationId =
        _locationId ?? _existing?.locationId ?? currentLocation?.id;
    final baseStock =
        _type == ProductType.variable ? variationStockTotal : parsedStock;
    final stockMap = Map<String, double>.from(_existing?.stockByLocation ?? {});
    if (selectedLocationId != null && selectedLocationId.isNotEmpty) {
      stockMap[selectedLocationId] = baseStock;
    }
    final totalStock = stockMap.isEmpty
        ? baseStock
        : stockMap.values.fold<double>(0.0, (sum, v) => sum + v);

    final product = Product(
      id: _existing?.id ?? '',
      businessId: _existing?.businessId ?? currentBusiness?.id ?? '',
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim(),
      type: _type,
      locationId: selectedLocationId,
      categoryId: _categoryId,
      brandId: _brandId,
      unitId: _unitId,
      description: _descCtrl.text.trim(),
      purchasePrice: _type == ProductType.variable
          ? variations.first.purchasePrice
          : parsedPurchase,
      sellingPrice: _type == ProductType.variable
          ? variations.first.sellingPrice
          : parsedSelling,
      stockQuantity: totalStock,
      stockByLocation: stockMap,
      alertQuantity:
          _type == ProductType.variable ? variationAlertTotal : parsedAlert,
      taxPercent: double.tryParse(_taxCtrl.text) ?? 0,
      variations: variations,
    );

    try {
      if (_existing != null) {
        await notifier.update(product);
      } else {
        await notifier.add(product);
      }
      if (mounted) {
        _goBackToProducts();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save product: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addCategoryQuick() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;

    try {
      final id = await ref.read(categoriesProvider.notifier).add(
            Category(
              id: '',
              businessId: AppConstants.demoBusinessId,
              name: result,
            ),
          );
      await _selectWhenAvailable(
        id: id,
        currentIds: ref.read(categoriesProvider).map((e) => e.id).toList(),
        assign: (v) => _categoryId = v,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add category: $e')),
      );
    }
  }

  Future<void> _addBrandQuick() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Brand'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Brand Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;

    try {
      final id = await ref.read(brandsProvider.notifier).add(
            Brand(
              id: '',
              businessId: AppConstants.demoBusinessId,
              name: result,
            ),
          );
      await _selectWhenAvailable(
        id: id,
        currentIds: ref.read(brandsProvider).map((e) => e.id).toList(),
        assign: (v) => _brandId = v,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add brand: $e')),
      );
    }
  }

  Future<void> _addUnitQuick() async {
    final nameCtrl = TextEditingController();
    final abbrCtrl = TextEditingController();
    bool decimals = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Unit Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: abbrCtrl,
                decoration: const InputDecoration(labelText: 'Abbreviation'),
              ),
              CheckboxListTile(
                title: const Text('Allow Decimals'),
                value: decimals,
                onChanged: (v) => setDlg(() => decimals = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, <String, dynamic>{
                'name': nameCtrl.text.trim(),
                'abbr': abbrCtrl.text.trim(),
                'decimals': decimals,
              }),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    abbrCtrl.dispose();
    if (result == null) return;
    final name = (result['name'] as String?) ?? '';
    if (name.isEmpty) return;
    try {
      final id = await ref.read(unitsProvider.notifier).add(
            Unit(
              id: '',
              businessId: AppConstants.demoBusinessId,
              name: name,
              abbreviation: (result['abbr'] as String?) ?? '',
              allowDecimals: (result['decimals'] as bool?) ?? false,
            ),
          );
      await _selectWhenAvailable(
        id: id,
        currentIds: ref.read(unitsProvider).map((e) => e.id).toList(),
        assign: (v) => _unitId = v,
      );
    } catch (e) {
      _showMessage('Could not add unit: $e');
    }
  }

  Future<void> _editCategoryQuick(List<Category> categories) async {
    if (_categoryId == null || _categoryId!.isEmpty) {
      _showMessage('Select a category first.');
      return;
    }
    Category selected;
    try {
      selected = categories.firstWhere((c) => c.id == _categoryId);
    } catch (_) {
      _showMessage('Selected category not found.');
      return;
    }

    final ctrl = TextEditingController(text: selected.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (result == null || result.isEmpty) return;
    try {
      await ref
          .read(categoriesProvider.notifier)
          .update(selected.copyWith(name: result));
      _showMessage('Category updated.');
    } catch (e) {
      _showMessage('Could not update category: $e');
    }
  }

  Future<void> _deleteCategoryQuick() async {
    if (_categoryId == null || _categoryId!.isEmpty) {
      _showMessage('Select a category first.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Delete selected category?'),
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
      await ref.read(categoriesProvider.notifier).delete(_categoryId!);
      if (!mounted) return;
      setState(() => _categoryId = null);
      _showMessage('Category deleted.');
    } catch (e) {
      _showMessage('Could not delete category: $e');
    }
  }

  Future<void> _editBrandQuick(List<Brand> brands) async {
    if (_brandId == null || _brandId!.isEmpty) {
      _showMessage('Select a brand first.');
      return;
    }
    Brand selected;
    try {
      selected = brands.firstWhere((b) => b.id == _brandId);
    } catch (_) {
      _showMessage('Selected brand not found.');
      return;
    }

    final ctrl = TextEditingController(text: selected.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Brand'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Brand Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (result == null || result.isEmpty) return;
    try {
      await ref
          .read(brandsProvider.notifier)
          .update(selected.copyWith(name: result));
      _showMessage('Brand updated.');
    } catch (e) {
      _showMessage('Could not update brand: $e');
    }
  }

  Future<void> _deleteBrandQuick() async {
    if (_brandId == null || _brandId!.isEmpty) {
      _showMessage('Select a brand first.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Brand'),
        content: const Text('Delete selected brand?'),
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
      await ref.read(brandsProvider.notifier).delete(_brandId!);
      if (!mounted) return;
      setState(() => _brandId = null);
      _showMessage('Brand deleted.');
    } catch (e) {
      _showMessage('Could not delete brand: $e');
    }
  }

  Future<void> _editUnitQuick(List<Unit> units) async {
    if (_unitId == null || _unitId!.isEmpty) {
      _showMessage('Select a unit first.');
      return;
    }
    Unit selected;
    try {
      selected = units.firstWhere((u) => u.id == _unitId);
    } catch (_) {
      _showMessage('Selected unit not found.');
      return;
    }

    final nameCtrl = TextEditingController(text: selected.name);
    final abbrCtrl = TextEditingController(text: selected.abbreviation);
    var decimals = selected.allowDecimals;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Unit Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: abbrCtrl,
                decoration: const InputDecoration(labelText: 'Abbreviation'),
              ),
              CheckboxListTile(
                title: const Text('Allow Decimals'),
                value: decimals,
                onChanged: (v) => setDlg(() => decimals = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, <String, dynamic>{
                'name': nameCtrl.text.trim(),
                'abbr': abbrCtrl.text.trim(),
                'decimals': decimals,
              }),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    abbrCtrl.dispose();
    if (result == null) return;
    final name = (result['name'] as String?) ?? '';
    if (name.isEmpty) return;

    try {
      await ref.read(unitsProvider.notifier).update(
            selected.copyWith(
              name: name,
              abbreviation: (result['abbr'] as String?) ?? '',
              allowDecimals: (result['decimals'] as bool?) ?? false,
            ),
          );
      _showMessage('Unit updated.');
    } catch (e) {
      _showMessage('Could not update unit: $e');
    }
  }

  Future<void> _deleteUnitQuick() async {
    if (_unitId == null || _unitId!.isEmpty) {
      _showMessage('Select a unit first.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        content: const Text('Delete selected unit?'),
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
      await ref.read(unitsProvider.notifier).delete(_unitId!);
      if (!mounted) return;
      setState(() => _unitId = null);
      _showMessage('Unit deleted.');
    } catch (e) {
      _showMessage('Could not delete unit: $e');
    }
  }

  Future<void> _editVariation(int idx) async {
    if (idx < 0 || idx >= _variationInputs.length) return;
    final variation = _variationInputs[idx];

    final nameCtrl = TextEditingController(text: variation.nameCtrl.text);
    final skuCtrl = TextEditingController(text: variation.skuCtrl.text);
    final purchaseCtrl =
        TextEditingController(text: variation.purchaseCtrl.text);
    final sellingCtrl = TextEditingController(text: variation.sellingCtrl.text);
    final stockCtrl = TextEditingController(text: variation.stockCtrl.text);
    final alertCtrl = TextEditingController(text: variation.alertCtrl.text);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Variation ${idx + 1}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Variation Name *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: skuCtrl,
                decoration: const InputDecoration(labelText: 'Variation SKU'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: purchaseCtrl,
                decoration: const InputDecoration(labelText: 'Purchase'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sellingCtrl,
                decoration: const InputDecoration(labelText: 'Selling'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: alertCtrl,
                decoration: const InputDecoration(labelText: 'Alert'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        variation.nameCtrl.text = nameCtrl.text.trim();
        variation.skuCtrl.text = skuCtrl.text.trim();
        variation.purchaseCtrl.text = purchaseCtrl.text.trim();
        variation.sellingCtrl.text = sellingCtrl.text.trim();
        variation.stockCtrl.text = stockCtrl.text.trim();
        variation.alertCtrl.text = alertCtrl.text.trim();
      });
    }

    nameCtrl.dispose();
    skuCtrl.dispose();
    purchaseCtrl.dispose();
    sellingCtrl.dispose();
    stockCtrl.dispose();
    alertCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final brands = ref.watch(brandsProvider);
    final units = ref.watch(unitsProvider);
    final locations = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null ? 'Edit Product' : 'Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToProducts,
        ),
        actions: [
          IconButton(
            tooltip: 'Add Purchase',
            onPressed: _loading ? null : () => context.go('/purchases/new'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              _loading ? 'Saving...' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<ProductType>(
                        segments: const [
                          ButtonSegment(
                            value: ProductType.single,
                            label: Text('Single Product'),
                          ),
                          ButtonSegment(
                            value: ProductType.variable,
                            label: Text('Variable Product'),
                          ),
                        ],
                        selected: <ProductType>{_type},
                        onSelectionChanged: (v) {
                          setState(() {
                            _type = v.first;
                            if (_type == ProductType.variable &&
                                _variationInputs.isEmpty) {
                              _variationInputs.add(_VariationInput());
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Product Name *'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _skuCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'SKU'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _categoryId,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('None'),
                                      ),
                                      ...categories.map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _categoryId = v),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Add Category',
                                  onPressed: _addCategoryQuick,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Edit Selected Category',
                                  onPressed: () =>
                                      _editCategoryQuick(categories),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete Selected Category',
                                  onPressed: _deleteCategoryQuick,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _locationId,
                        decoration: const InputDecoration(
                          labelText: 'Branch / Location for Stock',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Use Current Branch'),
                          ),
                          ...locations.map(
                            (l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _locationId = v),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Opening stock will be applied to this branch and centralized in branch-wise stock map.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _brandId,
                                    decoration: const InputDecoration(
                                        labelText: 'Brand'),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('None'),
                                      ),
                                      ...brands.map(
                                        (b) => DropdownMenuItem(
                                          value: b.id,
                                          child: Text(b.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _brandId = v),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Add Brand',
                                  onPressed: _addBrandQuick,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Edit Selected Brand',
                                  onPressed: () => _editBrandQuick(brands),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete Selected Brand',
                                  onPressed: _deleteBrandQuick,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _unitId,
                                    decoration: const InputDecoration(
                                        labelText: 'Unit'),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('None'),
                                      ),
                                      ...units.map(
                                        (u) => DropdownMenuItem(
                                          value: u.id,
                                          child: Text(u.name),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _unitId = v),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Add Unit',
                                  onPressed: _addUnitQuick,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Edit Selected Unit',
                                  onPressed: () => _editUnitQuick(units),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete Selected Unit',
                                  onPressed: _deleteUnitQuick,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_type == ProductType.single) _singlePriceStockCard(),
              if (_type == ProductType.variable) _variationCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _singlePriceStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing & Stock',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Purchase Price *'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onEditingComplete: _autoCalcSellingPrice,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPriceCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Selling Price *'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _taxCtrl,
                    decoration: const InputDecoration(labelText: 'Tax %'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Opening Stock'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _alertCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Alert Quantity'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _variationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Variations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addVariation,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Variation'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _taxCtrl,
              decoration: const InputDecoration(
                  labelText: 'Tax % (applies to product)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            if (_variationInputs.isEmpty)
              const Text(
                'No variation added. Click "Add Variation".',
                style: TextStyle(color: Colors.grey),
              ),
            ..._variationInputs.asMap().entries.map((entry) {
              final idx = entry.key;
              final variation = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Variation ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Edit variation',
                          onPressed: () => _editVariation(idx),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              variation.dispose();
                              _variationInputs.removeAt(idx);
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: variation.nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Variation Name *'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: variation.skuCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Variation SKU'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: variation.purchaseCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Purchase'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: variation.sellingCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Selling'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: variation.stockCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Stock'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: variation.alertCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Alert'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _VariationInput {
  _VariationInput({
    String name = '',
    String sku = '',
    String purchase = '0',
    String selling = '0',
    String stock = '0',
    String alert = '5',
  })  : nameCtrl = TextEditingController(text: name),
        skuCtrl = TextEditingController(text: sku),
        purchaseCtrl = TextEditingController(text: purchase),
        sellingCtrl = TextEditingController(text: selling),
        stockCtrl = TextEditingController(text: stock),
        alertCtrl = TextEditingController(text: alert);

  final TextEditingController nameCtrl;
  final TextEditingController skuCtrl;
  final TextEditingController purchaseCtrl;
  final TextEditingController sellingCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController alertCtrl;

  factory _VariationInput.fromVariation(ProductVariation v) {
    return _VariationInput(
      name: v.name,
      sku: v.sku,
      purchase: v.purchasePrice.toString(),
      selling: v.sellingPrice.toString(),
      stock: v.stockQuantity.toString(),
      alert: v.alertQuantity.toString(),
    );
  }

  ProductVariation toVariation() {
    return ProductVariation(
      name: nameCtrl.text.trim(),
      sku: skuCtrl.text.trim(),
      purchasePrice: double.tryParse(purchaseCtrl.text.trim()) ?? 0.0,
      sellingPrice: double.tryParse(sellingCtrl.text.trim()) ?? 0.0,
      stockQuantity: double.tryParse(stockCtrl.text.trim()) ?? 0.0,
      alertQuantity: double.tryParse(alertCtrl.text.trim()) ?? 5.0,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    skuCtrl.dispose();
    purchaseCtrl.dispose();
    sellingCtrl.dispose();
    stockCtrl.dispose();
    alertCtrl.dispose();
  }
}
