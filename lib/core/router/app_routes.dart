class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String superAdminDashboard = '/super-admin/dashboard';

  // Business management
  static const String businesses = '/businesses';
  static const String locations = '/locations';

  // User management
  static const String users = '/users';
  static const String rolesPermissions = '/roles-permissions';

  // Contacts
  static const String contacts = '/contacts';
  static const String contactNew = '/contacts/new';
  static const String contactEdit = '/contacts/:id';

  // Products
  static const String products = '/products';
  static const String productNew = '/products/new';
  static const String productEdit = '/products/:id';
  static const String categories = '/products/categories';
  static const String brands = '/products/brands';
  static const String units = '/products/units';

  // Purchases
  static const String purchases = '/purchases';
  static const String purchaseNew = '/purchases/new';
  static const String purchaseView = '/purchases/:id';

  // Sell
  static const String sell = '/sell';
  static const String pos = '/sell/pos';
  static const String saleView = '/sell/:id';

  // Stock
  static const String stockTransfers = '/stock-transfers';
  static const String stockTransferNew = '/stock-transfers/new';
  static const String stockAdjustments = '/stock-adjustments';
  static const String stockAdjustmentNew = '/stock-adjustments/new';

  // Expenses
  static const String expenses = '/expenses';
  static const String expenseNew = '/expenses/new';

  // Reports
  static const String reports = '/reports';
  static const String returns = '/returns';

  // Notifications
  static const String notifications = '/notifications';

  // Settings
  static const String settings = '/settings';
  static const String packages = '/packages';
  static const String superAdmin = '/super-admin';
}
