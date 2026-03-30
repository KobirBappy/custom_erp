import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../providers/product_provider.dart';
import '../../../core/constants/app_constants.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _goBackToProducts(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/products');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final roots = categories
        .where((c) => c.parentId == null || c.parentId!.isEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBackToProducts(context),
        ),
      ),
      body: roots.isEmpty
          ? const Center(child: Text('No categories yet. Add one below.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: roots.length,
              itemBuilder: (_, i) {
                final root = roots[i];
                final subs =
                    categories.where((c) => c.parentId == root.id).toList();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(root.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          tooltip: 'Add sub-category',
                          onPressed: () => _showDialog(context, ref,
                              parentId: root.id, parentName: root.name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit category',
                          onPressed: () =>
                              _showDialog(context, ref, existing: root),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => ref
                              .read(categoriesProvider.notifier)
                              .delete(root.id),
                        ),
                      ],
                    ),
                    children: subs
                        .map((s) => ListTile(
                              contentPadding:
                                  const EdgeInsets.only(left: 32, right: 8),
                              title: Text(s.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 16),
                                    tooltip: 'Edit sub-category',
                                    onPressed: () => _showDialog(
                                      context,
                                      ref,
                                      existing: s,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16),
                                    onPressed: () => ref
                                        .read(categoriesProvider.notifier)
                                        .delete(s.id),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  void _showDialog(
    BuildContext context,
    WidgetRef ref, {
    String? parentId,
    String? parentName,
    Category? existing,
  }) {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing != null
              ? 'Edit Category'
              : parentId == null
                  ? 'Add Category'
                  : 'Add Sub-Category of "$parentName"',
        ),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name *'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;

              if (existing != null) {
                await ref
                    .read(categoriesProvider.notifier)
                    .update(existing.copyWith(name: name));
              } else {
                await ref.read(categoriesProvider.notifier).add(
                      Category(
                        id: '',
                        businessId: AppConstants.demoBusinessId,
                        name: name,
                        parentId: parentId,
                      ),
                    );
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: Text(existing != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
