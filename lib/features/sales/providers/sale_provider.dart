import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sale.dart';
import 'cart_provider.dart';

const _uuid = Uuid();

final salesProvider =
    StateNotifierProvider<SalesNotifier, List<Sale>>(
  (ref) => SalesNotifier(ref),
);

class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoSales : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static final _demoSales = [
    Sale(
      id: 's1', businessId: AppConstants.demoBusinessId,
      locationId: AppConstants.demoLocationId,
      saleDate: DateTime(2026, 3, 21),
      invoiceNo: 'BL0001-0001',
      customerName: 'Walk-In Customer',
      status: SaleStatus.final_, paymentStatus: PaymentStatus.paid,
      lines: [
        const SaleLine(productId: 'p1', productName: 'PVC Pipe 1"', sku: 'PVC-001', qty: 5, unitPrice: 120),
      ],
      paidAmount: 600,
    ),
  ];

  int _sequence = 4;

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
        .collection('sales')
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => Sale.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      state = list;
    });
  }

  Future<Sale> finalizeSale({
    required CartState cart,
    required String businessId,
    required String locationId,
    required String cashierId,
    required String locationPrefix,
    double transportCost = 0,
    double paidAmount = 0,
  }) async {
    final id = _uuid.v4();
    final invoiceNo =
        '${locationPrefix.isEmpty ? 'INV' : locationPrefix}-${_sequence.toString().padLeft(4, '0')}';
    _sequence++;

    final sale = Sale(
      id: id,
      businessId: businessId,
      locationId: locationId,
      saleDate: DateTime.now(),
      invoiceNo: invoiceNo,
      customerId: cart.customerId,
      customerName: cart.customerName,
      cashierId: cashierId,
      status: SaleStatus.final_,
      paymentStatus: paidAmount >= cart.grandTotal
          ? PaymentStatus.paid
          : paidAmount > 0
              ? PaymentStatus.partial
              : PaymentStatus.due,
      paymentMethod: cart.paymentMethod,
      lines: cart.toSaleLines(),
      discountAmount: cart.globalDiscount,
      taxAmount: cart.totalTax,
      transportCost: transportCost,
      paidAmount: paidAmount,
      notes: cart.notes,
      isSynced: false,
      createdAt: DateTime.now(),
    );

    if (AppConstants.demoMode) {
      state = [...state, sale];
      return sale;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .doc(id)
        .set({
      ...sale.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return sale;
  }

  Future<void> voidSale(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((s) => s.id != id).toList();
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .doc(id)
        .delete();
  }

  Future<void> markPaid(String id, double amount) async {
    final target = state.where((s) => s.id == id);
    if (target.isEmpty) return;

    final s = target.first;
    final updated = s.copyWith(
      paidAmount: s.paidAmount + amount,
      paymentStatus: (s.paidAmount + amount) >= s.grandTotal
          ? PaymentStatus.paid
          : PaymentStatus.partial,
    );

    if (AppConstants.demoMode) {
      state = [for (final it in state) if (it.id == id) updated else it];
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.businessId)
        .collection('sales')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  double get totalSales => state
      .where((s) => s.status == SaleStatus.final_)
      .fold(0.0, (acc, s) => acc + s.grandTotal);
  double get totalDue => state.fold(0.0, (acc, s) => acc + s.dueAmount);
}
