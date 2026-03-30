import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class SuperAdminBusinessItem {
  const SuperAdminBusinessItem({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.onboardingStatus,
    required this.licenseActive,
    required this.licensePaymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String onboardingStatus;
  final bool licenseActive;
  final String licensePaymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get pendingApproval => onboardingStatus == 'pending_approval';

  factory SuperAdminBusinessItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return SuperAdminBusinessItem(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Business',
      ownerId: map['ownerId'] as String? ?? '',
      onboardingStatus:
          map['onboardingStatus'] as String? ?? 'pending_approval',
      licenseActive: map['licenseActive'] as bool? ?? false,
      licensePaymentStatus: map['licensePaymentStatus'] as String? ?? 'unpaid',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}

class SuperAdminPaymentRequestItem {
  const SuperAdminPaymentRequestItem({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessPhone,
    required this.businessEmail,
    required this.businessAddress,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.durationDays,
    required this.paymentMethod,
    required this.transactionRef,
    required this.status,
    required this.requestedBy,
    required this.requestedByName,
    this.requestedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.note,
    this.paymentRequestPath = '',
    this.businessDocPath = '',
  });

  final String id;
  final String businessId;
  final String businessName;
  final String businessPhone;
  final String businessEmail;
  final String businessAddress;
  final String planId;
  final String planName;
  final double amount;
  final int durationDays;
  final String paymentMethod;
  final String transactionRef;
  final String status;
  final String requestedBy;
  final String requestedByName;
  final DateTime? requestedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? note;
  final String paymentRequestPath;
  final String businessDocPath;

  bool get isPending => status.trim().toLowerCase() == 'pending';

  factory SuperAdminPaymentRequestItem.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return SuperAdminPaymentRequestItem(
      id: id,
      businessId: map['businessId'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      businessPhone: map['businessPhone'] as String? ?? '',
      businessEmail: map['businessEmail'] as String? ?? '',
      businessAddress: map['businessAddress'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      planName: map['planName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      transactionRef: map['transactionRef'] as String? ?? '',
      status: (map['status'] as String? ?? 'pending').trim().toLowerCase(),
      requestedBy: map['requestedBy'] as String? ?? '',
      requestedByName: map['requestedByName'] as String? ?? '',
      requestedAt: parseDate(map['requestedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedByName: map['reviewedByName'] as String?,
      reviewedAt: parseDate(map['reviewedAt']),
      note: map['note'] as String?,
      paymentRequestPath: map['paymentRequestPath'] as String? ?? '',
      businessDocPath: map['businessDocPath'] as String? ?? '',
    );
  }

  factory SuperAdminPaymentRequestItem.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final parentBusinessId = doc.reference.parent.parent?.id ?? '';
    final parentBusinessPath = doc.reference.parent.parent?.path ?? '';

    final normalized = <String, dynamic>{
      ...data,
      'businessId': (data['businessId'] as String?)?.trim().isNotEmpty == true
          ? data['businessId']
          : parentBusinessId,
      'businessName': data['businessName'] as String? ?? '',
      'businessPhone': data['businessPhone'] as String? ?? '',
      'businessEmail': data['businessEmail'] as String? ?? '',
      'businessAddress': data['businessAddress'] as String? ?? '',
      'paymentRequestPath': doc.reference.path,
      'businessDocPath': parentBusinessPath,
    };

    return SuperAdminPaymentRequestItem.fromMap(doc.id, normalized);
  }
}

final isSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider);
  if (user?.role.trim().toLowerCase() == 'super_admin') return true;

  final email = user?.email.trim().toLowerCase();
  if (email == null || email.isEmpty) return false;

  return AppConstants.superAdminEmails
      .map((e) => e.trim().toLowerCase())
      .contains(email);
});

final superAdminBusinessesProvider =
    StreamProvider<List<SuperAdminBusinessItem>>((ref) {
  final isSuperAdmin = ref.watch(isSuperAdminProvider);
  if (AppConstants.demoMode || !isSuperAdmin) {
    return Stream<List<SuperAdminBusinessItem>>.value(
      const <SuperAdminBusinessItem>[],
    );
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => SuperAdminBusinessItem.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

final superAdminPaymentRequestsProvider =
    StreamProvider<List<SuperAdminPaymentRequestItem>>((ref) {
  final isSuperAdmin = ref.watch(isSuperAdminProvider);
  if (AppConstants.demoMode || !isSuperAdmin) {
    return Stream<List<SuperAdminPaymentRequestItem>>.value(
      const <SuperAdminPaymentRequestItem>[],
    );
  }

  return FirebaseFirestore.instance
      .collectionGroup('paymentRequests')
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(SuperAdminPaymentRequestItem.fromSnapshot).toList(),
      );
});

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService(ref);
});

class SuperAdminService {
  SuperAdminService(this.ref);
  final Ref ref;

  Future<void> approveBusiness({required String businessId}) async {
    final user = ref.read(authProvider);
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .set({
      'onboardingStatus': 'approved',
      'onboardingReviewedBy': user?.uid ?? '',
      'onboardingReviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> rejectBusiness({
    required String businessId,
    required String note,
  }) async {
    final user = ref.read(authProvider);
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .set({
      'onboardingStatus': 'rejected',
      'onboardingReviewNote': note,
      'onboardingReviewedBy': user?.uid ?? '',
      'onboardingReviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approvePaymentRequest({
    required SuperAdminPaymentRequestItem request,
  }) async {
    if (request.businessDocPath.isEmpty && request.businessId.trim().isEmpty) {
      throw Exception(
        'Payment request is missing business reference. Please refresh and try again.',
      );
    }

    final user = ref.read(authProvider);
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: request.durationDays));

    final db = FirebaseFirestore.instance;
    final businessRef = request.businessDocPath.isNotEmpty
        ? db.doc(request.businessDocPath)
        : db.collection('businesses').doc(request.businessId);
    final paymentRef = request.paymentRequestPath.isNotEmpty
        ? db.doc(request.paymentRequestPath)
        : businessRef.collection('paymentRequests').doc(request.id);

    final batch = db.batch();

    batch.set(
        businessRef,
        {
          'onboardingStatus': 'approved',
          'onboardingReviewedBy': user?.uid ?? '',
          'onboardingReviewedAt': FieldValue.serverTimestamp(),
          'licenseActive': true,
          'licensePlanId': request.planId,
          'licensePlanName': request.planName,
          'licensePaymentStatus': 'paid',
          'licensePaymentMethod': request.paymentMethod,
          'licenseTransactionRef': request.transactionRef,
          'licenseAmount': request.amount,
          'licenseCurrency': AppConstants.defaultCurrencyCode,
          'licenseActivatedAt': Timestamp.fromDate(now),
          'licenseExpiresAt': Timestamp.fromDate(expiresAt),
          'licenseUpdatedBy': user?.uid ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    batch.set(
        paymentRef,
        {
          'status': 'approved',
          'reviewedBy': user?.uid ?? '',
          'reviewedByName': user?.displayName ?? user?.email ?? 'Super Admin',
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> rejectPaymentRequest({
    required String businessId,
    required String requestId,
    required String note,
    String paymentRequestPath = '',
    String businessDocPath = '',
  }) async {
    final user = ref.read(authProvider);
    final db = FirebaseFirestore.instance;

    final batch = db.batch();
    final businessRef = businessDocPath.isNotEmpty
        ? db.doc(businessDocPath)
        : db.collection('businesses').doc(businessId);
    final paymentRef = paymentRequestPath.isNotEmpty
        ? db.doc(paymentRequestPath)
        : businessRef.collection('paymentRequests').doc(requestId);

    batch.set(
        paymentRef,
        {
          'status': 'rejected',
          'note': note,
          'reviewedBy': user?.uid ?? '',
          'reviewedByName': user?.displayName ?? user?.email ?? 'Super Admin',
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    batch.set(
        businessRef,
        {
          'licenseActive': false,
          'licensePaymentStatus': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    await batch.commit();
  }
}
