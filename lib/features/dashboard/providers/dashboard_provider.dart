import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../../sales/providers/sale_provider.dart';
import '../../purchases/providers/purchase_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../returns/providers/return_provider.dart';

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final sales = ref.watch(salesProvider);
  final purchases = ref.watch(purchasesProvider);
  final expenses = ref.watch(expensesProvider);
  final saleReturns = ref.watch(saleReturnsProvider);
  final purchaseReturns = ref.watch(purchaseReturnsProvider);

  final totalSales = sales.fold(0.0, (sum, s) => sum + s.grandTotal);
  final totalSellReturn = saleReturns.fold(0.0, (sum, r) => sum + r.amount);
  final totalSellReturnPaid =
      saleReturns.fold(0.0, (sum, r) => sum + r.paidAmount);
  final invoiceDue = sales.fold(0.0, (sum, s) => sum + s.dueAmount);
  final totalPurchase = purchases.fold(0.0, (sum, p) => sum + p.grandTotal);
  final totalPurchaseReturn =
      purchaseReturns.fold(0.0, (sum, r) => sum + r.amount);
  final totalPurchaseReturnPaid =
      purchaseReturns.fold(0.0, (sum, r) => sum + r.paidAmount);
  final purchaseDue = purchases.fold(0.0, (sum, p) => sum + p.dueAmount);
  final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
  final transportExpense = expenses
      .where((e) => e.categoryName.toLowerCase() == 'transport')
      .fold(0.0, (sum, e) => sum + e.amount);

  // Build last-30-days sales array
  final now = DateTime.now();
  final salesLast30Days = List.generate(30, (i) {
    final day = DateTime(now.year, now.month, now.day - (29 - i));
    return sales
        .where((s) =>
            s.saleDate.year == day.year &&
            s.saleDate.month == day.month &&
            s.saleDate.day == day.day)
        .fold(0.0, (sum, s) => sum + s.grandTotal);
  });

  return DashboardStats(
    totalSales: totalSales,
    netSales: totalSales - totalSellReturn,
    invoiceDue: invoiceDue,
    totalSellReturn: totalSellReturn,
    totalSellReturnPaid: totalSellReturnPaid,
    totalPurchase: totalPurchase,
    purchaseDue: purchaseDue,
    totalExpense: totalExpense,
    transportExpense: transportExpense,
    totalPurchaseReturn: totalPurchaseReturn,
    totalPurchaseReturnPaid: totalPurchaseReturnPaid,
    salesLast30Days: salesLast30Days,
  );
});
