import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class FirestoreBootstrap {
  FirestoreBootstrap._();

  static const String _metaCollection = 'system_meta';
  static const String _bootstrapDocId = 'bootstrap_v1';

  static Future<void> ensureInitialized() async {
    if (AppConstants.demoMode) {
      debugPrint('Firestore bootstrap skipped: demo mode enabled.');
      return;
    }

    if (!AppConstants.autoBootstrapFirestore) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint(
          'Firestore bootstrap skipped: no authenticated Firebase user.');
      return;
    }

    final db = FirebaseFirestore.instance;
    final metaRef = db.collection(_metaCollection).doc(_bootstrapDocId);

    try {
      final meta = await metaRef.get();
      final currentVersion = (meta.data()?['version'] as num?)?.toInt() ?? 0;
      if (currentVersion >= AppConstants.firestoreBootstrapVersion) {
        return;
      }

      final batch = db.batch();

      final businessRef =
          db.collection('businesses').doc(AppConstants.demoBusinessId);
      batch.set(
          businessRef,
          <String, dynamic>{
            'name': AppConstants.demoBusinessName,
            'currencyCode': AppConstants.defaultCurrencyCode,
            'currencySymbol': AppConstants.defaultCurrencySymbol,
            'timeZone': 'Asia/Dhaka',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      batch.set(
        businessRef.collection('locations').doc(AppConstants.demoLocationId),
        <String, dynamic>{
          'name': 'Main Store',
          'code': 'BL0001',
          'address': 'Dhaka',
          'isPrimary': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        businessRef.collection('users').doc(AppConstants.demoUserId),
        <String, dynamic>{
          'name': 'Owner',
          'email': 'owner@demo.local',
          'role': 'admin',
          'permissions': <String>['*'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      for (final unit in _units) {
        batch.set(
          businessRef.collection('units').doc(unit['id']!),
          <String, dynamic>{
            ...unit,
            'businessId': AppConstants.demoBusinessId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      for (final category in _categories) {
        batch.set(
          businessRef.collection('categories').doc(category['id']!),
          <String, dynamic>{
            ...category,
            'businessId': AppConstants.demoBusinessId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      for (final brand in _brands) {
        batch.set(
          businessRef.collection('brands').doc(brand['id']!),
          <String, dynamic>{
            ...brand,
            'businessId': AppConstants.demoBusinessId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      for (final product in _products) {
        batch.set(
          businessRef.collection('products').doc(product['id']!),
          <String, dynamic>{
            ...product,
            'businessId': AppConstants.demoBusinessId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      for (final contact in _contacts) {
        batch.set(
          businessRef.collection('contacts').doc(contact['id']!),
          <String, dynamic>{
            ...contact,
            'businessId': AppConstants.demoBusinessId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      for (final expenseCategory in _expenseCategories) {
        batch.set(
          businessRef
              .collection('expenseCategories')
              .doc(expenseCategory['id']!),
          <String, dynamic>{
            ...expenseCategory,
            'businessId': AppConstants.demoBusinessId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      batch.set(
          metaRef,
          <String, dynamic>{
            'version': AppConstants.firestoreBootstrapVersion,
            'seededBusinessId': AppConstants.demoBusinessId,
            'seededLocationId': AppConstants.demoLocationId,
            'seededUserId': AppConstants.demoUserId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();
      debugPrint('Firestore bootstrap completed.');
    } catch (e) {
      debugPrint('Firestore bootstrap failed: $e');
    }
  }

  static const List<Map<String, dynamic>> _units = <Map<String, dynamic>>[
    {'id': 'u1', 'name': 'Piece', 'abbreviation': 'Pc', 'allowDecimals': false},
    {'id': 'u2', 'name': 'Meter', 'abbreviation': 'm', 'allowDecimals': true},
    {
      'id': 'u3',
      'name': 'Kilogram',
      'abbreviation': 'kg',
      'allowDecimals': true
    },
    {'id': 'u4', 'name': 'Box', 'abbreviation': 'Box', 'allowDecimals': false},
  ];

  static const List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[
    {'id': 'cat1', 'name': 'Pipes & Fittings'},
    {'id': 'cat2', 'name': 'Valves'},
    {'id': 'cat3', 'name': 'Faucets & Showers'},
    {'id': 'cat4', 'name': 'Water Storage'},
  ];

  static const List<Map<String, dynamic>> _brands = <Map<String, dynamic>>[
    {'id': 'br1', 'name': 'Supreme'},
    {'id': 'br2', 'name': 'Valvex'},
    {'id': 'br3', 'name': 'Grohe'},
    {'id': 'br4', 'name': 'Tuff'},
  ];

  static const List<Map<String, dynamic>> _products = <Map<String, dynamic>>[
    {
      'id': 'p1',
      'name': 'PVC Pipe 1"',
      'sku': 'PVC-001',
      'categoryId': 'cat1',
      'brandId': 'br1',
      'unitId': 'u1',
      'purchasePrice': 80.0,
      'sellingPrice': 120.0,
      'taxPercent': 0.0,
      'stockQuantity': 250.0,
      'alertQuantity': 20.0
    },
    {
      'id': 'p2',
      'name': 'PVC Pipe 2"',
      'sku': 'PVC-002',
      'categoryId': 'cat1',
      'brandId': 'br1',
      'unitId': 'u1',
      'purchasePrice': 150.0,
      'sellingPrice': 220.0,
      'taxPercent': 0.0,
      'stockQuantity': 180.0,
      'alertQuantity': 20.0
    },
    {
      'id': 'p3',
      'name': 'Ball Valve 1/2"',
      'sku': 'BV-001',
      'categoryId': 'cat2',
      'brandId': 'br2',
      'unitId': 'u2',
      'purchasePrice': 45.0,
      'sellingPrice': 75.0,
      'taxPercent': 0.0,
      'stockQuantity': 120.0,
      'alertQuantity': 15.0
    },
    {
      'id': 'p4',
      'name': 'Gate Valve 3/4"',
      'sku': 'GV-001',
      'categoryId': 'cat2',
      'brandId': 'br2',
      'unitId': 'u2',
      'purchasePrice': 120.0,
      'sellingPrice': 180.0,
      'taxPercent': 0.0,
      'stockQuantity': 8.0,
      'alertQuantity': 10.0
    },
    {
      'id': 'p5',
      'name': 'Faucet Chrome',
      'sku': 'FC-001',
      'categoryId': 'cat3',
      'brandId': 'br3',
      'unitId': 'u2',
      'purchasePrice': 350.0,
      'sellingPrice': 550.0,
      'taxPercent': 0.0,
      'stockQuantity': 45.0,
      'alertQuantity': 5.0
    },
    {
      'id': 'p6',
      'name': 'Shower Head',
      'sku': 'SH-001',
      'categoryId': 'cat3',
      'brandId': 'br3',
      'unitId': 'u2',
      'purchasePrice': 280.0,
      'sellingPrice': 450.0,
      'taxPercent': 0.0,
      'stockQuantity': 30.0,
      'alertQuantity': 5.0
    },
    {
      'id': 'p7',
      'name': 'Water Tank 500L',
      'sku': 'WT-001',
      'categoryId': 'cat4',
      'brandId': 'br4',
      'unitId': 'u2',
      'purchasePrice': 2800.0,
      'sellingPrice': 4200.0,
      'taxPercent': 0.0,
      'stockQuantity': 3.0,
      'alertQuantity': 2.0
    },
    {
      'id': 'p8',
      'name': 'Pipe Elbow 1"',
      'sku': 'PE-001',
      'categoryId': 'cat1',
      'brandId': 'br1',
      'unitId': 'u2',
      'purchasePrice': 12.0,
      'sellingPrice': 20.0,
      'taxPercent': 0.0,
      'stockQuantity': 500.0,
      'alertQuantity': 50.0
    },
  ];

  static const List<Map<String, dynamic>> _contacts = <Map<String, dynamic>>[
    {
      'id': 'c1',
      'name': 'Ahmed Traders',
      'type': 'supplier',
      'phone': '+880 1711-111111',
      'email': 'ahmed@traders.com',
      'city': 'Dhaka',
      'debitBalance': 45000.0,
      'creditBalance': 0.0
    },
    {
      'id': 'c2',
      'name': 'Rahman Brothers',
      'type': 'customer',
      'phone': '+880 1722-222222',
      'email': 'rahman@brothers.com',
      'city': 'Chittagong',
      'debitBalance': 0.0,
      'creditBalance': 12000.0
    },
    {
      'id': 'c3',
      'name': 'Karim Supplies',
      'type': 'both',
      'phone': '+880 1733-333333',
      'city': 'Sylhet',
      'debitBalance': 8000.0,
      'creditBalance': 3000.0
    },
  ];

  static const List<Map<String, dynamic>> _expenseCategories =
      <Map<String, dynamic>>[
    {'id': 'ec1', 'name': 'Rent'},
    {'id': 'ec2', 'name': 'Utilities'},
    {'id': 'ec3', 'name': 'Salaries'},
    {'id': 'ec4', 'name': 'Transport'},
    {'id': 'ec5', 'name': 'Marketing'},
    {'id': 'ec6', 'name': 'Miscellaneous'},
  ];
}
