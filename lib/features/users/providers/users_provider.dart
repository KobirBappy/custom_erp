import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../firebase_options.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/business_user.dart';

final businessUsersProvider =
    StateNotifierProvider<BusinessUsersNotifier, List<BusinessUser>>(
  (ref) => BusinessUsersNotifier(ref),
);

class BusinessUsersNotifier extends StateNotifier<List<BusinessUser>> {
  BusinessUsersNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoUsers : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(
        currentBusinessIdProvider,
        (_, next) => _bind(next),
        fireImmediately: true,
      );
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const _demoUsers = [
    BusinessUser(
      id: AppConstants.demoUserId,
      businessId: AppConstants.demoBusinessId,
      name: 'Hafizur Rahman',
      email: 'admin@demo.com',
      role: 'owner',
      isActive: true,
    ),
    BusinessUser(
      id: 'demo_user_002',
      businessId: AppConstants.demoBusinessId,
      name: 'Kashem Ali',
      email: 'kashem@demo.com',
      role: 'cashier',
      isActive: true,
    ),
    BusinessUser(
      id: 'demo_user_003',
      businessId: AppConstants.demoBusinessId,
      name: 'Rina Begum',
      email: 'rina@demo.com',
      role: 'cashier',
      isActive: false,
    ),
    BusinessUser(
      id: 'demo_user_004',
      businessId: AppConstants.demoBusinessId,
      name: 'Mahmud Hasan',
      email: 'mahmud@demo.com',
      role: 'manager',
      isActive: true,
    ),
  ];

  @override
  void dispose() {
    _sub?.cancel();
    _bizSub?.close();
    super.dispose();
  }

