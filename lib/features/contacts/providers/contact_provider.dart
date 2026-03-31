import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/contact.dart';

const _uuid = Uuid();

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Contact>>(
  (ref) => ContactsNotifier(ref),
);

class ContactsNotifier extends StateNotifier<List<Contact>> {
  ContactsNotifier(this.ref)
      : super(AppConstants.demoMode ? _demoContacts : const []) {
    if (!AppConstants.demoMode) {
      _bizSub = ref.listen<String?>(currentBusinessIdProvider, (prev, next) {
        _bind(next);
      }, fireImmediately: true);
    }
  }

  final Ref ref;
  ProviderSubscription<String?>? _bizSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static final _demoContacts = [
    Contact(
      id: 'c1',
      businessId: AppConstants.demoBusinessId,
      name: 'Ahmed Traders',
      type: ContactType.supplier,
      phone: '+880 1711-111111',
      email: 'ahmed@traders.com',
      city: 'Dhaka',
      debitBalance: 45000,
      createdAt: DateTime(2024, 1, 15),
    ),
    Contact(
      id: 'c2',
      businessId: AppConstants.demoBusinessId,
      name: 'Rahman Brothers',
      type: ContactType.customer,
      phone: '+880 1722-222222',
      email: 'rahman@brothers.com',
      city: 'Chittagong',
      creditBalance: 12000,
      createdAt: DateTime(2024, 2, 10),
    ),
    Contact(
      id: 'c3',
      businessId: AppConstants.demoBusinessId,
      name: 'Karim Supplies',
      type: ContactType.both,
      phone: '+880 1733-333333',
      city: 'Sylhet',
      debitBalance: 8000,
      creditBalance: 3000,
      createdAt: DateTime(2024, 3, 5),
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
        .collection('contacts')
        .snapshots()
        .listen((snap) {
      state = snap.docs.map((d) => Contact.fromMap(d.data(), d.id)).toList();
    });
  }

  Future<String> add(Contact contact) async {
    if (AppConstants.demoMode) {
      final newId = _uuid.v4();
      final newContact = Contact(
        id: newId,
        businessId: contact.businessId,
        name: contact.name,
        type: contact.type,
        phone: contact.phone,
        email: contact.email,
        address: contact.address,
        city: contact.city,
        taxNumber: contact.taxNumber,
        openingBalance: contact.openingBalance,
        payTermDays: contact.payTermDays,
        createdAt: DateTime.now(),
      );
      state = [...state, newContact];
      return newId;
    }

    final businessId =
        ref.read(currentBusinessIdProvider) ?? contact.businessId;
    if (businessId.isEmpty) return '';

    final docId =
        contact.id.trim().isNotEmpty ? contact.id.trim() : _uuid.v4();

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('contacts')
        .doc(docId)
        .set({
      ...contact.toMap(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docId;
  }

  Future<void> update(Contact updated) async {
    if (AppConstants.demoMode) {
      state = [
        for (final c in state)
          if (c.id == updated.id) updated else c,
      ];
      return;
    }

    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(updated.businessId)
        .collection('contacts')
        .doc(updated.id)
        .set({
      ...updated.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
        .collection('contacts')
        .doc(id)
        .delete();
  }

  List<Contact> byType(ContactType? type) {
    if (type == null) return state;
    return state
        .where((c) => c.type == type || c.type == ContactType.both)
        .toList();
  }

  List<Contact> get suppliers => state
      .where(
          (c) => c.type == ContactType.supplier || c.type == ContactType.both)
      .toList();

  List<Contact> get customers => state
      .where(
          (c) => c.type == ContactType.customer || c.type == ContactType.both)
      .toList();
}
