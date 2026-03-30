import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/role_permissions_provider.dart';
import '../models/business_user.dart';
import '../providers/users_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(businessUsersProvider);
    final currentUser = ref.watch(authProvider);
    final actorRole = currentUser?.role.toLowerCase() ?? '';
    final permissions = ref.watch(rolePermissionsProvider).valueOrNull;
    final canManageRoles =
        permissions?.isAllowed('manage_users_roles', actorRole) ??
            (actorRole == 'owner' || actorRole == 'admin');

    const roles = [
      _RoleData('owner', 'Owner', 'Full access + business settings',
          AppColors.cardRed),
      _RoleData('admin', 'Admin', 'Full access to all features',
          AppColors.cardOrange),
      _RoleData('manager', 'Manager', 'Reports and inventory access',
          AppColors.cardGreen),
      _RoleData('cashier', 'Cashier', 'POS and basic sales access',
          AppColors.cardBlue),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('User Management',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: canManageRoles
                      ? () => _showInviteDialog(context, ref)
                      : null,
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Create User'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Users',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No users found.')),
            )
          else
            ...users.map((u) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _roleBadge(u.role),
                          const SizedBox(width: 8),
                          Icon(
                            u.isActive
                                ? Icons.check_circle
                                : Icons.cancel_outlined,
                            color: u.isActive
                                ? AppColors.success
                                : AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit user',
                            onPressed: _canEditTarget(
                              canManageRoles: canManageRoles,
                              actorId: currentUser?.uid,
                              actorRole: actorRole,
                              target: u,
                            )
                                ? () => _showEditDialog(context, ref, u)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Delete user',
                            color: AppColors.error,
                            onPressed: _canDeleteTarget(
                              canManageRoles: canManageRoles,
                              actorId: currentUser?.uid,
                              actorRole: actorRole,
                              target: u,
                            )
                                ? () => _confirmDelete(context, ref, u)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Text('Roles & Permissions',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showRoleInfoDialog(context),
                  icon: const Icon(Icons.info_outline, size: 14),
                  label: const Text('Role Info'),
                ),
              ],
            ),
          ),
          ...roles.map((r) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.color.withOpacity(0.15),
                      child:
                          Icon(Icons.shield_outlined, color: r.color, size: 20),
                    ),
                    title: Text(r.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(r.description),
                    trailing: Text(
                      '${users.where((u) => u.role == r.value).length} users',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    const colors = {
      'owner': AppColors.cardRed,
      'admin': AppColors.cardOrange,
      'manager': AppColors.cardGreen,
      'cashier': AppColors.cardBlue,
    };
    final color = colors[role] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final actorRole = ref.read(authProvider)?.role.toLowerCase() ?? '';
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'cashier';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create User Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Minimum 6 characters',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roleMenuItemsForInvite(actorRole),
                onChanged: (v) => setLocal(() => selectedRole = v ?? 'cashier'),
              ),
              const SizedBox(height: 8),
              const Text(
                'This creates login credentials instantly for this business user.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final password = passCtrl.text.trim();
                if (email.isEmpty || password.length < 6) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(businessUsersProvider.notifier).inviteUser(
                        email: email,
                        name: nameCtrl.text.trim(),
                        role: selectedRole,
                        password: password,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('$email created as $selectedRole.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User creation failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    ).then((_) {
      emailCtrl.dispose();
      nameCtrl.dispose();
      passCtrl.dispose();
    });
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, BusinessUser user) {
    final actor = ref.read(authProvider);
    final actorRole = actor?.role.toLowerCase() ?? '';
    final roleItems = _roleMenuItemsForEdit(actorRole, user.role);
    if (roleItems.isEmpty) return;

    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: roleItems,
                onChanged: (v) => setLocal(() => selectedRole = v ?? user.role),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(businessUsersProvider.notifier).updateUser(
                        user.copyWith(role: selectedRole, isActive: isActive),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Role Permissions'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoleRow('Owner', 'Full access + license & business management'),
            SizedBox(height: 8),
            _RoleRow('Admin', 'All modules except license management'),
            SizedBox(height: 8),
            _RoleRow('Manager', 'Products, reports, expenses, contacts'),
            SizedBox(height: 8),
            _RoleRow('Cashier', 'POS and daily sales only'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, BusinessUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete ${user.name} (${user.email}) from this business?\n\n'
          'They will lose access to this business immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(businessUsersProvider.notifier).deleteUser(user);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} deleted.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  bool _canEditTarget({
    required bool canManageRoles,
    required String? actorId,
    required String actorRole,
    required BusinessUser target,
  }) {
    if (!canManageRoles) return false;
    if (actorId == null) return false;
    if (!(actorRole == 'owner' || actorRole == 'admin')) return false;
    if (target.id == actorId) return false; // self-role immutable
    if (target.role == 'owner') return false; // owner role immutable
    return true;
  }

  bool _canDeleteTarget({
    required bool canManageRoles,
    required String? actorId,
    required String actorRole,
    required BusinessUser target,
  }) {
    if (!canManageRoles) return false;
    if (actorId == null) return false;
    if (!(actorRole == 'owner' || actorRole == 'admin')) return false;
    if (target.id == actorId) return false;
    if (target.role == 'owner') return false;
    if (actorRole == 'admin' && target.role == 'admin') return false;
    return true;
  }

  List<DropdownMenuItem<String>> _roleMenuItemsForInvite(String actorRole) {
    final roles = actorRole == 'owner'
        ? const ['owner', 'admin', 'manager', 'cashier']
        : actorRole == 'admin'
            ? const ['admin', 'manager', 'cashier']
            : const <String>[];
    return roles
        .map((r) => DropdownMenuItem(value: r, child: Text(_prettyRole(r))))
        .toList();
  }

  List<DropdownMenuItem<String>> _roleMenuItemsForEdit(
      String actorRole, String targetRole) {
    if (targetRole == 'owner') return const <DropdownMenuItem<String>>[];
    final roles = actorRole == 'owner'
        ? const ['admin', 'manager', 'cashier']
        : actorRole == 'admin'
            ? const ['admin', 'manager', 'cashier']
            : const <String>[];
    return roles
        .map((r) => DropdownMenuItem(value: r, child: Text(_prettyRole(r))))
        .toList();
  }

  String _prettyRole(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      default:
        return 'Cashier';
    }
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow(this.role, this.desc);
  final String role;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child:
              Text(role, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(desc,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _RoleData {
  const _RoleData(this.value, this.label, this.description, this.color);
  final String value;
  final String label;
  final String description;
  final Color color;
}
