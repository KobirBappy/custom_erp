import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../router/app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/businesses/providers/business_provider.dart';
import '../../features/super_admin/providers/super_admin_provider.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    if (!isWide) {
      return Scaffold(
        appBar: _buildTopBar(
          context,
          ref,
          isMobile: true,
          isSuperAdmin: isSuperAdmin,
        ),
        drawer: SizedBox(width: 240, child: _buildSidebar(context, ref)),
        body: widget.child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: _sidebarCollapsed ? 64 : 240,
            child: _buildSidebar(context, ref),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBarWidget(context, ref, isMobile: false),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context, WidgetRef ref,
      {required bool isMobile, required bool isSuperAdmin}) {
    final business = ref.watch(currentBusinessProvider);
    return AppBar(
      backgroundColor: AppColors.primary,
      title: Text(
          isSuperAdmin ? 'Super Admin Console' : (business?.name ?? 'ERP')),
      actions: _topBarActions(context, ref, isSuperAdmin: isSuperAdmin),
    );
  }

  Widget _buildTopBarWidget(BuildContext context, WidgetRef ref,
      {required bool isMobile}) {
    final business = ref.watch(currentBusinessProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    return Container(
      height: 60,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _sidebarCollapsed ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSuperAdmin ? 'Super Admin Console' : (business?.name ?? 'ERP'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          ..._topBarActions(context, ref, isSuperAdmin: isSuperAdmin),
        ],
      ),
    );
  }

  List<Widget> _topBarActions(BuildContext context, WidgetRef ref,
      {required bool isSuperAdmin}) {
    if (isSuperAdmin) {
      return [
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.superAdmin),
          icon: const Icon(Icons.pending_actions_outlined, size: 14),
          label: const Text('Approvals', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        const _UserAvatar(),
        const SizedBox(width: 8),
      ];
    }

    return [
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.calendar_today, size: 14, color: Colors.white),
        label: const Text('Filter by date',
            style: TextStyle(color: Colors.white, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white54),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () => context.go(AppRoutes.sell),
        icon: const Icon(Icons.point_of_sale, size: 14),
        label: const Text('POS', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        onPressed: () {},
      ),
      const _UserAvatar(),
      const SizedBox(width: 8),
    ];
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref) {
    final business = ref.watch(currentBusinessProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final homeRoute =
        isSuperAdmin ? AppRoutes.superAdminDashboard : AppRoutes.dashboard;
    return Container(
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Brand header
          Container(
            height: 60,
            color: AppColors.sidebarDark,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  isSuperAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.storefront,
                  color: Colors.white,
                  size: 22,
                ),
                if (!_sidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSuperAdmin
                          ? 'Super Admin'
                          : (business?.name ?? 'My Business'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    route: homeRoute,
                    collapsed: _sidebarCollapsed),
                if (isSuperAdmin)
                  _NavItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Approval Queue',
                      route: AppRoutes.superAdmin,
                      collapsed: _sidebarCollapsed),
                if (isSuperAdmin)
                  _NavItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Packages',
                      route: AppRoutes.packages,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.people_outline,
                      label: 'User Management',
                      route: AppRoutes.users,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Roles & Permissions',
                      route: AppRoutes.rolesPermissions,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.account_tree_outlined,
                      label: 'Branches',
                      route: AppRoutes.locations,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.contacts_outlined,
                      label: 'Contacts',
                      route: AppRoutes.contacts,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Products',
                      route: AppRoutes.products,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Purchases',
                      route: AppRoutes.purchases,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.sell_outlined,
                      label: 'Sell',
                      route: AppRoutes.sell,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.assignment_return_outlined,
                      label: 'Returns',
                      route: AppRoutes.returns,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.local_shipping_outlined,
                      label: 'Stock Transfers',
                      route: AppRoutes.stockTransfers,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.tune_outlined,
                      label: 'Stock Adjustment',
                      route: AppRoutes.stockAdjustments,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Expenses',
                      route: AppRoutes.expenses,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Reports',
                      route: AppRoutes.reports,
                      collapsed: _sidebarCollapsed),
                if (!isSuperAdmin)
                  _NavItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Packages',
                      route: AppRoutes.packages,
                      collapsed: _sidebarCollapsed),
                _NavItem(
                    icon: Icons.mail_outline,
                    label: 'Notification Templates',
                    route: AppRoutes.notifications,
                    collapsed: _sidebarCollapsed),
                _NavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: AppRoutes.settings,
                    collapsed: _sidebarCollapsed),
              ],
            ),
          ),
          // Logout
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.logout,
                      color: AppColors.sidebarText, size: 20),
                  if (!_sidebarCollapsed) ...[
                    const SizedBox(width: 12),
                    const Text('Logout',
                        style: TextStyle(color: AppColors.sidebarText)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.collapsed,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isActive = currentLocation == route ||
        (route != AppRoutes.dashboard && currentLocation.startsWith(route));

    return Tooltip(
      message: collapsed ? label : '',
      preferBelow: false,
      child: InkWell(
        onTap: () => context.go(route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 12 : 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sidebarActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive ? Colors.white : AppColors.sidebarText),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.sidebarText,
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends ConsumerWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final initials = (user?.displayName ?? 'U')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white24,
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user?.displayName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem(
          enabled: false,
          child: Text(user?.email ?? '',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        const PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
      onSelected: (val) async {
        if (val == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go(AppRoutes.login);
        } else if (val == 'settings') {
          context.go(AppRoutes.settings);
        }
      },
    );
  }
}
