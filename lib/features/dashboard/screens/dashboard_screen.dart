import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../businesses/providers/business_provider.dart';
import '../../businesses/models/business_location.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../expenses/models/expense.dart';
import '../../products/models/product.dart';
import '../../products/providers/product_provider.dart';
import '../../purchases/models/purchase.dart';
import '../../purchases/providers/purchase_provider.dart';
import '../../returns/providers/return_provider.dart';
import '../../sales/models/sale.dart';
import '../../sales/providers/sale_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final products = ref.watch(productsProvider);
    final sales = ref.watch(salesProvider);
    final purchases = ref.watch(purchasesProvider);
    final expenses = ref.watch(expensesProvider);
    final locations = ref.watch(locationsProvider);
    final saleReturns = ref.watch(saleReturnsProvider);
    final purchaseReturns = ref.watch(purchaseReturnsProvider);

    final totalIn = sales.fold(0.0, (sum, s) => sum + s.paidAmount) +
        purchaseReturns.fold(0.0, (sum, r) => sum + r.paidAmount);
    final totalOut = purchases.fold(0.0, (sum, p) => sum + p.paidAmount) +
        expenses.fold(0.0, (sum, e) => sum + e.amount) +
        saleReturns.fold(0.0, (sum, r) => sum + r.paidAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsGrid(stats: stats),
          const SizedBox(height: 24),
          _ProfitLossCard(stats: stats),
          const SizedBox(height: 24),
          _BranchPerformanceCard(
            locations: locations,
            sales: sales,
            purchases: purchases,
            expenses: expenses,
          ),
          const SizedBox(height: 24),
          _ExpenseCashflowCard(
            expenses: expenses,
            totalInflow: totalIn,
            totalOutflow: totalOut,
          ),
          const SizedBox(height: 24),
          _SalesChart(salesData: stats.salesLast30Days),
          const SizedBox(height: 24),
          _ProductStockChart(
            products: products,
            locations: locations,
          ),
        ],
      ),
    );
  }
}

