import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/stock_dashboard_bloc.dart';

class StockDashboardView extends StatefulWidget {
  const StockDashboardView({super.key});
  @override
  State<StockDashboardView> createState() => _StockDashboardViewState();
}

class _StockDashboardViewState extends State<StockDashboardView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    context.read<DashboardStockBloc>().add(FetchDashboardStats());
  }

  // 🔍 Search Logic: Name aur SKU dono par kaam karega
  void _runSearch(String query) {
    setState(() {
      _filteredProducts = _allProducts
          .where((p) =>
      p['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
          p['sku'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocConsumer<DashboardStockBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardLoaded) {
            _allProducts = state.summary.productList;
            _filteredProducts = _allProducts;
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading) return const Center(child: CircularProgressIndicator());
          if (state is DashboardLoaded) {
            final d = state.summary;
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  if (d.lowStockCount > 0) _buildAlertBar(d.lowStockCount),

                  // 💰 Horizontal Rectangular Cards (Swipable)
                  const SizedBox(height: 12),
                  _buildMetricsRow(d),

                  // 🔍 Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSearchBar(),
                  ),

                  // 📋 Product List Table
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("INVENTORY STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildProductList()),
                ],
              ),
            );
          }
          return const Center(child: Text("Unable to sync data"));
        },
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Control Center", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        IconButton(onPressed: () => context.read<DashboardStockBloc>().add(FetchDashboardStats()), icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
  );

  Widget _buildAlertBar(int count) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade100)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 18),
      const SizedBox(width: 8),
      Text("$count Items are running low!", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );

  // 💰 Rectangular Metric Cards Fix
  Widget _buildMetricsRow(var d) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        _metricCard("Sales Today", "₹${d.sales}", const Color(0xFF0EA5E9)),
        _metricCard("Total Profit", "₹${d.profit}", const Color(0xFF10B981)),
        _metricCard("Net Cash Flow", "₹${d.netFlow}", const Color(0xFF00BCD4)), // ⬅️ CASH FLOW ADDED
        _metricCard("Purchase", "₹${d.purchases}", const Color(0xFF6366F1)),
        _metricCard("Stock Value", "₹${d.valuation}", const Color(0xFFF59E0B)),
        _metricCard("Wastage Loss", "₹${d.wastage}", const Color(0xFFEF4444)),
      ],
    ),
  );

  Widget _metricCard(String label, String value, Color color) => Container(
    width: 170, // Rectangular Shape
    height: 90,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );

  Widget _buildSearchBar() => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: TextField(
      controller: _searchController,
      onChanged: _runSearch,
      decoration: const InputDecoration(
        hintText: "Search SKU or Product Name...",
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
        border: InputBorder.none,
        icon: Icon(Icons.search, color: Colors.cyan),
      ),
    ),
  );

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) return const Center(child: Text("No items found"));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, i) {
        final item = _filteredProducts[i];
        final bool isLow = (item['current_stock'] ?? 0) < 5;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text("SKU: ${item['sku']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: isLow ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(
              "${item['current_stock']}",
              style: TextStyle(fontWeight: FontWeight.w900, color: isLow ? Colors.red : Colors.green),
            ),
          ),
        );
      },
    );
  }
}