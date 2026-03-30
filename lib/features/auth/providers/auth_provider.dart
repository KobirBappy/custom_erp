import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/app_user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>(
  (ref) => AuthNotifier(),
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider) != null,
);

final currentBusinessIdProvider = Provider<String?>(
  (ref) => ref.watch(authProvider)?.currentBusinessId,
);

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null) {
    if (AppConstants.demoMode) {
      state = const AppUser(
        uid: AppConstants.demoUserId,
        email: 'admin@demo.com',
        displayName: 'Hafizur Rahman',
        role: 'admin',
        businessIds: [AppConstants.demoBusinessId],
        currentBusinessId: AppConstants.demoBusinessId,
      );
      return;
    }

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        state = null;
        return;
      }

      final profile = await _buildAppUser(user);
      state = profile;
    });
  }

  StreamSubscription<User?>? _sub;
  static const _uuid = Uuid();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    if (AppConstants.demoMode) {
      final trimmed = email.trim().toLowerCase();
      final isSuperAdmin = AppConstants.superAdminEmails
          .map((e) => e.trim().toLowerCase())
          .contains(trimmed);
      state = AppUser(
        uid: isSuperAdmin ? 'demo_superadmin_001' : AppConstants.demoUserId,
        email: email.trim(),
        displayName: email.split('@').first,
        role: isSuperAdmin ? 'super_admin' : 'owner',
        businessIds:
            isSuperAdmin ? const [] : const [AppConstants.demoBusinessId],
        currentBusinessId: isSuperAdmin ? null : AppConstants.demoBusinessId,
      );
      return true;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    if (AppConstants.demoMode) {
      state = null;
      return;
    }

    await FirebaseAuth.instance.signOut();
    state = null;
  }

  Future<void> switchBusiness(String businessId) async {
    if (state == null) return;

    final next = state!.copyWith(currentBusinessId: businessId);
    state = next;

    if (AppConstants.demoMode) return;

    // Optional app-user profile persistence (if this document exists).
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final appUserRef =
        FirebaseFirestore.instance.collection('appUsers').doc(uid);
    try {
      await appUserRef.set(
        <String, dynamic>{'currentBusinessId': businessId},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal: business switching still works in-memory.
    }
  }

  Future<bool> registerBusinessOwner({
    required String fullName,
    required String email,
    required String password,
    required String businessName,
    String businessPhone = '',
    String businessEmail = '',
    String businessAddress = '',
  }) async {
    if (AppConstants.demoMode) {
      state = AppUser(
        uid: AppConstants.demoUserId,
        email: email.trim(),
        displayName: fullName,
        role: 'owner',
        businessIds: const [AppConstants.demoBusinessId],
        currentBusinessId: AppConstants.demoBusinessId,
      );
      return true;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return false;

      await user.updateDisplayName(fullName);

      final businessId = _uuid.v4();
      final locationId = _uuid.v4();
      final now = DateTime.now();

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final businessRef = db.collection('businesses').doc(businessId);
      batch.set(
          businessRef,
          <String, dynamic>{
            'name': businessName,
            'phone': businessPhone.trim(),
            'email': businessEmail.trim().isEmpty
                ? email.trim()
                : businessEmail.trim(),
            'address': businessAddress.trim(),
            'ownerId': user.uid,
            'currencyCode': AppConstants.defaultCurrencyCode,
            'currencySymbol': AppConstants.defaultCurrencySymbol,
            'timeZone': 'Asia/Dhaka',
            'onboardingStatus': 'pending_approval',
            'onboardingRequestedAt': Timestamp.fromDate(now),
            'licenseActive': false,
            'licensePaymentStatus': 'unpaid',
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          },
          SetOptions(merge: true));

      batch.set(
        businessRef.collection('locations').doc(locationId),
        <String, dynamic>{
          'businessId': businessId,
          'name': 'Main Store',
          'type': 'storefront',
          'city': '',
          'invoicePrefix': 'INV',
          'isActive': true,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      batch.set(
        businessRef.collection('users').doc(user.uid),
        <String, dynamic>{
          'name': fullName,
          'email': email,
          'role': 'owner',
          'isActive': true,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      batch.set(
        db.collection('appUsers').doc(user.uid),
        <String, dynamic>{
          'email': email,
          'displayName': fullName,
          'role': 'owner',
          'businessIds': <String>[businessId],
          'currentBusinessId': businessId,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AppUser> _buildAppUser(User fbUser) async {
    final idToken = await fbUser.getIdTokenResult(true);
    final claims = idToken.claims ?? const <String, dynamic>{};

    final tokenBusinessIds = _readBusinessIds(claims);
    final tokenRoles = _readRoles(claims);

    final appUserDoc = await FirebaseFirestore.instance
        .collection('appUsers')
        .doc(fbUser.uid)
        .get();

    final appUserData = appUserDoc.data() ?? const <String, dynamic>{};

    final docBusinessIds =
        List<String>.from(appUserData['businessIds'] as List? ?? const []);
    final mergedBusinessIds =
        <String>{...tokenBusinessIds, ...docBusinessIds}.toList();

    String resolvedBusinessId = (appUserData['currentBusinessId'] as String?) ??
        (claims['currentBusinessId'] as String?) ??
        (mergedBusinessIds.isNotEmpty ? mergedBusinessIds.first : '');

    if (resolvedBusinessId.isEmpty && mergedBusinessIds.isNotEmpty) {
      resolvedBusinessId = mergedBusinessIds.first;
    }

    String? businessRole;
    if (resolvedBusinessId.isNotEmpty) {
      try {
        final businessUserDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(resolvedBusinessId)
            .collection('users')
            .doc(fbUser.uid)
            .get();
        businessRole = businessUserDoc.data()?['role'] as String?;
      } catch (_) {
        businessRole = null;
      }
    }

    final appUserRolesMap = (appUserData['roles'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const <String, String>{};
    final appRoleForBusiness =
        resolvedBusinessId.isEmpty ? null : appUserRolesMap[resolvedBusinessId];

    final role = businessRole ??
        appRoleForBusiness ??
        (appUserData['role'] as String?) ??
        tokenRoles[resolvedBusinessId] ??
        (claims['role'] as String?) ??
        'cashier';

    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName:
          fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
      photoUrl: fbUser.photoURL,
      role: role,
      businessIds: mergedBusinessIds,
      currentBusinessId: resolvedBusinessId.isEmpty ? null : resolvedBusinessId,
    );
  }

  List<String> _readBusinessIds(Map<String, dynamic> claims) {
    final raw = claims['businessIds'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  Map<String, String> _readRoles(Map<String, dynamic> claims) {
    final raw = claims['roles'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return const <String, String>{};
  }
}
