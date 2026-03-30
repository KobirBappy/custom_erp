import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/role_permissions_provider.dart';

class RolesPermissionsScreen extends ConsumerWidget {
  const RolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(authProvider)?.role.toLowerCase() ?? '';
    final canEdit = ref.watch(canEditRolePermissionsProvider);
    final permissionsAsync = ref.watch(rolePermissionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Roles & Permissions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            currentRole.isEmpty
                ? 'Review access by role for your team.'
                : 'Current logged-in role: ${_prettyRole(currentRole)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (canEdit) ...[
            const SizedBox(height: 6),
            const Text(
              'You can edit permissions as owner/admin.',
              style: TextStyle(color: AppColors.success, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoleChip(role: 'owner', color: AppColors.cardRed),
              _RoleChip(role: 'admin', color: AppColors.cardOrange),
              _RoleChip(role: 'manager', color: AppColors.cardGreen),
              _RoleChip(role: 'cashier', color: AppColors.cardBlue),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: permissionsAsync.when(
              data: (state) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  columns: const [
                    DataColumn(label: Text('Module / Action')),
                    DataColumn(label: Text('Owner')),
                    DataColumn(label: Text('Admin')),
                    DataColumn(label: Text('Manager')),
                    DataColumn(label: Text('Cashier')),
                  ],
                  rows: permissionDefinitions
                      .map(
                        (def) => DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Text(def.title),
                              ),
                            ),
                            DataCell(_permissionCell(
                              ref,
                              canEdit: canEdit,
                              permissionKey: def.key,
                              role: 'owner',
                              allowed: state.isAllowed(def.key, 'owner'),
                            )),
                            DataCell(_permissionCell(
                              ref,
                              canEdit: canEdit,
                              permissionKey: def.key,
                              role: 'admin',
                              allowed: state.isAllowed(def.key, 'admin'),
                            )),
                            DataCell(_permissionCell(
                              ref,
                              canEdit: canEdit,
                              permissionKey: def.key,
                              role: 'manager',
                              allowed: state.isAllowed(def.key, 'manager'),
                            )),
                            DataCell(_permissionCell(
                              ref,
                              canEdit: canEdit,
                              permissionKey: def.key,
                              role: 'cashier',
                              allowed: state.isAllowed(def.key, 'cashier'),
                            )),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load permissions: $e'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tip: Permission checks are enforced by Firestore rules and app logic. Update team roles from User Management.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _cell(bool allowed) {
    return Icon(
      allowed ? Icons.check_circle : Icons.cancel_outlined,
      color: allowed ? AppColors.success : AppColors.error,
      size: 18,
    );
  }

  Widget _permissionCell(
    WidgetRef ref, {
    required bool canEdit,
    required String permissionKey,
    required String role,
    required bool allowed,
  }) {
    if (!canEdit) return _cell(allowed);
    return Switch(
      value: allowed,
      activeColor: AppColors.primary,
      onChanged: (next) async {
        try {
          await ref.read(rolePermissionsServiceProvider).setPermission(
                permissionKey: permissionKey,
                role: role,
                allowed: next,
              );
        } catch (_) {
          // Keep UI simple; stream will restore previous value if save fails.
        }
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.color});

  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _prettyRole(role),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _prettyRole(String role) {
  switch (role) {
    case 'owner':
      return 'Owner';
    case 'admin':
      return 'Admin';
    case 'manager':
      return 'Manager';
    case 'cashier':
      return 'Cashier';
    default:
      return role;
  }
}
