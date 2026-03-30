import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _lowStockAlerts = true;

  static const _currencies = [
    _CurrencyOption('BDT', '৳', 'Bangladeshi Taka'),
    _CurrencyOption('USD', '\$', 'US Dollar'),
    _CurrencyOption('EUR', '€', 'Euro'),
    _CurrencyOption('GBP', '£', 'British Pound'),
    _CurrencyOption('INR', '₹', 'Indian Rupee'),
    _CurrencyOption('SAR', '﷼', 'Saudi Riyal'),
    _CurrencyOption('AED', 'د.إ', 'UAE Dirham'),
    _CurrencyOption('MYR', 'RM', 'Malaysian Ringgit'),
  ];

  static const _timezones = [
    'Asia/Dhaka',
    'Asia/Kolkata',
    'Asia/Karachi',
    'Asia/Dubai',
    'Asia/Singapore',
    'Asia/Kuala_Lumpur',
    'Europe/London',
    'America/New_York',
    'America/Los_Angeles',
    'UTC',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // ── Business Settings ────────────────────────────────────────────
          _Section(title: 'Business Settings', children: [
            _SettingTile(
              icon: Icons.storefront_outlined,
              title: 'Business Name',
              subtitle: business?.name ?? 'Not set',
              onTap: () => _editTextField(
                context,
                title: 'Business Name',
                current: business?.name ?? '',
                onSave: (v) => _updateBusiness(business?.copyWith(name: v)),
              ),
            ),
            _SettingTile(
              icon: Icons.attach_money,
              title: 'Currency',
              subtitle:
                  '${business?.currencyCode ?? 'BDT'} (${business?.currencySymbol ?? '৳'})',
              onTap: () => _pickCurrency(context, business),
            ),
            _SettingTile(
              icon: Icons.schedule_outlined,
              title: 'Timezone',
              subtitle: business?.timezone ?? 'Asia/Dhaka',
              onTap: () => _pickFromList(
                context,
                title: 'Timezone',
                items: _timezones,
                current: business?.timezone ?? 'Asia/Dhaka',
                onSave: (v) => _updateBusiness(business?.copyWith(timezone: v)),
              ),
            ),
            _SettingTile(
              icon: Icons.calendar_today_outlined,
              title: 'Financial Year Start',
              subtitle: _monthName(business?.financialYearStart ?? 1),
              onTap: () => _pickMonth(context, business),
            ),
            _SettingTile(
              icon: Icons.percent_outlined,
              title: 'Default Profit Margin',
              subtitle:
                  '${(business?.defaultProfitMargin ?? 0).toStringAsFixed(1)}%',
              onTap: () => _editNumber(
                context,
                title: 'Default Profit Margin (%)',
                current:
                    (business?.defaultProfitMargin ?? 0).toStringAsFixed(1),
                onSave: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) {
                    _updateBusiness(
                        business?.copyWith(defaultProfitMargin: parsed));
                  }
                },
              ),
            ),
            _SettingTile(
              icon: Icons.phone_outlined,
              title: 'Business Phone',
              subtitle: business?.phone.isNotEmpty == true
                  ? business!.phone
                  : 'Not set',
              onTap: () => _editTextField(
                context,
                title: 'Business Phone',
                current: business?.phone ?? '',
                keyboardType: TextInputType.phone,
                onSave: (v) => _updateBusiness(business?.copyWith(phone: v)),
              ),
            ),
            _SettingTile(
              icon: Icons.email_outlined,
              title: 'Business Email',
              subtitle: business?.email.isNotEmpty == true
                  ? business!.email
                  : 'Not set',
              onTap: () => _editTextField(
                context,
                title: 'Business Email',
                current: business?.email ?? '',
                keyboardType: TextInputType.emailAddress,
                onSave: (v) => _updateBusiness(business?.copyWith(email: v)),
              ),
            ),
            _SettingTile(
              icon: Icons.location_on_outlined,
              title: 'Address',
              subtitle: business?.address.isNotEmpty == true
                  ? business!.address
                  : 'Not set',
              onTap: () => _editTextField(
                context,
                title: 'Business Address',
                current: business?.address ?? '',
                maxLines: 2,
                onSave: (v) => _updateBusiness(business?.copyWith(address: v)),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Inventory ────────────────────────────────────────────────────
          _Section(title: 'Inventory', children: [
            _SettingTile(
              icon: Icons.warning_amber_outlined,
              title: 'Low Stock Alerts',
              subtitle: 'Get notified when stock is below alert quantity',
              onTap: () => setState(() => _lowStockAlerts = !_lowStockAlerts),
              trailing: Switch(
                value: _lowStockAlerts,
                onChanged: (v) => setState(() => _lowStockAlerts = v),
                activeColor: AppColors.primary,
              ),
            ),
            _SettingTile(
              icon: Icons.inventory_2_outlined,
              title: 'Stock Adjustments',
              subtitle: 'View and correct stock levels',
              onTap: () => context.go(AppRoutes.stockAdjustments),
            ),
            _SettingTile(
              icon: Icons.swap_horiz_outlined,
              title: 'Stock Transfers',
              subtitle: 'Transfer stock between locations',
              onTap: () => context.go(AppRoutes.stockTransfers),
            ),
          ]),
          const SizedBox(height: 16),

          // ── POS & Invoice ────────────────────────────────────────────────
          _Section(title: 'POS & Invoice', children: [
            _SettingTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Packages & License',
              subtitle: 'Activate package to unlock Sell & POS',
              onTap: () => context.go(AppRoutes.packages),
            ),
            _SettingTile(
              icon: Icons.receipt_outlined,
              title: 'Invoice Prefix',
              subtitle: 'Customize invoice number prefix',
              onTap: () => _showInvoicePrefixDialog(context),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Account ──────────────────────────────────────────────────────
          _Section(title: 'Account', children: [
            _SettingTile(
              icon: Icons.business_outlined,
              title: 'Manage Businesses',
              subtitle: 'Add or switch businesses',
              onTap: () => context.go(AppRoutes.businesses),
            ),
            _SettingTile(
              icon: Icons.location_city_outlined,
              title: 'Manage Locations',
              subtitle: 'Add or edit store locations',
              onTap: () => context.go(AppRoutes.locations),
            ),
            _SettingTile(
              icon: Icons.people_outline,
              title: 'User Management',
              subtitle: 'Manage users and roles',
              onTap: () => context.go(AppRoutes.users),
            ),
            _SettingTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Roles & Permissions',
              subtitle: 'View access matrix by role',
              onTap: () => context.go(AppRoutes.rolesPermissions),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _updateBusiness(Business? updated) {
    if (updated == null) return;
    ref.read(businessesProvider.notifier).update(updated);
  }

  String _monthName(int month) {
    if (month >= 1 && month <= 12) return _months[month - 1];
    return 'January';
  }

  // Generic single-line text editor dialog.
  void _editTextField(
    BuildContext context, {
    required String title,
    required String current,
    required void Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: true,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) onSave(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  // Number input dialog.
  void _editNumber(
    BuildContext context, {
    required String title,
    required String current,
    required void Function(String) onSave,
  }) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onSave(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  // Generic pick-from-list dialog.
  void _pickFromList(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String current,
    required void Function(String) onSave,
  }) {
    String selected = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) => RadioListTile<String>(
                dense: true,
                title: Text(items[i]),
                value: items[i],
                groupValue: selected,
                activeColor: AppColors.primary,
                onChanged: (v) => setLocal(() => selected = v ?? current),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                onSave(selected);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickCurrency(BuildContext context, Business? business) {
    String selectedCode = business?.currencyCode ?? 'BDT';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Currency'),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _currencies.length,
              itemBuilder: (_, i) {
                final c = _currencies[i];
                return RadioListTile<String>(
                  dense: true,
                  title: Text('${c.code} – ${c.name}'),
                  subtitle: Text('Symbol: ${c.symbol}'),
                  value: c.code,
                  groupValue: selectedCode,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setLocal(() => selectedCode = v ?? selectedCode),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final chosen =
                    _currencies.firstWhere((c) => c.code == selectedCode);
                _updateBusiness(business?.copyWith(
                  currencyCode: chosen.code,
                  currencySymbol: chosen.symbol,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickMonth(BuildContext context, Business? business) {
    int selectedMonth = business?.financialYearStart ?? 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Financial Year Start'),
          content: SizedBox(
            width: 280,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final month = i + 1;
                final selected = selectedMonth == month;
                return InkWell(
                  onTap: () => setLocal(() => selectedMonth = month),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _months[i].substring(0, 3),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _updateBusiness(
                    business?.copyWith(financialYearStart: selectedMonth));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoicePrefixDialog(BuildContext context) {
    final locationsNotifier = ref.read(locationsProvider.notifier);
    final locations = ref.read(locationsProvider);
    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No locations configured.')),
      );
      return;
    }

    final location = locations.first;
    final ctrl = TextEditingController(
        text: location.invoicePrefix.isEmpty ? 'INV' : location.invoicePrefix);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invoice Prefix'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${location.name}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Prefix (e.g. INV, BL)',
                hintText: 'INV',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Invoices will be numbered as: PREFIX-0001',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final prefix = ctrl.text.trim().toUpperCase();
              if (prefix.isNotEmpty) {
                locationsNotifier
                    .update(location.copyWith(invoicePrefix: prefix));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children:
                children.expand((c) => [c, const Divider(height: 1)]).toList()
                  ..removeLast(),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}

class _CurrencyOption {
  const _CurrencyOption(this.code, this.symbol, this.name);
  final String code;
  final String symbol;
  final String name;
}
