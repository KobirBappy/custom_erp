import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_constants.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(contactsProvider);
    const sym = AppConstants.defaultCurrencySymbol;

    List<Contact> filtered(List<Contact> list) {
      if (_search.isEmpty) return list;
      final q = _search.toLowerCase();
      return list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.email.toLowerCase().contains(q))
          .toList();
    }

    final allFiltered = filtered(all);
    final customers = filtered(
        all.where((c) => c.type != ContactType.supplier).toList());
    final suppliers = filtered(
        all.where((c) => c.type != ContactType.customer).toList());

    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Contacts',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/contacts/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Contact'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'All (${allFiltered.length})'),
                  Tab(text: 'Customers (${customers.length})'),
                  Tab(text: 'Suppliers (${suppliers.length})'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _ContactList(contacts: allFiltered, sym: sym),
              _ContactList(contacts: customers, sym: sym),
              _ContactList(contacts: suppliers, sym: sym),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactList extends ConsumerWidget {
  const _ContactList({required this.contacts, required this.sym});
  final List<Contact> contacts;
  final String sym;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contacts.isEmpty) {
      return const Center(
        child: Text('No contacts found', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = contacts[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _typeColor(c.type).withOpacity(0.15),
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: _typeColor(c.type), fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${c.phone}${c.city.isNotEmpty ? ' · ${c.city}' : ''}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TypeBadge(type: c.type),
                const SizedBox(height: 4),
                if (c.balance != 0)
                  Text(
                    CurrencyFormatter.formatSimple(c.balance.abs(), symbol: sym),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.balance > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
              ],
            ),
            onTap: () => context.go('/contacts/${c.id}'),
          ),
        );
      },
    );
  }

  Color _typeColor(ContactType type) {
    switch (type) {
      case ContactType.customer:
        return AppColors.cardBlue;
      case ContactType.supplier:
        return AppColors.cardOrange;
      case ContactType.both:
        return AppColors.cardGreen;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final ContactType type;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (type) {
      case ContactType.customer:
        color = AppColors.cardBlue;
        label = 'Customer';
      case ContactType.supplier:
        color = AppColors.cardOrange;
        label = 'Supplier';
      case ContactType.both:
        color = AppColors.cardGreen;
        label = 'Both';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
