import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/return_entry.dart';

const _uuid = Uuid();

final saleReturnsProvider =
    StateNotifierProvider<SaleReturnsNotifier, List<ReturnEntry>>(
  (ref) => SaleReturnsNotifier(ref),
);

final purchaseReturnsProvider =
    StateNotifierProvider<PurchaseReturnsNotifier, List<ReturnEntry>>(
  (ref) => PurchaseReturnsNotifier(ref),
);

class SaleReturnsNotifier extends _BaseReturnNotifier {
  SaleReturnsNotifier(super.ref) : super(collectionName: 'saleReturns');
}

class PurchaseReturnsNotifier extends _BaseReturnNotifier {
  PurchaseReturnsNotifier(super.ref) : super(collectionName: 'purchaseReturns');
}

class _BaseReturnNotifier extends StateNotifier<List<ReturnEntry>> {
  _BaseReturnNotifier(
    this.ref, {
    required this.collectionName,
  }) : super(const []) {
    if (AppConstants.demoMode) return;
    _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
      _bind(next);
    }, fireImmediately: true);
  }

  final Ref ref;
  final String collectionName;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

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
        .collection(collectionName)
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((d) => ReturnEntry.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      state = list;
    });
  }

  Future<void> add(ReturnEntry entry) async {
    if (AppConstants.demoMode) {
      state = [
        ReturnEntry(
          id: _uuid.v4(),
          businessId: entry.businessId,
          locationId: entry.locationId,
          referenceId: entry.referenceId,
          referenceNo: entry.referenceNo,
          partyId: entry.partyId,
          partyName: entry.partyName,
          amount: entry.amount,
          paidAmount: entry.paidAmount,
          date: entry.date,
          reason: entry.reason,
          createdAt: DateTime.now(),
        ),
        ...state,
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider) ?? entry.businessId;
    if (businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection(collectionName)
        .doc(_uuid.v4())
        .set({
      ...entry.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(ReturnEntry entry) async {
    if (AppConstants.demoMode) {
      state = [
        for (final e in state)
          if (e.id == entry.id) entry else e,
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider) ?? entry.businessId;
    if (businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection(collectionName)
        .doc(entry.id)
        .set({
      ...entry.toMap(),
      'businessId': businessId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((e) => e.id != id).toList();
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection(collectionName)
        .doc(id)
        .delete();
  }
}
