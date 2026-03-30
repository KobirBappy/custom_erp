import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../models/purchase.dart';

const _uuid = Uuid();

final purchasesProvider =
    StateNotifierProvider<PurchasesNotifier, List<Purchase>>(
  (ref) => PurchasesNotifier(ref),
);

class PurchasesNotifier extends StateNotifier<List<Purchase>> {
  PurchasesNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoPurchases : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static final _demoPurchases = [
    Purchase(
      id: 'pur1',
      businessId: AppConstants.demoBusinessId,
      locationId: AppConstants.demoLocationId,
      supplierId: 'c1',
      supplierName: 'Ahmed Traders',
      purchaseDate: DateTime(2026, 3, 1),
      referenceNo: 'PO-2026-001',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.paid,
      lines: [
        const PurchaseLine(
            productId: 'p1',
            productName: 'PVC Pipe 1"',
            sku: 'PVC-001',
            qty: 100,
            unitCost: 80),
        const PurchaseLine(
            productId: 'p2',
            productName: 'PVC Pipe 2"',
            sku: 'PVC-002',
            qty: 50,
            unitCost: 150),
      ],
      paidAmount: 15500,
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
        .collection('purchases')
        .snapshots()
        .listen((snap) {
      state = snap.docs.map((d) => Purchase.fromMap(d.data(), d.id)).toList();
    });
  }

  Future<void> add(Purchase purchase) async {
    if (AppConstants.demoMode) {
      final newPurchase = Purchase(
        id: _uuid.v4(),
        businessId: purchase.businessId,
        locationId: purchase.locationId,
        supplierId: purchase.supplierId,
        supplierName: purchase.supplierName,
        purchaseDate: purchase.purchaseDate,
        referenceNo: purchase.referenceNo,
        status: purchase.status,
        paymentStatus: purchase.paymentStatus,
        lines: purchase.lines,
        discountAmount: purchase.discountAmount,
        taxAmount: purchase.taxAmount,
        shippingCost: purchase.shippingCost,
        paidAmount: purchase.paidAmount,
        notes: purchase.notes,
        dueDate: purchase.dueDate,
        createdAt: DateTime.now(),
      );
      state = [...state, newPurchase];
      return;
    }

    final businessId =
        ref.read(currentBusinessIdProvider) ?? purchase.businessId;
    if (businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('purchases')
        .doc(_uuid.v4())
        .set({
      ...purchase.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _applyStockDeltaForAdd(purchase);
  }

  Future<void> update(Purchase updated) async {
    Purchase? previous;
    for (final p in state) {
      if (p.id == updated.id) {
        previous = p;
        break;
      }
    }

    if (AppConstants.demoMode) {
      state = [
        for (final p in state)
          if (p.id == updated.id) updated else p
      ];
      await _applyStockDeltaForUpdate(
        previous: previous,
        updated: updated,
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.businessId)
        .collection('purchases')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _applyStockDeltaForUpdate(
      previous: previous,
      updated: updated,
    );
  }

  Future<void> delete(String id) async {
    Purchase? previous;
    for (final p in state) {
      if (p.id == id) {
        previous = p;
        break;
      }
    }

    if (AppConstants.demoMode) {
      state = state.where((p) => p.id != id).toList();
      await _applyStockRollbackForDelete(previous);
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('purchases')
        .doc(id)
        .delete();

    await _applyStockRollbackForDelete(previous);
  }

  Future<void> markPaid(String id, double amount) async {
    final existing = state.where((p) => p.id == id);
    if (existing.isEmpty) return;
    final p = existing.first;

    final updated = p.copyWith(
      paidAmount: p.paidAmount + amount,
      paymentStatus: (p.paidAmount + amount) >= p.grandTotal
          ? PaymentStatus.paid
          : PaymentStatus.partial,
    );
    await update(updated);
  }

  double get totalDue => state.fold(0.0, (acc, p) => acc + p.dueAmount);
  double get totalPurchases => state.fold(0.0, (acc, p) => acc + p.grandTotal);

  bool _affectsStock(PurchaseStatus status) =>
      status == PurchaseStatus.received;

  Future<void> _applyStockDeltaForAdd(Purchase purchase) async {
    if (!_affectsStock(purchase.status)) return;
    for (final line in purchase.lines) {
      await ref.read(productsProvider.notifier).adjustStock(
            line.productId,
            line.qty,
            locationId: purchase.locationId,
          );
    }
  }

  Future<void> _applyStockRollbackForDelete(Purchase? previous) async {
    if (previous == null || !_affectsStock(previous.status)) return;
    for (final line in previous.lines) {
      await ref.read(productsProvider.notifier).adjustStock(
            line.productId,
            -line.qty,
            locationId: previous.locationId,
          );
    }
  }

  Future<void> _applyStockDeltaForUpdate({
    required Purchase? previous,
    required Purchase updated,
  }) async {
    final oldMap = _effectiveQtyMap(previous);
    final newMap = _effectiveQtyMap(updated);
    final allKeys = <String>{...oldMap.keys, ...newMap.keys};
    for (final key in allKeys) {
      final oldQty = oldMap[key] ?? 0.0;
      final newQty = newMap[key] ?? 0.0;
      final delta = newQty - oldQty;
      if (delta == 0) continue;

      final parts = key.split('|');
      if (parts.length != 2) continue;
      final productId = parts[0];
      final locationId = parts[1];
      await ref.read(productsProvider.notifier).adjustStock(
            productId,
            delta,
            locationId: locationId,
          );
    }
  }

  Map<String, double> _effectiveQtyMap(Purchase? purchase) {
    if (purchase == null || !_affectsStock(purchase.status)) {
      return const <String, double>{};
    }
    final map = <String, double>{};
    for (final line in purchase.lines) {
      final key = '${line.productId}|${purchase.locationId}';
      map[key] = (map[key] ?? 0) + line.qty;
    }
    return map;
  }
}
