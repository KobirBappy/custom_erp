class AppConstants {
  AppConstants._();

  /// Set to true to run with demo data (no Firebase needed).
  /// Set to false to use real Firebase backend.
  static const bool demoMode = false;

  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsedWidth = 64.0;
  static const double topBarHeight = 60.0;

  static const String appName = 'Custom ERP';
  static const String defaultCurrencySymbol = '৳';
  static const String defaultCurrencyCode = 'BDT';

  static const String demoBusinessId = 'demo_biz_001';
  static const String demoLocationId = 'demo_loc_001';
  static const String demoUserId = 'demo_user_001';
  static const String demoBusinessName = 'My Business';

  /// Auto-create initial Firestore documents on app start.
  /// Keep this false for SaaS mode. Business data is created at signup.
  static const bool autoBootstrapFirestore = false;
  static const int firestoreBootstrapVersion = 1;

  /// Super admin emails that can approve business enrollment and payment requests.
  static const List<String> superAdminEmails = <String>[
    'kobir.hosanpro@gmail.com',
  ];
}
