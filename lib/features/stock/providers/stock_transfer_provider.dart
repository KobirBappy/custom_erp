import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/stock_transfer.dart';

const _uuid = Uuid();

final stockTransfersProvider =
    StateNotifierProvider<StockTransfersNotifier, List<StockTransfer>>(
  (ref) => StockTransfersNotifier(ref),
);

class StockTransfersNotifier extends StateNotifier<List<StockTransfer>> {
  StockTransfersNotifier(this.ref)
      : super(AppConstants.demoMode ? const [] : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
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
        .collection('stockTransfers')
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((d) => StockTransfer.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => b.transferDate.compareTo(a.transferDate));
      state = list;
    });
  }

  Future<void> add(StockTransfer transfer) async {
    if (AppConstants.demoMode) {
      state = [
        StockTransfer(
          id: _uuid.v4(),
          businessId: transfer.businessId,
          productId: transfer.productId,
          productName: transfer.productName,
          fromLocationId: transfer.fromLocationId,
          fromLocationName: transfer.fromLocationName,
          toLocationId: transfer.toLocationId,
          toLocationName: transfer.toLocationName,
          qty: transfer.qty,
          transferDate: transfer.transferDate,
          note: transfer.note,
          createdBy: transfer.createdBy,
          createdAt: DateTime.now(),
        ),
        ...state,
      ];
      return;
    }

    final businessId =
        ref.read(currentBusinessIdProvider) ?? transfer.businessId;
    if (businessId.isEmpty) {
      throw Exception('No active business selected.');
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('stockTransfers')
        .doc(_uuid.v4())
        .set({
      ...transfer.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
