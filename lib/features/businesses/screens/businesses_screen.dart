import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../providers/business_provider.dart';
import '../../../core/constants/app_colors.dart';

class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(businessesProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Businesses',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showForm(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Business'),
              ),
            ],
          ),
        ),
        Expanded(
          child: businesses.isEmpty
              ? const Center(child: Text('No businesses yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: businesses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final b = businesses[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(b.name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(b.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${b.currencyCode} · ${b.phone.isNotEmpty ? b.phone : 'No phone'}'),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showForm(context, ref, business: b);
                            } else if (val == 'delete') {
                              ref
                                  .read(businessesProvider.notifier)
                                  .delete(b.id);
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

  void _showForm(BuildContext context, WidgetRef ref, {Business? business}) {
    final nameCtrl = TextEditingController(text: business?.name ?? '');
    final phoneCtrl = TextEditingController(text: business?.phone ?? '');
    final emailCtrl = TextEditingController(text: business?.email ?? '');
    String currency = business?.currencyCode ?? 'BDT';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(business == null ? 'Add Business' : 'Edit Business'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Business Name *')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                if (business == null) {
                  ref.read(businessesProvider.notifier).add(
                        Business(
                            id: '',
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            currencyCode: currency,
                            currencySymbol: '৳'),
                      );
                } else {
                  ref.read(businessesProvider.notifier).update(
                        business.copyWith(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim()),
                      );
                }
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
