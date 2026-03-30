import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/brand.dart';
import '../models/unit.dart';
import '../providers/product_provider.dart';
import '../../../core/constants/app_constants.dart';

class BrandsUnitsScreen extends ConsumerStatefulWidget {
  const BrandsUnitsScreen({super.key});

  @override
  ConsumerState<BrandsUnitsScreen> createState() => _BrandsUnitsScreenState();
}

class _BrandsUnitsScreenState extends ConsumerState<BrandsUnitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  void _goBackToProducts() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/products');
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showBrandDialog({Brand? existing}) {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Brand' : 'Edit Brand'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Brand Name'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                if (existing == null) {
                  await ref.read(brandsProvider.notifier).add(Brand(
                      id: '',
                      businessId: AppConstants.demoBusinessId,
                      name: name));
                } else {
                  await ref
                      .read(brandsProvider.notifier)
                      .update(existing.copyWith(name: name));
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: Text(existing == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showUnitDialog({Unit? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final abbrCtrl = TextEditingController(text: existing?.abbreviation ?? '');
    var decimals = existing?.allowDecimals ?? false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(existing == null ? 'Add Unit' : 'Edit Unit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Unit Name'),
                  autofocus: true),
              const SizedBox(height: 8),
              TextField(
                  controller: abbrCtrl,
                  decoration: const InputDecoration(labelText: 'Abbreviation')),
              const SizedBox(height: 8),
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
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  if (existing == null) {
                    await ref.read(unitsProvider.notifier).add(Unit(
                        id: '',
                        businessId: AppConstants.demoBusinessId,
                        name: name,
                        abbreviation: abbrCtrl.text.trim(),
                        allowDecimals: decimals));
                  } else {
                    await ref.read(unitsProvider.notifier).update(
                          existing.copyWith(
                            name: name,
                            abbreviation: abbrCtrl.text.trim(),
                            allowDecimals: decimals,
                          ),
                        );
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                }
              },
              child: Text(existing == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final units = ref.watch(unitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands & Units'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: _goBackToProducts),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Brands'), Tab(text: 'Units')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Brands
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = brands[i];
              return ListTile(
                title: Text(b.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit brand',
                      onPressed: () => _showBrandDialog(existing: b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(brandsProvider.notifier).delete(b.id),
                    ),
                  ],
                ),
              );
            },
          ),
          // Units
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = units[i];
              return ListTile(
                title: Text(u.name),
                subtitle: Text(u.abbreviation),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (u.allowDecimals)
                      const Chip(
                          label:
                              Text('Decimals', style: TextStyle(fontSize: 10))),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit unit',
                      onPressed: () => _showUnitDialog(existing: u),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(unitsProvider.notifier).delete(u.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _tabs.index == 0 ? _showBrandDialog() : _showUnitDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
