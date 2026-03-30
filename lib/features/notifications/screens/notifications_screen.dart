import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const templates = [
      _Template('Sale Complete', 'sale_complete',
          'Dear {customer_name}, your invoice {invoice_no} for {amount} is ready. Thank you!',
          true),
      _Template('Low Stock Alert', 'low_stock',
          'Alert: Product {product_name} is running low. Current stock: {quantity}',
          true),
      _Template('Payment Due', 'payment_due',
          'Reminder: Payment of {amount} for invoice {invoice_no} is due on {due_date}.',
          false),
    ];

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Notification Templates',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Template'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = templates[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          Switch(
                            value: t.isActive,
                            onChanged: (_) {},
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t.event,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 8),
                      Text(t.body,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Variables: {customer_name}, {invoice_no}, {amount}, {due_date}, {product_name}, {quantity}',
                          style: TextStyle(fontSize: 10, color: AppColors.textLight, fontStyle: FontStyle.italic)),
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

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Notification Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Template Name')),
            const SizedBox(height: 12),
            TextField(controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Message Body'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}

class _Template {
  const _Template(this.name, this.event, this.body, this.isActive);
  final String name;
  final String event;
  final String body;
  final bool isActive;
}
