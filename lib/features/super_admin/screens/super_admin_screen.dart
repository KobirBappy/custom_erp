import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/id_formatter.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../subscription/utils/payment_voucher_printer.dart';
import '../providers/super_admin_provider.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(superAdminBusinessesProvider);
    final requestsAsync = ref.watch(superAdminPaymentRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Super Admin Panel',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.security, size: 16),
                  label: Text(
                    AppConstants.superAdminEmails.first,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Approve business enrollment and payment requests before enabling POS/Sell.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const TabBar(
              tabs: [
                Tab(text: 'Businesses'),
                Tab(text: 'Payment Requests'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  businessesAsync.when(
                    data: _buildBusinessList,
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Failed to load businesses: $e')),
                  ),
                  requestsAsync.when(
                    data: _buildPaymentRequestList,
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('Failed to load payment requests: $e')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessList(List<SuperAdminBusinessItem> businesses) {
    if (businesses.isEmpty) {
      return const Center(child: Text('No businesses found.'));
    }

    return ListView.separated(
      itemCount: businesses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final business = businesses[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        business.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _statusChip(business.onboardingStatus),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Business Code: ${IdFormatter.numericCode(business.id)}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Business Name: ${business.name}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Owner UID: ${business.ownerId}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('License: ${business.licensePaymentStatus}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (_processing ||
                              business.onboardingStatus == 'approved')
                          ? null
                          : () => _approveBusiness(business.id),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Approve Business'),
                    ),
                    OutlinedButton.icon(
                      onPressed: (_processing ||
                              business.onboardingStatus == 'rejected')
                          ? null
                          : () => _rejectBusiness(business.id),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject Business'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentRequestList(List<SuperAdminPaymentRequestItem> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text('No payment requests found.'));
    }

    return ListView.separated(
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = requests[index];
        final requestedBy = request.requestedByName.isEmpty
            ? request.requestedBy
            : request.requestedByName;
        final reviewedBy = (request.reviewedByName ?? '').trim().isEmpty
            ? (request.reviewedBy ?? '-')
            : request.reviewedByName!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${request.planName} (${AppConstants.defaultCurrencySymbol}${request.amount.toStringAsFixed(0)})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _statusChip(request.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Business: ${request.businessName.isEmpty ? 'Business' : request.businessName}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                    'Business Code: ${IdFormatter.numericCode(request.businessId)}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Requested By: $requestedBy',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Reviewed By: $reviewedBy',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Transaction Ref: ${request.transactionRef}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Payment Method: ${request.paymentMethod}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text('Duration: ${request.durationDays} days',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (_processing || !request.isPending)
                          ? null
                          : () => _approvePayment(request),
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text('Approve Payment'),
                    ),
                    OutlinedButton.icon(
                      onPressed: (_processing || !request.isPending)
                          ? null
                          : () => _rejectPayment(request),
                      icon: const Icon(Icons.block_outlined, size: 16),
                      label: const Text('Reject Payment'),
                    ),
                    OutlinedButton.icon(
                      onPressed: request.status == 'approved'
                          ? () => _printVoucher(request)
                          : null,
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Print Chalan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.trim().toLowerCase();
    final Color color;
    switch (normalized) {
      case 'approved':
      case 'paid':
        color = AppColors.success;
        break;
      case 'pending':
      case 'pending_approval':
        color = AppColors.warning;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _approveBusiness(String businessId) async {
    setState(() => _processing = true);
    try {
      await ref
          .read(superAdminServiceProvider)
          .approveBusiness(businessId: businessId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business approved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _rejectBusiness(String businessId) async {
    final note = await _noteDialog('Reject Business', 'Reason for rejection');
    if (note == null) return;

    setState(() => _processing = true);
    try {
      await ref
          .read(superAdminServiceProvider)
          .rejectBusiness(businessId: businessId, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business request rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejection failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _approvePayment(SuperAdminPaymentRequestItem request) async {
    setState(() => _processing = true);
    try {
      await ref
          .read(superAdminServiceProvider)
          .approvePaymentRequest(request: request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment approved. POS/Sell enabled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment approval failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _rejectPayment(SuperAdminPaymentRequestItem request) async {
    final note = await _noteDialog('Reject Payment', 'Reason for rejection');
    if (note == null) return;

    setState(() => _processing = true);
    try {
      await ref.read(superAdminServiceProvider).rejectPaymentRequest(
            businessId: request.businessId,
            requestId: request.id,
            note: note,
            paymentRequestPath: request.paymentRequestPath,
            businessDocPath: request.businessDocPath,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment request rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment rejection failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _printVoucher(SuperAdminPaymentRequestItem request) async {
    final printable = PaymentRequestItem(
      id: request.id,
      businessId: request.businessId,
      businessName: request.businessName,
      businessPhone: request.businessPhone,
      businessEmail: request.businessEmail,
      businessAddress: request.businessAddress,
      planId: request.planId,
      planName: request.planName,
      amount: request.amount,
      durationDays: request.durationDays,
      paymentMethod: request.paymentMethod,
      transactionRef: request.transactionRef,
      status: request.status,
      requestedBy: request.requestedBy,
      requestedByName: request.requestedByName,
      requestedAt: request.requestedAt,
      reviewedBy: request.reviewedBy,
      reviewedByName: request.reviewedByName,
      reviewedAt: request.reviewedAt,
      note: request.note,
    );

    try {
      await PaymentVoucherPrinter.printChalan(printable);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chalan print failed: $e')),
      );
    }
  }

  Future<String?> _noteDialog(String title, String label) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty) return null;
    return result;
  }
}