  void _bind(String? businessId) {
    _sub?.cancel();
    if (businessId == null || businessId.isEmpty) {
      state = const [];
      return;
    }
    _sub = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('users')
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => BusinessUser.fromMap(d.data(), d.id, businessId))
          .toList();
    });
  }

  Future<void> updateUser(BusinessUser updated) async {
    final actor = ref.read(authProvider);
    if (actor == null) {
      throw Exception('Not authenticated.');
    }
    final actorRole = actor.role.toLowerCase();
    final isPrivileged = actorRole == 'owner' || actorRole == 'admin';
    if (!isPrivileged) {
      throw Exception('Only owner/admin can change roles.');
    }

    final previous = state.where((u) => u.id == updated.id);
    if (previous.isEmpty) {
      throw Exception('User not found.');
    }
    final prevUser = previous.first;

    if (actor.uid == updated.id && prevUser.role != updated.role) {
      throw Exception('You cannot change your own role.');
    }
    if (prevUser.role == 'owner' && prevUser.role != updated.role) {
      throw Exception('Owner role cannot be changed.');
    }
    if (actorRole == 'admin' && updated.role == 'owner') {
      throw Exception('Only owner can assign owner role.');
    }

    if (AppConstants.demoMode) {
      state = [
        for (final u in state)
          if (u.id == updated.id) updated else u
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('users')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Keep appUsers role in sync so login role resolution reflects updates.
    final appUsers = FirebaseFirestore.instance.collection('appUsers');
    DocumentReference<Map<String, dynamic>> targetRef =
        appUsers.doc(updated.id);
    bool canWriteById = false;
    try {
      final byId = await targetRef.get();
      canWriteById = byId.exists;
    } catch (_) {
      canWriteById = false;
    }

    if (!canWriteById) {
      try {
        final byEmail = await appUsers
            .where('email', isEqualTo: updated.email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          targetRef = byEmail.docs.first.reference;
          canWriteById = true;
        }
      } catch (_) {
        canWriteById = false;
      }
    }

    if (canWriteById) {
      await targetRef.set({
        'role': updated.role,
        'roles': {
          businessId: updated.role,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteUser(BusinessUser target) async {
    final actor = ref.read(authProvider);
    if (actor == null) {
      throw Exception('Not authenticated.');
    }
    final actorRole = actor.role.toLowerCase();
    final isPrivileged = actorRole == 'owner' || actorRole == 'admin';
    if (!isPrivileged) {
      throw Exception('Only owner/admin can delete users.');
    }

    if (target.id == actor.uid) {
      throw Exception('You cannot delete your own account.');
    }
    if (target.role == 'owner') {
      throw Exception('Owner user cannot be deleted.');
    }
    if (actorRole == 'admin' && target.role == 'admin') {
      throw Exception('Admin cannot delete another admin.');
    }

    if (AppConstants.demoMode) {
      state = [
        for (final u in state)
          if (u.id != target.id) u
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    final db = FirebaseFirestore.instance;
    await db
        .collection('businesses')
        .doc(businessId)
        .collection('users')
        .doc(target.id)
        .delete();

    final appUsers = db.collection('appUsers');
    DocumentReference<Map<String, dynamic>> targetRef = appUsers.doc(target.id);
    bool existsById = false;
    try {
      final byId = await targetRef.get();
      existsById = byId.exists;
    } catch (_) {
      existsById = false;
    }

    if (!existsById) {
      try {
        final byEmail = await appUsers
            .where('email', isEqualTo: target.email.toLowerCase())
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          targetRef = byEmail.docs.first.reference;
          existsById = true;
        }
      } catch (_) {
        existsById = false;
      }
    }

    if (existsById) {
      final snap = await targetRef.get();
      final currentBusinessId =
          (snap.data()?['currentBusinessId'] as String?) ?? '';
      final update = <String, dynamic>{
        'businessIds': FieldValue.arrayRemove(<String>[businessId]),
        'roles.$businessId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (currentBusinessId == businessId) {
        update['currentBusinessId'] = '';
      }
      await targetRef.set(update, SetOptions(merge: true));
    }
  }

  Future<void> inviteUser({
    required String email,
    required String name,
    required String role,
    String? password,
  }) async {
    final actor = ref.read(authProvider);
    if (actor == null) {
      throw Exception('Not authenticated.');
    }
    final actorRole = actor.role.toLowerCase();
    final isPrivileged = actorRole == 'owner' || actorRole == 'admin';
    if (!isPrivileged) {
      throw Exception('Only owner/admin can invite users.');
    }
    if (actorRole == 'admin' && role == 'owner') {
      throw Exception('Only owner can invite another owner.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }
    if (password == null || password.trim().length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    if (AppConstants.demoMode) {
      state = [
        ...state,
        BusinessUser(
          id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
          businessId: AppConstants.demoBusinessId,
          name: trimmedName.isEmpty
              ? normalizedEmail.split('@').first
              : trimmedName,
          email: normalizedEmail,
          role: role,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    final userName =
        trimmedName.isEmpty ? normalizedEmail.split('@').first : trimmedName;
    final db = FirebaseFirestore.instance;

    final existing = await db
        .collection('businesses')
        .doc(businessId)
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('User already exists in this business.');
    }

    FirebaseApp? secondaryApp;
    FirebaseAuth? secondaryAuth;
    User? createdUser;
    try {
      final appName = 'user_creator_${DateTime.now().microsecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      createdUser = cred.user;
      if (createdUser == null) {
        throw Exception('Failed to create auth user.');
      }
      await createdUser.updateDisplayName(userName);

      await db
          .collection('businesses')
          .doc(businessId)
          .collection('users')
          .doc(createdUser.uid)
          .set({
        'name': userName,
        'email': normalizedEmail,
        'role': role,
        'isActive': true,
        'inviteStatus': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instanceFor(app: secondaryApp)
          .collection('appUsers')
          .doc(createdUser.uid)
          .set({
        'email': normalizedEmail,
        'displayName': userName,
        'role': role,
        'businessIds': <String>[businessId],
        'roles': {businessId: role},
        'currentBusinessId': businessId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
            'This email already has an account. Use another email.');
      }
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Use at least 6 characters.');
      }
      throw Exception(e.message ?? 'Failed to create user account.');
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Best-effort rollback only.
        }
      }
      rethrow;
    } finally {
      if (secondaryAuth != null) {
        try {
          await secondaryAuth.signOut();
        } catch (_) {
          // Ignore cleanup errors.
        }
      }
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {
          // Ignore cleanup errors.
        }
      }
    }
  }
}
