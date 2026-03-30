import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class PermissionDefinition {
  const PermissionDefinition({
    required this.key,
    required this.title,
  });

  final String key;
  final String title;
}

const List<String> rolePermissionRoles = <String>[
  'owner',
  'admin',
  'manager',
  'cashier',
];

const List<PermissionDefinition> permissionDefinitions = <PermissionDefinition>[
  PermissionDefinition(
    key: 'view_dashboard_reports',
    title: 'Dashboard & Reports',
  ),
  PermissionDefinition(
    key: 'manage_users_roles',
    title: 'Manage Users & Roles',
  ),
  PermissionDefinition(
    key: 'manage_branches_settings',
    title: 'Manage Branches / Settings',
  ),
  PermissionDefinition(
    key: 'manage_products_catalog',
    title: 'Products / Categories / Brands / Units',
  ),
  PermissionDefinition(
    key: 'manage_purchases',
    title: 'Purchases',
  ),
  PermissionDefinition(
    key: 'pos_sales',
    title: 'POS & Sales',
  ),
  PermissionDefinition(
    key: 'manage_returns',
    title: 'Create / Edit Returns',
  ),
  PermissionDefinition(
    key: 'delete_sales_purchases',
    title: 'Delete Sales / Purchases',
  ),
  PermissionDefinition(
    key: 'stock_transfer_adjustment',
    title: 'Stock Transfers / Adjustments',
  ),
  PermissionDefinition(
    key: 'expense_management',
    title: 'Expense Management',
  ),
  PermissionDefinition(
    key: 'packages_license',
    title: 'Packages / License Requests',
  ),
];

const Map<String, Map<String, bool>> defaultRolePermissions =
    <String, Map<String, bool>>{
  'view_dashboard_reports': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': false,
  },
  'manage_users_roles': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': false,
    'cashier': false,
  },
  'manage_branches_settings': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': false,
    'cashier': false,
  },
  'manage_products_catalog': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': false,
  },
  'manage_purchases': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': false,
  },
  'pos_sales': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': true,
  },
  'manage_returns': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': false,
  },
  'delete_sales_purchases': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': false,
    'cashier': false,
  },
  'stock_transfer_adjustment': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': false,
  },
  'expense_management': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': true,
    'cashier': true,
  },
  'packages_license': <String, bool>{
    'owner': true,
    'admin': true,
    'manager': false,
    'cashier': false,
  },
};

class RolePermissionsState {
  const RolePermissionsState({required this.matrix});

  final Map<String, Map<String, bool>> matrix;

  bool isAllowed(String permissionKey, String role) {
    return matrix[permissionKey]?[role] ?? false;
  }
}

final rolePermissionsProvider = StreamProvider<RolePermissionsState>((ref) {
  if (AppConstants.demoMode) {
    return Stream<RolePermissionsState>.value(
      const RolePermissionsState(matrix: defaultRolePermissions),
    );
  }

  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null || businessId.isEmpty) {
    return Stream<RolePermissionsState>.value(
      const RolePermissionsState(matrix: defaultRolePermissions),
    );
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(businessId)
      .collection('settings')
      .doc('role_permissions')
      .snapshots()
      .map((snap) {
    final data = snap.data() ?? const <String, dynamic>{};
    final raw = data['permissions'] as Map<String, dynamic>?;
    return RolePermissionsState(
      matrix: _mergeWithDefaults(raw),
    );
  });
});

final canEditRolePermissionsProvider = Provider<bool>((ref) {
  final role = ref.watch(authProvider)?.role.toLowerCase() ?? '';
  return role == 'owner' || role == 'admin';
});

final rolePermissionsServiceProvider = Provider<RolePermissionsService>((ref) {
  return RolePermissionsService(ref);
});

class RolePermissionsService {
  RolePermissionsService(this.ref);

  final Ref ref;

  Future<void> setPermission({
    required String permissionKey,
    required String role,
    required bool allowed,
  }) async {
    final canEdit = ref.read(canEditRolePermissionsProvider);
    if (!canEdit) {
      throw Exception('Only owner/admin can edit role permissions.');
    }
    if (!rolePermissionRoles.contains(role)) {
      throw Exception('Invalid role.');
    }
    final known = permissionDefinitions.any((def) => def.key == permissionKey);
    if (!known) {
      throw Exception('Invalid permission key.');
    }

    if (AppConstants.demoMode) return;
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('role_permissions')
        .set({
      'permissions': {
        permissionKey: {role: allowed},
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

Map<String, Map<String, bool>> _mergeWithDefaults(Map<String, dynamic>? raw) {
  final merged = <String, Map<String, bool>>{};

  for (final def in permissionDefinitions) {
    final base = <String, bool>{
      ...?defaultRolePermissions[def.key],
    };
    final rawForKey = raw?[def.key];
    if (rawForKey is Map) {
      for (final role in rolePermissionRoles) {
        final v = rawForKey[role];
        if (v is bool) {
          base[role] = v;
        }
      }
    }
    merged[def.key] = base;
  }

  return merged;
}
