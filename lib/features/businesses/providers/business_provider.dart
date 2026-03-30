import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/models/app_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/business.dart';
import '../models/business_location.dart';

const _uuid = Uuid();

final businessesProvider =
    StateNotifierProvider<BusinessesNotifier, List<Business>>(
  (ref) => BusinessesNotifier(ref),
);

class BusinessesNotifier extends StateNotifier<List<Business>> {
  BusinessesNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoBusinesses : const []) {
    if (!AppConstants.demoMode) {
      _authSub = ref.listen<AppUser?>(authProvider, (prev, next) {
        _bindBusinesses(next?.businessIds ?? const <String>[]);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<AppUser?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static final _demoBusinesses = [
    Business(
      id: AppConstants.demoBusinessId,
      name: 'Jamuna Sanitary',
      currencySymbol: '?',
      currencyCode: 'BDT',
      phone: '+880 1700-000000',
      email: 'info@jamunasnitary.com',
      address: '123 Main Road, Dhaka',
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.close();
    super.dispose();
  }

  void _bindBusinesses(List<String> businessIds) {
    _sub?.cancel();

    if (businessIds.isEmpty) {
      state = const [];
      return;
    }

    final ids =
        businessIds.length > 10 ? businessIds.take(10).toList() : businessIds;
    _sub = FirebaseFirestore.instance
        .collection('businesses')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .listen((snap) {
      final list =
          snap.docs.map((d) => Business.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      state = list;
    });
  }

  Future<void> add(Business business) async {
    final appUser = ref.read(authProvider);
    final ownerId = appUser?.uid ?? '';

    if (AppConstants.demoMode) {
      final newBusiness = Business(
        id: _uuid.v4(),
        name: business.name,
        currencySymbol: business.currencySymbol,
        currencyCode: business.currencyCode,
        timezone: business.timezone,
        financialYearStart: business.financialYearStart,
        defaultProfitMargin: business.defaultProfitMargin,
        phone: business.phone,
        email: business.email,
        address: business.address,
        taxNumber: business.taxNumber,
        ownerId: ownerId,
        createdAt: DateTime.now(),
      );
      state = [...state, newBusiness];
      return;
    }

    final id = _uuid.v4();
    final doc = FirebaseFirestore.instance.collection('businesses').doc(id);

    await doc.set({
      ...business.copyWith().toMap(),
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (ownerId.isNotEmpty) {
      await doc.collection('users').doc(ownerId).set({
        'role': 'owner',
        'isActive': true,
        'name': appUser?.displayName ?? '',
        'email': appUser?.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> update(Business updated) async {
    if (AppConstants.demoMode) {
      state = [
        for (final b in state)
          if (b.id == updated.id) updated else b,
      ];
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((b) => b.id != id).toList();
      return;
    }

    await FirebaseFirestore.instance.collection('businesses').doc(id).delete();
  }

  Business? getById(String id) {
    try {
      return state.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

final currentBusinessProvider = Provider<Business?>((ref) {
  final businesses = ref.watch(businessesProvider);
  if (businesses.isEmpty) return null;

  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  if (currentBusinessId == null || currentBusinessId.isEmpty) {
    return businesses.first;
  }

  for (final business in businesses) {
    if (business.id == currentBusinessId) return business;
  }

  return businesses.first;
});

final locationsProvider =
    StateNotifierProvider<LocationsNotifier, List<BusinessLocation>>(
  (ref) => LocationsNotifier(ref),
);

final currentLocationProvider = Provider<BusinessLocation?>((ref) {
  final locations = ref.watch(locationsProvider);
  if (locations.isEmpty) return null;
  return locations.first;
});

class LocationsNotifier extends StateNotifier<List<BusinessLocation>> {
  LocationsNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoLocations : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bindLocations(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static final _demoLocations = [
    const BusinessLocation(
      id: AppConstants.demoLocationId,
      businessId: AppConstants.demoBusinessId,
      name: 'Main Store',
      type: LocationType.storefront,
      address: '123 Main Road',
      city: 'Dhaka',
      phone: '+880 1700-000000',
      invoicePrefix: 'BL',
    ),
    const BusinessLocation(
      id: 'demo_loc_002',
      businessId: AppConstants.demoBusinessId,
      name: 'Warehouse',
      type: LocationType.warehouse,
      address: '456 Industrial Area',
      city: 'Dhaka',
    ),
  ];

  @override
  void dispose() {
    _sub?.cancel();
    _bizSub?.close();
    super.dispose();
  }

  void _bindLocations(String? businessId) {
    _sub?.cancel();

    if (businessId == null || businessId.isEmpty) {
      state = const [];
      return;
    }

    _sub = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('locations')
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => BusinessLocation.fromMap(d.data(), d.id))
          .toList();
    });
  }

  Future<void> add(BusinessLocation location) async {
    if (AppConstants.demoMode) {
      final newLocation = BusinessLocation(
        id: _uuid.v4(),
        businessId: location.businessId,
        name: location.name,
        type: location.type,
        address: location.address,
        city: location.city,
        phone: location.phone,
        invoicePrefix: location.invoicePrefix,
      );
      state = [...state, newLocation];
      return;
    }

    final businessId =
        ref.read(currentBusinessIdProvider) ?? location.businessId;
    if (businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('locations')
        .add({
      ...location.copyWith().toMap(),
      'businessId': businessId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(BusinessLocation updated) async {
    if (AppConstants.demoMode) {
      state = [
        for (final l in state)
          if (l.id == updated.id) updated else l,
      ];
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.businessId)
        .collection('locations')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    if (AppConstants.demoMode) {
      state = state.where((l) => l.id != id).toList();
      return;
    }

    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null || businessId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('locations')
        .doc(id)
        .delete();
  }

  List<BusinessLocation> forBusiness(String businessId) =>
      state.where((l) => l.businessId == businessId).toList();
}
