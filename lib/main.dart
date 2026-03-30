import 'package:custom_erp/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/firebase/firestore_bootstrap.dart';

// ─────────────────────────────────────────────────────────────────────────────
// To connect Firebase:
//   1. Run: flutterfire configure
//   2. Uncomment the Firebase.initializeApp call below
//   3. Set AppConstants.demoMode = false in core/constants/app_constants.dart
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!AppConstants.demoMode) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await FirestoreBootstrap.ensureInitialized();
  }

  runApp(
    const ProviderScope(
      child: ErpApp(),
    ),
  );
}
