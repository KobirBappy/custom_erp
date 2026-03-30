import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../businesses/providers/business_provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    final filtered = _search.isEmpty
        ? expenses
        : expenses
            .where((e) =>
                e.categoryName.toLowerCase().contains(_search.toLowerCase()) ||
                e.note.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final total = filtered.fold(0.0, (s, e) => s + e.amount);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Expenses',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _manageCategoriesDialog(context, ref, categories),
                    icon: const Icon(Icons.category_outlined, size: 16),
                    label: const Text('Categories'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/expenses/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ],
          ),
        ),
        Container(
          color: AppColors.primary.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('Total: ',
                  style: TextStyle(color: AppColors.textSecondary)),
              Text(
                CurrencyFormatter.formatSimple(total, symbol: sym),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No expenses found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = filtered[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.cardRed.withOpacity(0.1),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.cardRed, size: 20),
                        ),
                        title: Text(e.categoryName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${DateFormatter.formatDate(e.date)}${e.note.isNotEmpty ? ' · ${e.note}' : ''}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatSimple(e.amount,
                                  symbol: sym),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.error),
                            ),
                            Text(e.paymentMethod,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        onTap: () => context.go('/expenses/${e.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _manageCategoriesDialog(BuildContext ctx, WidgetRef ref, categories) {
    final ctrl = TextEditingController();
    final currentBusiness = ref.read(currentBusinessProvider);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Expense Categories'),
        content: SizedBox(
          width: 320,
          height: 300,
          child: Column(
            children: [
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                            hintText: 'New category name', isDense: true))),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    try {
                      await ref.read(expenseCategoriesProvider.notifier).add(
                            ExpenseCategory(
                              id: '',
                              businessId: currentBusiness?.id ??
                                  AppConstants.demoBusinessId,
                              name: name,
                            ),
                          );
                      ctrl.clear();
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Category add failed: $e')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer(
                  builder: (_, ref, __) {
                    final cats = ref.watch(expenseCategoriesProvider);
                    return ListView.builder(
                      itemCount: cats.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(cats[i].name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          onPressed: () => ref
                              .read(expenseCategoriesProvider.notifier)
                              .delete(cats[i].id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }
}
