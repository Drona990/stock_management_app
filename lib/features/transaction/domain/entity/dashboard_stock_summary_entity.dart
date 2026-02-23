class DashboardStockSummaryEntity {
  final double sales;
  final double purchases;
  final double profit;
  final double netFlow;
  final double wastage;
  final double valuation;
  final int lowStockCount;
  final List<dynamic> productList;

  DashboardStockSummaryEntity({
    required this.sales, required this.purchases, required this.profit,
    required this.netFlow, required this.wastage, required this.valuation,
    required this.lowStockCount, required this.productList,
  });

  factory DashboardStockSummaryEntity.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic v) => double.tryParse(v?.toString() ?? '0.0') ?? 0.0;
    final s = json['stats'] ?? {};
    final inv = json['inventory'] ?? {};

    return DashboardStockSummaryEntity(
      sales: parseD(s['sales']),
      purchases: parseD(s['purchases']),
      profit: parseD(s['profit']),
      netFlow: parseD(s['net_flow']),
      wastage: parseD(s['wastage']),
      valuation: parseD(inv['valuation']),
      lowStockCount: (inv['low_stock_count'] as int?) ?? 0,
      productList: inv['product_list'] ?? [],
    );
  }
}