class _ProfitLossCard extends StatelessWidget {
  const _ProfitLossCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    const sym = AppConstants.defaultCurrencySymbol;
    final revenue = stats.totalSales - stats.totalSellReturn;
    final cogs = stats.totalPurchase - stats.totalPurchaseReturn;
    final expense = stats.totalExpense;
    final netProfit = revenue - cogs - expense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit / Loss Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _plRow(
              'Revenue (Sales - Sale Return)',
              CurrencyFormatter.formatSimple(revenue, symbol: sym),
              AppColors.success,
            ),
            _plRow(
              'Cost (Purchase - Purchase Return)',
              CurrencyFormatter.formatSimple(cogs, symbol: sym),
              AppColors.error,
            ),
            _plRow(
              'Operating Expense',
              CurrencyFormatter.formatSimple(expense, symbol: sym),
              AppColors.warning,
            ),
            const Divider(height: 18),
            _plRow(
              'Net Profit / Loss',
              CurrencyFormatter.formatSimple(netProfit, symbol: sym),
              netProfit >= 0 ? AppColors.success : AppColors.error,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _plRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchPerformanceCard extends StatelessWidget {
  const _BranchPerformanceCard({
    required this.locations,
    required this.sales,
    required this.purchases,
    required this.expenses,
  });

  final List<BusinessLocation> locations;
  final List<Sale> sales;
  final List<Purchase> purchases;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final branchRows = locations.map<Map<String, dynamic>>((loc) {
      final locationSales = sales
          .where((s) => s.locationId == loc.id)
          .fold<double>(0.0, (sum, s) => sum + s.grandTotal);
      final locationPurchases = purchases
          .where((p) => p.locationId == loc.id)
          .fold<double>(0.0, (sum, p) => sum + p.grandTotal);
      final locationExpenses = expenses
          .where((e) => e.locationId == loc.id)
          .fold<double>(0.0, (sum, e) => sum + e.amount);
      final net = locationSales - locationPurchases - locationExpenses;
      return <String, dynamic>{
        'name': loc.name,
        'sales': locationSales,
        'purchase': locationPurchases,
        'expense': locationExpenses,
        'net': net,
      };
    }).toList();

    final maxMagnitude = branchRows.fold<double>(
      100,
      (m, r) => r['net'].abs() > m ? r['net'].abs() : m,
    );

    const sym = AppConstants.defaultCurrencySymbol;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Branch-wise Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: branchRows.isEmpty
                  ? const Center(child: Text('No branch data found'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        minY: -maxMagnitude * 1.1,
                        maxY: maxMagnitude * 1.1,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxMagnitude / 4,
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (v, _) => Text(
                                '${(v / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= branchRows.length) {
                                  return const SizedBox.shrink();
                                }
                                final n = branchRows[i]['name'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    n.length > 10
                                        ? '${n.substring(0, 10)}..'
                                        : n,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(branchRows.length, (i) {
                          final net = branchRows[i]['net'] as double;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: net,
                                width: 20,
                                color: net >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            ...branchRows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(r['name'] as String)),
                      Text(
                        CurrencyFormatter.formatSimple(
                          r['net'] as double,
                          symbol: sym,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (r['net'] as double) >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCashflowCard extends StatelessWidget {
  const _ExpenseCashflowCard({
    required this.expenses,
    required this.totalInflow,
    required this.totalOutflow,
  });

  final List<Expense> expenses;
  final double totalInflow;
  final double totalOutflow;

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.categoryName] = (byCategory[e.categoryName] ?? 0) + e.amount;
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = categories.take(6).toList();
    final double maxY = top.isEmpty
        ? 100.0
        : top.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    const sym = AppConstants.defaultCurrencySymbol;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Analytics & Cashflow Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniSummary(
                    'Cash Inflow',
                    CurrencyFormatter.formatSimple(totalInflow, symbol: sym),
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniSummary(
                    'Cash Outflow',
                    CurrencyFormatter.formatSimple(totalOutflow, symbol: sym),
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniSummary(
                    'Net Cash',
                    CurrencyFormatter.formatSimple(
                      totalInflow - totalOutflow,
                      symbol: sym,
                    ),
                    totalInflow - totalOutflow >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: top.isEmpty
                  ? const Center(child: Text('No expense data'))
                  : BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        maxY: maxY,
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              getTitlesWidget: (v, _) => Text(
                                '${(v / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= top.length) {
                                  return const SizedBox.shrink();
                                }
                                final name = top[i].key;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    name.length > 10
                                        ? '${name.substring(0, 10)}..'
                                        : name,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(top.length, (i) {
                          final v = top[i].value;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: v,
                                width: 16,
                                color: AppColors.cardRed,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniSummary(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    const sym = AppConstants.defaultCurrencySymbol;
    final cards = [
      _CardData(
          'TOTAL SALES',
          CurrencyFormatter.formatSimple(stats.totalSales, symbol: sym),
          Icons.shopping_cart_outlined,
          AppColors.cardBlue),
      _CardData(
          'NET',
          CurrencyFormatter.formatSimple(stats.netSales, symbol: sym),
          Icons.receipt_outlined,
          AppColors.cardGreen,
          info: true),
      _CardData(
          'INVOICE DUE',
          CurrencyFormatter.formatSimple(stats.invoiceDue, symbol: sym),
          Icons.warning_amber_outlined,
          AppColors.cardOrange),
      _CardData(
          'TOTAL SELL RETURN',
          CurrencyFormatter.formatSimple(stats.totalSellReturn, symbol: sym),
          Icons.swap_horiz_outlined,
          AppColors.cardRed,
          sub1:
              'Total Sell Return: ${CurrencyFormatter.formatSimple(stats.totalSellReturn, symbol: sym)}',
          sub2:
              'Total Sell Return Paid: ${CurrencyFormatter.formatSimple(stats.totalSellReturnPaid, symbol: sym)}'),
      _CardData(
          'TOTAL PURCHASE',
          CurrencyFormatter.formatSimple(stats.totalPurchase, symbol: sym),
          Icons.attach_money_outlined,
          AppColors.cardCyan),
      _CardData(
          'PURCHASE DUE',
          CurrencyFormatter.formatSimple(stats.purchaseDue, symbol: sym),
          Icons.error_outline,
          AppColors.cardOrange),
      _CardData(
          'EXPENSE',
          CurrencyFormatter.formatSimple(stats.totalExpense, symbol: sym),
          Icons.remove_circle_outline,
          AppColors.cardRed),
      _CardData(
          'TRANSPORT COST',
          CurrencyFormatter.formatSimple(stats.transportExpense, symbol: sym),
          Icons.local_shipping_outlined,
          AppColors.cardPurple),
      _CardData(
          'TOTAL PURCHASE RETURN',
          CurrencyFormatter.formatSimple(stats.totalPurchaseReturn,
              symbol: sym),
          Icons.replay_outlined,
          AppColors.cardRed,
          sub1:
              'Total Purchase Return: ${CurrencyFormatter.formatSimple(stats.totalPurchaseReturn, symbol: sym)}',
          sub2:
              'Total Purchase Return Paid: ${CurrencyFormatter.formatSimple(stats.totalPurchaseReturnPaid, symbol: sym)}'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900
          ? 4
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: cols == 4 ? 2.1 : 2.4,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) => _StatCard(data: cards[i]),
      );
    });
  }
}

class _CardData {
  const _CardData(this.title, this.value, this.icon, this.color,
      {this.info = false, this.sub1, this.sub2});
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool info;
  final String? sub1;
  final String? sub2;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: data.color,
              child: Icon(data.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(data.title,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5)),
                      if (data.info) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.info_outline,
                            size: 12, color: AppColors.textSecondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data.value,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  if (data.sub1 != null) ...[
                    const SizedBox(height: 2),
                    Text(data.sub1!,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                    Text(data.sub2 ?? '',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sales chart ───────────────────────────────────────────────────────────────

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.salesData});
  final List<double> salesData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sales Last 30 Days',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 2,
                      color: AppColors.cardBlue,
                    ),
                    const SizedBox(width: 6),
                    const Text('Main Store (BL0001)',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: salesData.isEmpty
                  ? const Center(child: Text('No sales data'))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _maxY / 4,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.cardBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            axisNameWidget: const RotatedBox(
                              quarterTurns: 3,
                              child: Text('Total Sales (BDT)',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary)),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (val, _) => Text(
                                val == 0
                                    ? '0'
                                    : '${(val / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx % 5 != 0) {
                                  return const SizedBox.shrink();
                                }
                                final date = DateTime.now()
                                    .subtract(Duration(days: 29 - idx));
                                return Text('${date.day}/${date.month}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary));
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 29,
                        minY: 0,
                        maxY: _maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              salesData.length,
                              (i) => FlSpot(i.toDouble(), salesData[i]),
                            ),
                            isCurved: true,
                            color: AppColors.cardBlue,
                            barWidth: 2,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                radius: 3,
                                color: AppColors.cardBlue,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.cardBlue.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double get _maxY {
    if (salesData.isEmpty) return 100;
    final max = salesData.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 100 : max * 1.3;
  }
}

class _ProductStockChart extends StatelessWidget {
  const _ProductStockChart({
    required this.products,
    required this.locations,
  });

  final List<Product> products;
  final List<BusinessLocation> locations;

  @override
  Widget build(BuildContext context) {
    final locationMap = <String, BusinessLocation>{
      for (final l in locations) l.id: l,
    };

    final rows = <Map<String, dynamic>>[];
    for (final p in products) {
      if (p.stockByLocation.isEmpty) {
        rows.add(<String, dynamic>{
          'label': '${p.name.trim()} (ALL)',
          'stock': p.stockQuantity,
        });
        continue;
      }

      for (final entry in p.stockByLocation.entries) {
        final qty = entry.value;
        if (qty <= 0) continue;
        final locShort = _locationShort(locationMap[entry.key]);
        rows.add(<String, dynamic>{
          'label': '${p.name.trim()} ($locShort)',
          'stock': qty,
        });
      }
    }

    rows.sort((a, b) => (b['stock'] as double).compareTo(a['stock'] as double));
    final topRows = rows.take(12).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Stock by Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Product name + location short form with quantity',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: topRows.isEmpty
                  ? const Center(child: Text('No product stock data'))
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _maxY(topRows) / 5,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.cardBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: _maxY(topRows),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              getTitlesWidget: (value, _) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= topRows.length) {
                                  return const SizedBox.shrink();
                                }
                                final name = topRows[idx]['label'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    name.length > 14
                                        ? '${name.substring(0, 14)}..'
                                        : name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(topRows.length, (index) {
                          final stock = topRows[index]['stock'] as double;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: stock,
                                width: 16,
                                color: AppColors.cardBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                            showingTooltipIndicators: const [0],
                          );
                        }),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Showing top 12 product-location quantities',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  double _maxY(List<Map<String, dynamic>> rows) {
    final top = rows
        .map((r) => (r['stock'] as double))
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (top <= 0) return 5;
    return top * 1.25;
  }

  String _locationShort(BusinessLocation? location) {
    if (location == null) return 'LOC';
    final prefix = location.invoicePrefix.trim();
    if (prefix.isNotEmpty) return prefix.toUpperCase();
    final words =
        location.name.split(' ').where((w) => w.trim().isNotEmpty).toList();
    if (words.isEmpty) return 'LOC';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}
