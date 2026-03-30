import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense.dart';

const _uuid = Uuid();

final expenseCategoriesProvider =
    StateNotifierProvider<ExpenseCategoriesNotifier, List<ExpenseCategory>>(
  (ref) => ExpenseCategoriesNotifier(ref),
);

class ExpenseCategoriesNotifier extends StateNotifier<List<ExpenseCategory>> {
  ExpenseCategoriesNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoCategories : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const _demoCategories = [
    ExpenseCategory(
        id: 'ec1', businessId: AppConstants.demoBusinessId, name: 'Rent'),
    ExpenseCategory(
        id: 'ec2', businessId: AppConstants.demoBusinessId, name: 'Utilities'),
    ExpenseCategory(
        id: 'ec3', businessId: AppConstants.demoBusinessId, name: 'Salaries'),
    ExpenseCategory(
        id: 'ec4', businessId: AppConstants.demoBusinessId, name: 'Transport'),
    ExpenseCategory(
        id: 'ec5', businessId: AppConstants.demoBusinessId, name: 'Marketing'),
    ExpenseCategory(
        id: 'ec6',
        businessId: AppConstants.demoBusinessId,
        name: 'Miscellaneous'),
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
        .collection('expenseCategories')
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => ExpenseCategory.fromMap(d.data(), d.id))
          .toList();
    }, onError: (_, __) {
      // Keep existing state and avoid crashing UI on transient permission/network issues.
    });
  }

  Future<void> add(ExpenseCategory cat) async {
    if (AppConstants.demoMode) {
      state = [
        ...state,
        ExpenseCategory(
            id: _uuid.v4(), businessId: cat.businessId, name: cat.name)
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider) ?? cat.businessId;
    if (businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('expenseCategories')
        .doc(_uuid.v4())
        .set({
      ...cat.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((c) => c.id != id).toList();
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('expenseCategories')
        .doc(id)
        .delete();
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>(
  (ref) => ExpensesNotifier(ref),
);

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoExpenses : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static final _demoExpenses = [
    Expense(
        id: 'e1',
        businessId: AppConstants.demoBusinessId,
        locationId: AppConstants.demoLocationId,
        categoryId: 'ec1',
        categoryName: 'Rent',
        amount: 25000,
        date: DateTime(2026, 3, 1),
        note: 'Monthly rent'),
    Expense(
        id: 'e2',
        businessId: AppConstants.demoBusinessId,
        locationId: AppConstants.demoLocationId,
        categoryId: 'ec2',
        categoryName: 'Utilities',
        amount: 3500,
        date: DateTime(2026, 3, 5),
        note: 'Electricity bill'),
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
        .collection('expenses')
        .snapshots()
        .listen((snap) {
      state = snap.docs.map((d) => Expense.fromMap(d.data(), d.id)).toList();
    }, onError: (_, __) {
      // Keep existing state and avoid crashing UI on transient permission/network issues.
    });
  }

  Future<void> add(Expense expense) async {
    if (AppConstants.demoMode) {
      final newExpense = Expense(
        id: _uuid.v4(),
        businessId: expense.businessId,
        locationId: expense.locationId,
        categoryId: expense.categoryId,
        categoryName: expense.categoryName,
        amount: expense.amount,
        date: expense.date,
        paymentMethod: expense.paymentMethod,
        note: expense.note,
        createdAt: DateTime.now(),
      );
      state = [...state, newExpense];
      return;
    }

    final businessId =
        ref.read(currentBusinessIdProvider) ?? expense.businessId;
    if (businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('expenses')
        .doc(_uuid.v4())
        .set({
      ...expense.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTransportExpense({
    required String businessId,
    required String locationId,
    required double amount,
    DateTime? date,
    String paymentMethod = 'cash',
    String note = '',
  }) async {
    if (amount <= 0) return;

    final fallbackNote =
        note.trim().isEmpty ? 'Transport cost from POS checkout' : note;

    await add(
      Expense(
        id: '',
        businessId: businessId,
        locationId: locationId,
        categoryId: 'ec_transport',
        categoryName: 'Transport',
        amount: amount,
        date: date ?? DateTime.now(),
        paymentMethod: paymentMethod,
        note: fallbackNote,
      ),
    );
  }

  Future<void> update(Expense updated) async {
    if (AppConstants.demoMode) {
      state = [
        for (final e in state)
          if (e.id == updated.id) updated else e
      ];
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.businessId)
        .collection('expenses')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((e) => e.id != id).toList();
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('expenses')
        .doc(id)
        .delete();
  }

  double get totalExpenses => state.fold(0.0, (acc, e) => acc + e.amount);

  Map<String, double> get byCategory {
    final map = <String, double>{};
    for (final e in state) {
      map[e.categoryName] = (map[e.categoryName] ?? 0) + e.amount;
    }
    return map;
  }
}
