import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../super_admin/providers/super_admin_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/payment_voucher_printer.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    const sym = AppConstants.defaultCurrencySymbol;
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final onboardingAsync = ref.watch(onboardingStatusProvider);
    final licenseAsync = ref.watch(businessLicenseProvider);
    final requestsAsync = ref.watch(paymentRequestsProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final pendingRequest = ref.watch(latestPendingPaymentRequestProvider);

    if (isSuperAdmin) {
      return _buildSuperAdminPackageManager(plansAsync);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Packages & License',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          onboardingAsync.when(
            data: (status) => _onboardingCard(status),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          licenseAsync.when(
            data: (license) => _licenseCard(license, sym),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load license: $e'),
              ),
            ),
          ),
          if (pendingRequest != null) ...[
            const SizedBox(height: 10),
            _pendingRequestCard(pendingRequest),
          ],
          const SizedBox(height: 20),
          const Text('Available Packages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No active package found.'),
                  ),
                );
              }
              return Column(
                children: plans
                    .map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          plan.name,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Text(
                                        '$sym${plan.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${plan.durationDays} days access'),
                                  const SizedBox(height: 10),
                                  ...plan.features.map(
                                    (f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('- $f',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: _processing ||
                                              pendingRequest != null
                                          ? null
                                          : () => _submitPaymentRequest(plan),
                                      icon: const Icon(Icons.send_outlined,
                                          size: 16),
                                      label: Text(_processing
                                          ? 'Submitting...'
                                          : pendingRequest != null
                                              ? 'Pending Approval'
                                              : 'Request Activation'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load plans: $e'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return _requestHistory(requests);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminPackageManager(
      AsyncValue<List<SubscriptionPlan>> plansAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Package Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _processing ? null : () => _addOrEditPlan(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Package'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Create, update, or remove package plans and features for business owners.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No package found. Add your first package.'),
                  ),
                );
              }
              return Column(
                children: plans
                    .map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plan.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Text(
                                      '${AppConstants.defaultCurrencySymbol}${plan.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Duration: ${plan.durationDays} days',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Sort order: ${plan.sortOrder}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...plan.features.map((f) => Text(
                                      '- $f',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary),
                                    )),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _processing
                                          ? null
                                          : () =>
                                              _addOrEditPlan(existing: plan),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16),
                                      label: const Text('Edit'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _processing
                                          ? null
                                          : () => _removePlan(plan),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                      ),
                                      label: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load package list: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onboardingCard(String status) {
    final normalized = status.trim().toLowerCase();
    final bool approved = normalized == 'approved';
    final bool rejected = normalized == 'rejected';

    final color = approved
        ? AppColors.success
        : rejected
            ? AppColors.error
            : AppColors.warning;

    final text = approved
        ? 'Business enrollment approved by super admin.'
        : rejected
            ? 'Business enrollment was rejected. Contact super admin.'
            : 'Business is pending super admin approval. Most modules are locked until approved.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              approved
                  ? Icons.verified_user_outlined
                  : rejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_outlined,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _licenseCard(BusinessLicense license, String sym) {
    final activeColor =
        license.canUseSellPos ? AppColors.success : AppColors.error;
    final statusText = license.canUseSellPos
        ? 'Active'
        : license.isExpired
            ? 'Expired'
            : 'Inactive';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Current License',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'Plan: ${license.planName.isEmpty ? 'Not selected' : license.planName}'),
            Text('Payment: ${license.paymentStatus}'),
            Text(
                'Expires: ${license.expiresAt?.toLocal().toString().split(' ').first ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(
              license.canUseSellPos
                  ? 'Sell and POS modules are enabled.'
                  : 'Sell and POS modules are locked until super admin approves payment request.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingRequestCard(PaymentRequestItem request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Pending Payment Request',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Plan: ${request.planName}'),
            Text('Transaction: ${request.transactionRef}'),
            Text('Payment method: ${request.paymentMethod}'),
            const SizedBox(height: 6),
            const Text(
              'Your request has been submitted and is waiting for super admin approval.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _processing ? null : () => _cancelRequest(request),
                icon: const Icon(Icons.cancel_outlined,
                    size: 16, color: AppColors.error),
                label: const Text('Cancel Request',
                    style: TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRequest(PaymentRequestItem request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Payment Request'),
        content:
            Text('Cancel your pending request for "${request.planName}"?\n\n'
                'Transaction ref: ${request.transactionRef}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, Keep It')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processing = true);
    try {
      await ref.read(subscriptionProvider).cancelPaymentRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment request cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _requestHistory(List<PaymentRequestItem> requests) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Request History',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...requests.take(5).map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${req.planName} - ${req.transactionRef}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (req.status == 'approved') ...[
                        IconButton(
                          tooltip: 'Print Chalan',
                          onPressed: () => _printVoucher(req),
                          icon: const Icon(Icons.print_outlined, size: 18),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        req.status,
                        style: TextStyle(
                          color: req.status == 'approved'
                              ? AppColors.success
                              : req.status == 'rejected'
                                  ? AppColors.error
                                  : AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPaymentRequest(SubscriptionPlan plan) async {
    final refCtrl = TextEditingController();
    String paymentMethod = 'card';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Request ${plan.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(
                      value: 'mobile', child: Text('Mobile Payment')),
                ],
                onChanged: (v) => setLocal(() => paymentMethod = v ?? 'card'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Transaction Ref',
                  hintText: 'Enter payment transaction reference',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit Request')),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      refCtrl.dispose();
      return;
    }

    if (refCtrl.text.trim().isEmpty) {
      refCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction reference is required.')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      await ref.read(subscriptionProvider).submitPaymentRequest(
            plan: plan,
            paymentMethod: paymentMethod,
            transactionRef: refCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Payment request submitted. Waiting for super admin.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
      refCtrl.dispose();
    }
  }

  Future<void> _printVoucher(PaymentRequestItem request) async {
    try {
      await PaymentVoucherPrinter.printChalan(request);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chalan print failed: $e')),
      );
    }
  }

  Future<void> _addOrEditPlan({SubscriptionPlan? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final durationCtrl = TextEditingController(
      text: existing != null ? '${existing.durationDays}' : '30',
    );
    final featuresCtrl = TextEditingController(
      text: existing?.features.join('\n') ?? '',
    );
    final sortOrderCtrl = TextEditingController(
      text: existing != null ? '${existing.sortOrder}' : '0',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Package' : 'Edit Package'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Plan Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (days)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Sort Order (0,1,2...)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: featuresCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Features (one per line)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      nameCtrl.dispose();
      priceCtrl.dispose();
      durationCtrl.dispose();
      featuresCtrl.dispose();
      sortOrderCtrl.dispose();
      return;
    }

    final price = double.tryParse(priceCtrl.text.trim());
    final duration = int.tryParse(durationCtrl.text.trim());
    final sortOrder = int.tryParse(sortOrderCtrl.text.trim()) ?? 0;
    final features = featuresCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (price == null || duration == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Price and duration must be valid numbers.')),
      );
      nameCtrl.dispose();
      priceCtrl.dispose();
      durationCtrl.dispose();
      featuresCtrl.dispose();
      sortOrderCtrl.dispose();
      return;
    }

    setState(() => _processing = true);
    try {
      await ref.read(subscriptionProvider).upsertSubscriptionPlan(
            id: existing?.id,
            name: nameCtrl.text.trim(),
            price: price,
            durationDays: duration,
            features: features,
            sortOrder: sortOrder,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Package added successfully.'
              : 'Package updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
      nameCtrl.dispose();
      priceCtrl.dispose();
      durationCtrl.dispose();
      featuresCtrl.dispose();
      sortOrderCtrl.dispose();
    }
  }

  Future<void> _removePlan(SubscriptionPlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Package'),
        content: Text('Delete package "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _processing = true);
    try {
      await ref.read(subscriptionProvider).deleteSubscriptionPlan(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}
