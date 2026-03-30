import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/businesses/screens/businesses_screen.dart';
import '../../features/businesses/screens/locations_screen.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/users/screens/roles_permissions_screen.dart';
import '../../features/contacts/screens/contacts_screen.dart';
import '../../features/contacts/screens/contact_form_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/products/screens/categories_screen.dart';
import '../../features/products/screens/brands_units_screen.dart';
import '../../features/purchases/screens/purchases_screen.dart';
import '../../features/purchases/screens/purchase_form_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/sales/screens/pos_screen.dart';
import '../../features/stock/screens/stock_transfers_screen.dart';
import '../../features/stock/screens/stock_adjustments_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/expenses/screens/expense_form_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/returns/screens/returns_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/super_admin/providers/super_admin_provider.dart';
import '../../features/super_admin/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/screens/super_admin_screen.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import '../../features/subscription/screens/packages_screen.dart';
import '../widgets/app_scaffold.dart';

/// Bridges Riverpod state changes → GoRouter redirect re-evaluation.
/// Keeps a single stable GoRouter instance; no recreation on auth changes.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<bool>(isAuthenticatedProvider, (_, __) => notifyListeners());
    _ref.listen<bool>(isSuperAdminProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue<String>>(
        onboardingStatusProvider, (_, __) => notifyListeners());
    _ref.listen<bool>(sellPosEnabledProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final isAuth = _ref.read(isAuthenticatedProvider);
    final isSuperAdmin = _ref.read(isSuperAdminProvider);
    final onboardingStatus = _ref.read(onboardingStatusProvider).maybeWhen(
          data: (s) => s,
          orElse: () => 'loading',
        );
    final sellPosEnabled = _ref.read(sellPosEnabledProvider);

    final loc = state.matchedLocation;
    final loggingIn = loc == AppRoutes.login;
    final inPackages = loc == AppRoutes.packages;
    final inSuperAdmin = loc == AppRoutes.superAdmin;
    final inSuperAdminDashboard = loc == AppRoutes.superAdminDashboard;
    final inSuperAdminArea = inSuperAdmin || inSuperAdminDashboard;
    final inOwnerBranchArea = loc == AppRoutes.locations;
    final inSell = loc.startsWith(AppRoutes.sell) || loc == AppRoutes.pos;

    // Not logged in → always go to login.
    if (!isAuth && !loggingIn) return AppRoutes.login;

    // Already logged in but on login page → send to dashboard.
    if (isAuth && loggingIn) {
      return isSuperAdmin ? AppRoutes.superAdminDashboard : AppRoutes.dashboard;
    }

    // Non-super-admin trying to access super admin area → go to dashboard.
    if (isAuth && !isSuperAdmin && inSuperAdminArea) {
      return AppRoutes.dashboard;
    }

    // Super admin should use dedicated dashboard, not business dashboard.
    if (isAuth && isSuperAdmin && loc == AppRoutes.dashboard) {
      return AppRoutes.superAdminDashboard;
    }
    if (isAuth && isSuperAdmin && inOwnerBranchArea) {
      return AppRoutes.superAdminDashboard;
    }

    // Business not yet approved → lock to packages page.
    if (isAuth &&
        !isSuperAdmin &&
        onboardingStatus != 'loading' &&
        onboardingStatus != 'approved' &&
        !inPackages) {
      return AppRoutes.packages;
    }

    // POS/Sell requires active license (super admin bypasses this check).
    if (isAuth && !isSuperAdmin && !sellPosEnabled && inSell) {
      return AppRoutes.packages;
    }

    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
              path: AppRoutes.dashboard,
              builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: AppRoutes.superAdminDashboard,
              builder: (_, __) => const SuperAdminDashboardScreen()),
          GoRoute(
              path: AppRoutes.businesses,
              builder: (_, __) => const BusinessesScreen()),
          GoRoute(
              path: AppRoutes.locations,
              builder: (_, __) => const LocationsScreen()),
          GoRoute(
              path: AppRoutes.users, builder: (_, __) => const UsersScreen()),
          GoRoute(
              path: AppRoutes.rolesPermissions,
              builder: (_, __) => const RolesPermissionsScreen()),
          GoRoute(
            path: AppRoutes.contacts,
            builder: (_, __) => const ContactsScreen(),
            routes: [
              GoRoute(
                  path: 'new', builder: (_, __) => const ContactFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ContactFormScreen(contactId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.products,
            builder: (_, __) => const ProductsScreen(),
            routes: [
              GoRoute(
                  path: 'new', builder: (_, __) => const ProductFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ProductFormScreen(productId: state.pathParameters['id']),
              ),
              GoRoute(
                  path: 'categories',
                  builder: (_, __) => const CategoriesScreen()),
              GoRoute(
                  path: 'brands-units',
                  builder: (_, __) => const BrandsUnitsScreen()),
            ],
          ),
          GoRoute(
            path: AppRoutes.purchases,
            builder: (_, __) => const PurchasesScreen(),
            routes: [
              GoRoute(
                  path: 'new', builder: (_, __) => const PurchaseFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    PurchaseFormScreen(purchaseId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.sell,
            builder: (_, __) => const SalesScreen(),
            routes: [
              GoRoute(path: 'pos', builder: (_, __) => const PosScreen()),
            ],
          ),
          GoRoute(
              path: AppRoutes.stockTransfers,
              builder: (_, __) => const StockTransfersScreen()),
          GoRoute(
              path: AppRoutes.stockAdjustments,
              builder: (_, __) => const StockAdjustmentsScreen()),
          GoRoute(
            path: AppRoutes.expenses,
            builder: (_, __) => const ExpensesScreen(),
            routes: [
              GoRoute(
                  path: 'new', builder: (_, __) => const ExpenseFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ExpenseFormScreen(expenseId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
              path: AppRoutes.reports,
              builder: (_, __) => const ReportsScreen()),
          GoRoute(
              path: AppRoutes.returns,
              builder: (_, __) => const ReturnsScreen()),
          GoRoute(
              path: AppRoutes.notifications,
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: AppRoutes.settings,
              builder: (_, __) => const SettingsScreen()),
          GoRoute(
              path: AppRoutes.packages,
              builder: (_, __) => const PackagesScreen()),
          GoRoute(
              path: AppRoutes.superAdmin,
              builder: (_, __) => const SuperAdminScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );

  ref.onDispose(notifier.dispose);

  return router;
});
