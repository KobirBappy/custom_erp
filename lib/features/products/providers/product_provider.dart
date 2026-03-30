import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/providers/business_provider.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/unit.dart';

const _uuid = Uuid();

final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>(
  (ref) => ProductsNotifier(ref),
);

class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoProducts : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const _demoProducts = [
    Product(
        id: 'p1',
        businessId: AppConstants.demoBusinessId,
        name: 'PVC Pipe 1"',
        sku: 'PVC-001',
        categoryId: 'cat1',
        brandId: 'br1',
        unitId: 'u1',
        purchasePrice: 80,
        sellingPrice: 120,
        stockQuantity: 250,
        alertQuantity: 20),
    Product(
        id: 'p2',
        businessId: AppConstants.demoBusinessId,
        name: 'PVC Pipe 2"',
        sku: 'PVC-002',
        categoryId: 'cat1',
        brandId: 'br1',
        unitId: 'u1',
        purchasePrice: 150,
        sellingPrice: 220,
        stockQuantity: 180,
        alertQuantity: 20),
    Product(
        id: 'p3',
        businessId: AppConstants.demoBusinessId,
        name: 'Ball Valve 1/2"',
        sku: 'BV-001',
        categoryId: 'cat2',
        brandId: 'br2',
        unitId: 'u2',
        purchasePrice: 45,
        sellingPrice: 75,
        stockQuantity: 120,
        alertQuantity: 15),
    Product(
        id: 'p4',
        businessId: AppConstants.demoBusinessId,
        name: 'Gate Valve 3/4"',
        sku: 'GV-001',
        categoryId: 'cat2',
        brandId: 'br2',
        unitId: 'u2',
        purchasePrice: 120,
        sellingPrice: 180,
        stockQuantity: 8,
        alertQuantity: 10),
    Product(
        id: 'p5',
        businessId: AppConstants.demoBusinessId,
        name: 'Faucet Chrome',
        sku: 'FC-001',
        categoryId: 'cat3',
        brandId: 'br3',
        unitId: 'u2',
        purchasePrice: 350,
        sellingPrice: 550,
        stockQuantity: 45,
        alertQuantity: 5),
    Product(
        id: 'p6',
        businessId: AppConstants.demoBusinessId,
        name: 'Shower Head',
        sku: 'SH-001',
        categoryId: 'cat3',
        brandId: 'br3',
        unitId: 'u2',
        purchasePrice: 280,
        sellingPrice: 450,
        stockQuantity: 30,
        alertQuantity: 5),
    Product(
        id: 'p7',
        businessId: AppConstants.demoBusinessId,
        name: 'Water Tank 500L',
        sku: 'WT-001',
        categoryId: 'cat4',
        brandId: 'br4',
        unitId: 'u2',
        purchasePrice: 2800,
        sellingPrice: 4200,
        stockQuantity: 3,
        alertQuantity: 2),
    Product(
        id: 'p8',
        businessId: AppConstants.demoBusinessId,
        name: 'Pipe Elbow 1"',
        sku: 'PE-001',
        categoryId: 'cat1',
        brandId: 'br1',
        unitId: 'u2',
        purchasePrice: 12,
        sellingPrice: 20,
        stockQuantity: 500,
        alertQuantity: 50),
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
        .collection('products')
        .snapshots()
        .listen((snap) {
      state = snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
    });
  }

  Future<void> add(Product product) async {
    if (AppConstants.demoMode) {
      state = [
        ...state,
        Product(
          id: _uuid.v4(),
          businessId: product.businessId,
          name: product.name,
          sku: product.sku,
          type: product.type,
          categoryId: product.categoryId,
          brandId: product.brandId,
          unitId: product.unitId,
          description: product.description,
          purchasePrice: product.purchasePrice,
          sellingPrice: product.sellingPrice,
          taxPercent: product.taxPercent,
          stockQuantity: product.stockQuantity,
          stockByLocation: product.stockByLocation,
          alertQuantity: product.alertQuantity,
          createdAt: DateTime.now(),
        ),
      ];
      return;
    }

    final businessId =
        ref.read(currentBusinessIdProvider) ?? product.businessId;
    if (businessId.isEmpty) return;

    final id = _uuid.v4();
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .doc(id)
        .set({
      ...product.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(Product updated) async {
    if (AppConstants.demoMode) {
      state = [
        for (final p in state)
          if (p.id == updated.id) updated else p,
      ];
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.businessId)
        .collection('products')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((p) => p.id != id).toList();
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .doc(id)
        .delete();
  }

  Future<void> adjustStock(String productId, double delta,
      {String? locationId}) async {
    if (AppConstants.demoMode) {
      final branchId = locationId ?? ref.read(currentLocationProvider)?.id;
      state = [
        for (final p in state)
          if (p.id == productId)
            () {
              final map = Map<String, double>.from(p.stockByLocation);
              if (branchId != null && branchId.isNotEmpty) {
                final current = p.stockForLocation(branchId);
                map[branchId] = current + delta;
              }
              final total = map.isEmpty
                  ? p.stockQuantity + delta
                  : map.values.fold<double>(0.0, (s, v) => s + v);
              return p.copyWith(stockQuantity: total, stockByLocation: map);
            }()
          else
            p,
      ];
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('products')
        .doc(productId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final item =
        Product.fromMap(snap.data() ?? const <String, dynamic>{}, snap.id);
    final branchId =
        locationId ?? ref.read(currentLocationProvider)?.id ?? item.locationId;
    final map = Map<String, double>.from(item.stockByLocation);
    if (branchId != null && branchId.isNotEmpty) {
      final current = item.stockForLocation(branchId);
      map[branchId] = current + delta;
    }
    final total = map.isEmpty
        ? item.stockQuantity + delta
        : map.values.fold<double>(0.0, (s, v) => s + v);

    await docRef.set({
      'stockQuantity': total,
      'stockByLocation': map,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> transferStock({
    required String productId,
    required String fromLocationId,
    required String toLocationId,
    required double qty,
  }) async {
    if (qty <= 0) {
      throw Exception('Transfer quantity must be greater than zero.');
    }
    if (fromLocationId == toLocationId) {
      throw Exception('From and To branch cannot be the same.');
    }

    Product? item;
    try {
      item = state.firstWhere((p) => p.id == productId);
    } catch (_) {
      item = null;
    }
    if (item == null) {
      throw Exception('Product not found.');
    }

    final fromAvailable = item.stockForLocation(fromLocationId);
    if (fromAvailable < qty) {
      throw Exception('Insufficient stock in source branch.');
    }

    final map = Map<String, double>.from(item.stockByLocation);
    map[fromLocationId] = fromAvailable - qty;
    map[toLocationId] = item.stockForLocation(toLocationId) + qty;
    final total = map.values.fold<double>(0.0, (s, v) => s + v);

    await update(
      item.copyWith(
        stockByLocation: map,
        stockQuantity: total,
      ),
    );
  }

  List<Product> get lowStockProducts =>
      state.where((p) => p.isLowStock).toList();

  List<Product> search(String query) {
    if (query.trim().isEmpty) return state;
    final q = query.toLowerCase();
    return state
        .where((p) =>
            p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q))
        .toList();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>(
  (ref) => CategoriesNotifier(ref),
);

class CategoriesNotifier extends _TenantCollectionNotifier<Category> {
  CategoriesNotifier(super.ref)
      : super(
          collectionName: 'categories',
          fromMap: (data, id) => Category.fromMap(data, id),
          demoState: AppConstants.demoMode ? _demoCategories : const [],
        );

  static const _demoCategories = [
    Category(
        id: 'cat1',
        businessId: AppConstants.demoBusinessId,
        name: 'Pipes & Fittings'),
    Category(
        id: 'cat2', businessId: AppConstants.demoBusinessId, name: 'Valves'),
    Category(
        id: 'cat3',
        businessId: AppConstants.demoBusinessId,
        name: 'Faucets & Showers'),
    Category(
        id: 'cat4',
        businessId: AppConstants.demoBusinessId,
        name: 'Water Storage'),
  ];

  Future<String?> add(Category cat) async {
    final id = _uuid.v4();
    await addDoc(cat.toMap(), docId: id);
    return id;
  }

  Future<void> update(Category updated) async =>
      setDoc(updated.id, updated.toMap());
  Future<void> delete(String id) async => deleteDoc(id);
}

final brandsProvider = StateNotifierProvider<BrandsNotifier, List<Brand>>(
  (ref) => BrandsNotifier(ref),
);

class BrandsNotifier extends _TenantCollectionNotifier<Brand> {
  BrandsNotifier(super.ref)
      : super(
          collectionName: 'brands',
          fromMap: (data, id) => Brand.fromMap(data, id),
          demoState: AppConstants.demoMode ? _demoBrands : const [],
        );

  static const _demoBrands = [
    Brand(id: 'br1', businessId: AppConstants.demoBusinessId, name: 'Supreme'),
    Brand(id: 'br2', businessId: AppConstants.demoBusinessId, name: 'Valvex'),
    Brand(id: 'br3', businessId: AppConstants.demoBusinessId, name: 'Grohe'),
    Brand(id: 'br4', businessId: AppConstants.demoBusinessId, name: 'Tuff'),
  ];

  Future<String?> add(Brand brand) async {
    final id = _uuid.v4();
    await addDoc(brand.toMap(), docId: id);
    return id;
  }

  Future<void> update(Brand updated) async =>
      setDoc(updated.id, updated.toMap());
  Future<void> delete(String id) async => deleteDoc(id);
}

final unitsProvider = StateNotifierProvider<UnitsNotifier, List<Unit>>(
  (ref) => UnitsNotifier(ref),
);

class UnitsNotifier extends _TenantCollectionNotifier<Unit> {
  UnitsNotifier(super.ref)
      : super(
          collectionName: 'units',
          fromMap: (data, id) => Unit.fromMap(data, id),
          demoState: AppConstants.demoMode ? _demoUnits : const [],
        );

  static const _demoUnits = [
    Unit(
        id: 'u1',
        businessId: AppConstants.demoBusinessId,
        name: 'Piece',
        abbreviation: 'Pc'),
    Unit(
        id: 'u2',
        businessId: AppConstants.demoBusinessId,
        name: 'Meter',
        abbreviation: 'm',
        allowDecimals: true),
    Unit(
        id: 'u3',
        businessId: AppConstants.demoBusinessId,
        name: 'Kilogram',
        abbreviation: 'kg',
        allowDecimals: true),
    Unit(
        id: 'u4',
        businessId: AppConstants.demoBusinessId,
        name: 'Box',
        abbreviation: 'Box'),
  ];

  Future<String?> add(Unit unit) async {
    final id = _uuid.v4();
    await addDoc(unit.toMap(), docId: id);
    return id;
  }

  Future<void> update(Unit updated) async =>
      setDoc(updated.id, updated.toMap());
  Future<void> delete(String id) async => deleteDoc(id);
}

class _TenantCollectionNotifier<T> extends StateNotifier<List<T>> {
  _TenantCollectionNotifier(
    this.ref, {
    required this.collectionName,
    required this.fromMap,
    required List<T> demoState,
  }) : super(demoState) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  final String collectionName;
  final T Function(Map<String, dynamic>, String) fromMap;

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
      state = snap.docs.map((d) => fromMap(d.data(), d.id)).toList();
    });
  }

  Future<void> addDoc(Map<String, dynamic> data,
      {required String docId}) async {
    if (AppConstants.demoMode) {
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
        .doc(docId)
        .set({
      ...data,
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDoc(String id, Map<String, dynamic> data) async {
    if (AppConstants.demoMode) {
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
        .set({
      ...data,
      'businessId': businessId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDoc(String id) async {
    if (AppConstants.demoMode) {
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
