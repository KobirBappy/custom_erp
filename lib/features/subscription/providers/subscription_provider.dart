import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_provider.dart';
import '../../super_admin/providers/super_admin_provider.dart';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.features,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final int sortOrder;

  factory SubscriptionPlan.fromMap(String id, Map<String, dynamic> map) {
    final rawFeatures = map['features'];
    final features = rawFeatures is List
        ? rawFeatures
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];

    return SubscriptionPlan(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Plan',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 30,
      features: features,
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'features': features,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BusinessLicense {
  const BusinessLicense({
    this.isActive = false,
    this.planId = '',
    this.planName = '',
    this.paymentStatus = 'unpaid',
    this.expiresAt,
  });

  final bool isActive;
  final String planId;
  final String planName;
  final String paymentStatus;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get canUseSellPos => isActive && !isExpired;

  factory BusinessLicense.fromBusinessMap(Map<String, dynamic> map) {
    final expiresRaw = map['licenseExpiresAt'];
    DateTime? expires;
    if (expiresRaw is Timestamp) {
      expires = expiresRaw.toDate();
    } else if (expiresRaw is String) {
      expires = DateTime.tryParse(expiresRaw);
    }

    return BusinessLicense(
      isActive: map['licenseActive'] as bool? ?? false,
      planId: map['licensePlanId'] as String? ?? '',
      planName: map['licensePlanName'] as String? ?? '',
      paymentStatus: map['licensePaymentStatus'] as String? ?? 'unpaid',
      expiresAt: expires,
    );
  }
}

class PaymentRequestItem {
  const PaymentRequestItem({
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

  bool get isPending => status.trim().toLowerCase() == 'pending';

  factory PaymentRequestItem.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return PaymentRequestItem(
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
    );
  }
}

const availablePlans = <SubscriptionPlan>[
  SubscriptionPlan(
    id: 'starter_monthly',
    name: 'Starter Monthly',
    price: 19,
    durationDays: 30,
    features: <String>[
      'POS + Sell module access',
      'Products, contacts, purchases, expenses',
      'Single business owner account',
    ],
    sortOrder: 1,
  ),
  SubscriptionPlan(
    id: 'growth_quarterly',
    name: 'Growth Quarterly',
    price: 49,
    durationDays: 90,
    features: <String>[
      'POS + Sell module access',
      'Priority support',
      'Multi-location ready',
    ],
    sortOrder: 2,
  ),
  SubscriptionPlan(
    id: 'pro_yearly',
    name: 'Pro Yearly',
    price: 149,
    durationDays: 365,
    features: <String>[
      'POS + Sell module access',
      'All reporting and analytics',
      'Best value annual plan',
    ],
    sortOrder: 3,
  ),
];

final subscriptionPlansProvider = StreamProvider<List<SubscriptionPlan>>((ref) {
  if (AppConstants.demoMode) {
    return Stream<List<SubscriptionPlan>>.value(availablePlans);
  }

  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) {
    return Stream<List<SubscriptionPlan>>.value(availablePlans);
  }

  final controller = StreamController<List<SubscriptionPlan>>();
  final sub = FirebaseFirestore.instance
      .collection('subscriptionPlans')
      .orderBy('sortOrder')
      .snapshots()
      .listen(
    (snap) {
      final plans = snap.docs
          .map((doc) => SubscriptionPlan.fromMap(doc.id, doc.data()))
          .where((p) => p.isActive)
          .toList();
      controller.add(plans.isEmpty ? availablePlans : plans);
    },
    onError: (error, stackTrace) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        controller.add(availablePlans);
        return;
      }
      controller.addError(error, stackTrace);
    },
  );

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

final onboardingStatusProvider = StreamProvider<String>((ref) {
  if (AppConstants.demoMode) {
    return Stream<String>.value('approved');
  }

  final business = ref.watch(currentBusinessProvider);
  if (business == null) {
    return Stream<String>.value('no_business');
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(business.id)
      .snapshots()
      .map((doc) =>
          doc.data()?['onboardingStatus'] as String? ?? 'pending_approval');
});

final businessLicenseProvider = StreamProvider<BusinessLicense>((ref) {
  if (AppConstants.demoMode) {
    return Stream<BusinessLicense>.value(const BusinessLicense(
      isActive: true,
      planId: 'demo',
      planName: 'Demo',
    ));
  }

  final business = ref.watch(currentBusinessProvider);
  if (business == null) {
    return Stream<BusinessLicense>.value(const BusinessLicense());
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(business.id)
      .snapshots()
      .map((doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return BusinessLicense.fromBusinessMap(map);
  });
});

final paymentRequestsProvider = StreamProvider<List<PaymentRequestItem>>((ref) {
  if (AppConstants.demoMode) {
    return Stream<List<PaymentRequestItem>>.value(const <PaymentRequestItem>[]);
  }

  final business = ref.watch(currentBusinessProvider);
  if (business == null) {
    return Stream<List<PaymentRequestItem>>.value(const <PaymentRequestItem>[]);
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(business.id)
      .collection('paymentRequests')
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => PaymentRequestItem.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

final latestPendingPaymentRequestProvider =
    Provider<PaymentRequestItem?>((ref) {
  final requests = ref.watch(paymentRequestsProvider).valueOrNull;
  if (requests == null || requests.isEmpty) return null;

  for (final req in requests) {
    if (req.isPending) return req;
  }

  return null;
});

final sellPosEnabledProvider = Provider<bool>((ref) {
  final licenseAsync = ref.watch(businessLicenseProvider);
  return licenseAsync.maybeWhen(
    data: (license) => license.canUseSellPos,
    orElse: () => false,
  );
});

final subscriptionProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref);
});

class SubscriptionService {
  SubscriptionService(this.ref);
  final Ref ref;

  static const Uuid _uuid = Uuid();

  Future<void> upsertSubscriptionPlan({
    String? id,
    required String name,
    required double price,
    required int durationDays,
    required List<String> features,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    final isSuperAdminUser = ref.read(isSuperAdminProvider);
    if (!isSuperAdminUser) {
      throw Exception('Only super admin can manage packages.');
    }

    final trimmedName = name.trim();
    final cleanedFeatures =
        features.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (trimmedName.isEmpty) {
      throw Exception('Plan name is required.');
    }
    if (price <= 0) {
      throw Exception('Plan price must be greater than zero.');
    }
    if (durationDays <= 0) {
      throw Exception('Duration must be greater than zero.');
    }

    final docId = (id == null || id.trim().isEmpty) ? _uuid.v4() : id.trim();
    final plan = SubscriptionPlan(
      id: docId,
      name: trimmedName,
      price: price,
      durationDays: durationDays,
      features: cleanedFeatures,
      isActive: isActive,
      sortOrder: sortOrder,
    );

    await FirebaseFirestore.instance
        .collection('subscriptionPlans')
        .doc(docId)
        .set({
      ...plan.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSubscriptionPlan(String id) async {
    final isSuperAdminUser = ref.read(isSuperAdminProvider);
    if (!isSuperAdminUser) {
      throw Exception('Only super admin can remove packages.');
    }

    await FirebaseFirestore.instance
        .collection('subscriptionPlans')
        .doc(id)
        .delete();
  }

  Future<void> submitPaymentRequest({
    required SubscriptionPlan plan,
    required String paymentMethod,
    required String transactionRef,
  }) async {
    final business = ref.read(currentBusinessProvider);
    final user = ref.read(authProvider);
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final requesterUid = (firebaseUid != null && firebaseUid.isNotEmpty)
        ? firebaseUid
        : user?.uid;

    if (business == null || requesterUid == null || requesterUid.isEmpty) {
      throw Exception('No active business/user found.');
    }

    final db = FirebaseFirestore.instance;
    final requestId = _uuid.v4();
    final normalizedMethod = paymentMethod.trim().toLowerCase();
    final normalizedTxRef = transactionRef.trim();

    // Only write to the paymentRequests subcollection.
    // The business document's licensePaymentStatus / licenseActive fields are
    // protected and must only be updated by a super admin (via approvePaymentRequest).
    // Attempting to write those fields from the client causes a permission denial.
    await db
        .collection('businesses')
        .doc(business.id)
        .collection('paymentRequests')
        .doc(requestId)
        .set({
      'businessId': business.id,
      'businessName': business.name,
      'businessPhone': business.phone,
      'businessEmail': business.email,
      'businessAddress': business.address,
      'planId': plan.id,
      'planName': plan.name,
      'amount': plan.price,
      'durationDays': plan.durationDays,
      'paymentMethod': normalizedMethod,
      'transactionRef': normalizedTxRef,
      'status': 'pending',
      'requestedBy': requesterUid,
      'requestedByName': user?.displayName ?? user?.email ?? 'Business Owner',
      'requestedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelPaymentRequest(String requestId) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) throw Exception('No active business found.');

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(business.id)
        .collection('paymentRequests')
        .doc(requestId)
        .update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // NOTE: deactivateForNonPayment writes protected license fields.
  // It must only be called from a super admin context or Cloud Function.
  // Calling it from a regular business owner session will be denied by Firestore rules.
  Future<void> deactivateForNonPayment() async {
    final isSuperAdminUser = ref.read(isSuperAdminProvider);
    if (!isSuperAdminUser) return; // guard: only super admin may call this

    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(business.id)
        .set({
      'licenseActive': false,
      'licensePaymentStatus': 'unpaid',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
