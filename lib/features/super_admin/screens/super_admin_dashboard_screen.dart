import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/super_admin_provider.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesAsync = ref.watch(superAdminBusinessesProvider);
    final requestsAsync = ref.watch(superAdminPaymentRequestsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Super Admin Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage business onboarding and subscription activation requests.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          businessesAsync.when(
            data: (businesses) => requestsAsync.when(
              data: (requests) => _OverviewCards(
                totalBusinesses: businesses.length,
                pendingBusinessApprovals:
                    businesses.where((b) => b.pendingApproval).length,
                pendingPayments: requests.where((r) => r.isPending).length,
                approvedPayments:
                    requests.where((r) => r.status == 'approved').length,
                totalApprovedAmount: requests
                    .where((r) => r.status == 'approved')
                    .fold<double>(0, (sum, r) => sum + r.amount),
                totalPendingAmount: requests
                    .where((r) => r.isPending)
                    .fold<double>(0, (sum, r) => sum + r.amount),
              ),
              loading: () => const _LoadingCards(),
              error: (e, _) =>
                  _ErrorCard(message: 'Failed to load payments: $e'),
            ),
            loading: () => const _LoadingCards(),
            error: (e, _) =>
                _ErrorCard(message: 'Failed to load businesses: $e'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.superAdmin),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Open Approval Queue'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.packages),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('View Packages'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({
    required this.totalBusinesses,
    required this.pendingBusinessApprovals,
    required this.pendingPayments,
    required this.approvedPayments,
    required this.totalApprovedAmount,
    required this.totalPendingAmount,
  });

  final int totalBusinesses;
  final int pendingBusinessApprovals;
  final int pendingPayments;
  final int approvedPayments;
  final double totalApprovedAmount;
  final double totalPendingAmount;

  @override
  Widget build(BuildContext context) {
    final cards = <_OverviewCardData>[
      _OverviewCardData(
        label: 'Total Businesses',
        value: '$totalBusinesses',
        icon: Icons.storefront_outlined,
        color: AppColors.cardBlue,
      ),
      _OverviewCardData(
        label: 'Pending Enrollment',
        value: '$pendingBusinessApprovals',
        icon: Icons.hourglass_top_outlined,
        color: AppColors.warning,
      ),
      _OverviewCardData(
        label: 'Pending Payments',
        value: '$pendingPayments',
        icon: Icons.payments_outlined,
        color: AppColors.cardOrange,
      ),
      _OverviewCardData(
        label: 'Approved Payments',
        value: '$approvedPayments',
        icon: Icons.verified_outlined,
        color: AppColors.success,
      ),
      _OverviewCardData(
        label: 'Approved Amount',
        value: CurrencyFormatter.formatSimple(
          totalApprovedAmount,
          symbol: AppConstants.defaultCurrencySymbol,
        ),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.cardGreen,
      ),
      _OverviewCardData(
        label: 'Pending Amount',
        value: CurrencyFormatter.formatSimple(
          totalPendingAmount,
          symbol: AppConstants.defaultCurrencySymbol,
        ),
        icon: Icons.hourglass_bottom_outlined,
        color: AppColors.cardPurple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (_, i) => _OverviewCard(card: cards[i]),
        );
      },
    );
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.card});
  final _OverviewCardData card;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: card.color.withOpacity(0.16),
              child: Icon(card.icon, color: card.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    card.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
