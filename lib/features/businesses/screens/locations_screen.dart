import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_location.dart';
import '../providers/business_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Locations',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Text('(Branches)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showForm(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Branch'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final l = locations[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _typeColor(l.type).withOpacity(0.15),
                    child: Icon(_typeIcon(l.type),
                        color: _typeColor(l.type), size: 20),
                  ),
                  title: Text(l.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${l.type.name} · ${l.city.isNotEmpty ? l.city : 'No city'}'),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showForm(context, ref, existing: l);
                      }
                      if (val == 'delete') {
                        ref.read(locationsProvider.notifier).delete(l.id);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _typeColor(LocationType type) {
    switch (type) {
      case LocationType.storefront:
        return AppColors.cardBlue;
      case LocationType.warehouse:
        return AppColors.cardOrange;
      case LocationType.office:
        return AppColors.cardGreen;
    }
  }

  IconData _typeIcon(LocationType type) {
    switch (type) {
      case LocationType.storefront:
        return Icons.storefront_outlined;
      case LocationType.warehouse:
        return Icons.warehouse_outlined;
      case LocationType.office:
        return Icons.business_outlined;
    }
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {BusinessLocation? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final prefixCtrl =
        TextEditingController(text: existing?.invoicePrefix ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final currentBusiness = ref.read(currentBusinessProvider);
    LocationType type = existing?.type ?? LocationType.storefront;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(existing == null ? 'Add Branch' : 'Edit Branch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Branch Name *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<LocationType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: LocationType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) =>
                    setDlg(() => type = v ?? LocationType.storefront),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'City')),
              const SizedBox(height: 12),
              TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(
                  controller: prefixCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Invoice Prefix')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final model = BusinessLocation(
                  id: existing?.id ?? '',
                  businessId:
                      currentBusiness?.id ?? AppConstants.demoBusinessId,
                  name: name,
                  type: type,
                  city: cityCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  invoicePrefix: prefixCtrl.text.trim(),
                  isActive: existing?.isActive ?? true,
                );

                if (existing == null) {
                  await ref.read(locationsProvider.notifier).add(model);
                } else {
                  await ref.read(locationsProvider.notifier).update(model);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
