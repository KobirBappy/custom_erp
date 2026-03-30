class DashboardStats {
  const DashboardStats({
    this.totalSales = 0.0,
    this.netSales = 0.0,
    this.invoiceDue = 0.0,
    this.totalSellReturn = 0.0,
    this.totalSellReturnPaid = 0.0,
    this.totalPurchase = 0.0,
    this.purchaseDue = 0.0,
    this.totalExpense = 0.0,
    this.transportExpense = 0.0,
    this.totalPurchaseReturn = 0.0,
    this.totalPurchaseReturnPaid = 0.0,
    this.salesLast30Days = const [],
  });

  final double totalSales;
  final double netSales;
  final double invoiceDue;
  final double totalSellReturn;
  final double totalSellReturnPaid;
  final double totalPurchase;
  final double purchaseDue;
  final double totalExpense;
  final double transportExpense;
  final double totalPurchaseReturn;
  final double totalPurchaseReturnPaid;

  /// Daily sales amounts for the last 30 days (index 0 = oldest)
  final List<double> salesLast30Days;

  static const DashboardStats empty = DashboardStats();

  static DashboardStats get demo => const DashboardStats(
        totalSales: 125430.50,
        netSales: 118200.00,
        invoiceDue: 23500.00,
        totalSellReturn: 4200.00,
        totalSellReturnPaid: 3800.00,
        totalPurchase: 89300.00,
        purchaseDue: 15600.00,
        totalExpense: 12400.00,
        transportExpense: 2800.00,
        totalPurchaseReturn: 1800.00,
        totalPurchaseReturnPaid: 1200.00,
        salesLast30Days: [
          1200,
          980,
          1450,
          2100,
          1800,
          2300,
          3100,
          2800,
          1900,
          2600,
          3200,
          2700,
          1500,
          3800,
          4200,
          3600,
          2900,
          3300,
          4100,
          3700,
          2400,
          3900,
          4500,
          3800,
          2700,
          4100,
          3600,
          4800,
          5200,
          4600,
        ],
      );
}
