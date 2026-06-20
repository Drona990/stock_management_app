import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockDashboardView extends StatefulWidget {
  const StockDashboardView({super.key});

  @override
  State<StockDashboardView> createState() => _StockDashboardViewState();
}

class _StockDashboardViewState extends State<StockDashboardView> {
  // --- PRODUCTION-READY STATIC ERP DATASET MATRIX ---
  final double staticRevenue = 485960.00;
  final double staticDiscount = 12450.00;
  final int staticStock = 2450;
  final int staticSold = 840;
  final int staticBills = 312;

  final Map<String, double> staticPaymentModes = {
    "CASH ON HAND": 185400.00,
    "UPI / QR SCANNER": 210560.00,
    "CREDIT / DEBIT CARD": 75400.00,
    "NEFT / BANK TRANSFER": 14600.00,
  };

  final List<Map<String, dynamic>> staticRecentSales = [
    {"bill_no": "INV-2026-001", "customer": "Ultra Industries", "items": 12, "total_amount": 45000.00, "time": "10:30 AM"},
    {"bill_no": "INV-2026-002", "customer": "Apex Retailers", "items": 5, "total_amount": 18500.00, "time": "11:15 AM"},
    {"bill_no": "INV-2026-003", "customer": "Drona Enterprises", "items": 45, "total_amount": 142000.00, "time": "12:00 PM"},
    {"bill_no": "INV-2026-004", "customer": "Singasandra Trading", "items": 8, "total_amount": 24300.00, "time": "02:45 PM"},
    {"bill_no": "INV-2026-005", "customer": "Matrix Logistics", "items": 22, "total_amount": 89000.00, "time": "04:10 PM"},
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    const Color industrialSlate = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB), // ERP Standard light canvas background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 50,
        iconTheme: const IconThemeData(color: industrialSlate, size: 18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "REAL-TIME STOCK ANALYTICS ENGINE",
                style: TextStyle(color: industrialSlate, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)
            ),
            Text(
              "STATIC SIMULATION LAYER • ${DateFormat('dd MMMM yyyy').format(DateTime.now()).toUpperCase()}",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.analytics_outlined, size: 12, color: Colors.cyanAccent),
              label: const Text("MASTER REPORTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Simulation Mode: Master report channel executed successfully."), backgroundColor: Colors.blueGrey),
                );
              },
            ),
          )
        ],
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================================================
            // 📊 1. HIGH-DENSITY KPI CARDS GRID MATRIX
            // ==========================================================================
            GridView.count(
              crossAxisCount: isMobile ? 2 : 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 2.2 : 2.5,
              children: [
                _buildStaticKpi("GROSS REVENUE", "₹${staticRevenue.toStringAsFixed(2)}", const Color(0xFF10B981), Icons.payments_outlined),
                _buildStaticKpi("DISCOUNTS ROUTED", "₹${staticDiscount.toStringAsFixed(2)}", const Color(0xFFEF4444), Icons.card_giftcard_outlined),
                _buildStaticKpi("CURRENT STOCK", staticStock.toString(), const Color(0xFF3B82F6), Icons.inventory_2_outlined),
                _buildStaticKpi("ITEMS DISPATCHED", staticSold.toString(), const Color(0xFFF59E0B), Icons.shopping_cart_outlined),
                _buildStaticKpi("VOUCHER BILL COUNT", staticBills.toString(), const Color(0xFF8B5CF6), Icons.receipt_long_outlined),
              ],
            ),
            const SizedBox(height: 20),

            // ==========================================================================
            // 🏢 2. DATA GRAPHICS & SYSTEM REGISTRY SEGMENT
            // ==========================================================================
            isMobile
                ? Column(
              children: [
                _buildStaticSalesTable(isMobile),
                const SizedBox(height: 16),
                _buildStaticPaymentBreakdown(),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildStaticSalesTable(isMobile)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildStaticPaymentBreakdown()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ⚡ CORE GRAPHICAL WIDGET RE-ENGINEERING COMPILER
  // ==========================================================================

  Widget _buildStaticKpi(String title, String value, Color schemaColor, IconData displayIcon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, bottom: 0,
            child: Container(width: 4, color: schemaColor), // Left edge indicator marker
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: schemaColor.withOpacity(0.08),
                  child: Icon(displayIcon, color: schemaColor, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          title,
                          style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.3)
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                            value,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticSalesTable(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIXED: Border ka niche ka line decoration ab ekdam standard ho gaya hai
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: const Row(
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 14, color: Color(0xFF0F4C81)),
                SizedBox(width: 8),
                Text("RECENT ACCOUNTING TRANSACTIONS RECORDS", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF1E293B), letterSpacing: 0.3)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: BoxConstraints(minWidth: isMobile ? 400 : 600),
              child: DataTable(
                headingRowHeight: 34,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text("TRANSACTION BILL NO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  DataColumn(label: Text("CLIENT PARTY NAME", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  DataColumn(label: Text("QTY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  DataColumn(label: Text("COMPOUND VALUE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                ],
                rows: staticRecentSales.map((sale) => DataRow(
                    cells: [
                      DataCell(Text(sale['bill_no'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)))),
                      DataCell(Text(sale['customer'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500))),
                      DataCell(Text(sale['items'].toString(), style: const TextStyle(fontSize: 10))),
                      DataCell(Text("₹${sale['total_amount'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 10))),
                    ]
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStaticPaymentBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF0F4C81)),
              SizedBox(width: 8),
              Text("LIQUIDITY & PAYMENT MODES AUDIT", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: Color(0xFF1E293B), letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          ...staticPaymentModes.entries.map((entry) {
            // Graphical percentage scale mapping logic
            double percentage = (entry.value / staticRevenue);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      Text("₹${entry.value.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}