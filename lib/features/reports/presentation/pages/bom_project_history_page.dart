import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/bom_project_printting_service.dart';
import '../../../../injection.dart';

class BomProjectHistoryPage extends StatefulWidget {
  const BomProjectHistoryPage({super.key});

  @override
  State<BomProjectHistoryPage> createState() => _BomProjectHistoryPageState();
}

class _BomProjectHistoryPageState extends State<BomProjectHistoryPage> {
  final ApiClient _apiClient = sl<ApiClient>();
  bool _isLoading = false;
  List<dynamic> _configurationsList = [];
  Map<String, dynamic>? _selectedConfigDetails;
  String? _selectedConfigCode;

  @override
  void initState() {
    super.initState();
    _fetchHistoryFromBackend();
  }

  // ✅ Functional Backend Data Fetch Stream
  Future<void> _fetchHistoryFromBackend() async {
    setState(() => _isLoading = true);
    try {
      dev.log("➡️ Syncing Production Configurations Release History...");
      // ✅ Updated URL pointing straight to the new Django viewset endpoint
      final response = await _apiClient.get('/api/erp/project-history/');

      print(("history response $response"));

      final List rawData = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data['data'] ?? []);

      setState(() {
        _configurationsList = rawData;

        // Auto-select the first item on fresh load if available
        if (_configurationsList.isNotEmpty && _selectedConfigCode == null) {
          _selectedConfigCode = _configurationsList.first['config_code'];
          _selectedConfigDetails = _configurationsList.first;
        } else if (_selectedConfigCode != null) {
          // Keep selection synchronized on manual list updates
          _selectedConfigDetails = _configurationsList.firstWhere(
                (element) => element['config_code'] == _selectedConfigCode,
            orElse: () => null,
          );
        }
      });
      dev.log("⬅️ History Synchronized Successfully. Total Records: ${_configurationsList.length}");
    } catch (e) {
      dev.log("❌ History network pipeline sync error: $e");
      _snack("Network Error: Showing cached memory fallback layers", Colors.blueGrey);

      setState(() {
        _configurationsList = _getMockFallbackData();
        if (_configurationsList.isNotEmpty) {
          _selectedConfigCode = _configurationsList.first['config_code'];
          _selectedConfigDetails = _configurationsList.first;
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("BOM PRODUCTION CONFIGURATION ARCHIVE HISTORY",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            onPressed: _fetchHistoryFromBackend,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 1.5))
          : Row(
        children: [
          // LEFT PANEL: Configurations Code List Matrix
          Expanded(
            flex: isDesktop ? 2 : 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: _configurationsList.isEmpty
                  ? const Center(child: Text("No configuration manifest logs tracked.", style: TextStyle(fontSize: 11, color: Colors.grey)))
                  : ListView.separated(
                itemCount: _configurationsList.length,
                separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final config = _configurationsList[index];
                  bool isSelected = _selectedConfigCode == config['config_code'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFF1F5F9),
                    title: Text(config['config_code'] ?? "CFG-GEN-UNASSIGNED",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFF1E293B))),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Template Ref: ${config['parent_project_code'] ?? 'N/A'}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                        const SizedBox(height: 2),
                        Text("Date Logs: ${config['created_at'] ?? '—'}", style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                      ],
                    ),
                    trailing: Text("₹ ${(config['grand_total_estimation_cost'] ?? 0.0).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF115E59))),
                    onTap: () {
                      setState(() {
                        _selectedConfigCode = config['config_code'];
                        _selectedConfigDetails = config;
                      });
                    },
                  );
                },
              ),
            ),
          ),

          // RIGHT PANEL: Detailed Spreadsheet View Area
          if (isDesktop || _selectedConfigDetails != null)
            Expanded(
              flex: 5,
              child: _selectedConfigDetails == null
                  ? const Center(child: Text("Select a configuration log token from left matrix view.", style: TextStyle(color: Colors.grey, fontSize: 11)))
                  : _buildDetailPanelView(),
            )
        ],
      ),
    );
  }

  Widget _buildDetailPanelView() {
    final details = _selectedConfigDetails!;
    final List<dynamic> items = details['configured_items'] ?? [];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(details['config_code'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text("Parent Target Matrix Specification: ${details['project_name'] ?? '—'} (${details['parent_project_code'] ?? '—'})",
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF115E59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text("PRINT TAX INVOICE MANIFEST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                // ✅ Calling the bound printing services logic
                onPressed: () => BomPdfGeneratorHelper.printConfigurationInvoice(details),
              )
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _buildMetaField("CONFIGURED QTY MULTIPLIER", "${details['final_configured_quantity'] ?? 0} Units"),
              _buildMetaField("DELIVERY TIMELINE TRACK", details['delivery_timeline'] ?? '—'),
              _buildMetaField("DISPATCH LOCATION", details['location'] ?? '—'),
              _buildMetaField("SOLD BY STAFF", details['sold_by_staff_name'] ?? '—'),
              _buildMetaField("GRAND PIPELINE COST VALUATION", "₹ ${(details['grand_total_estimation_cost'] ?? 0.0).toStringAsFixed(2)}", isAccent: true),
            ],
          ),
          const SizedBox(height: 24),

          Text("BOM RE-MULTIPLIED SNAPSHOT ITEMS BLOCK (${items.length})", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
              child: items.isEmpty
                  ? const Center(child: Text("No item matrices tracked inside this configuration.", style: TextStyle(fontSize: 11, color: Colors.grey)))
                  : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    // ✅ FIXED: Using clean and correct WidgetStatePropertyAll tracking class
                    headingRowColor: const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
                    headingRowHeight: 32,
                    dataRowMaxHeight: 42,
                    dataRowMinHeight: 32,
                    horizontalMargin: 12,
                    columnSpacing: 24,
                    border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
                    columns: const [
                      DataColumn(label: Text('Item No', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Description Specs', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Raw Size', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Finishing Size', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Process Flow', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Quantity', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Unit Rate', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total Cost', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                    ],
                    rows: items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['item_no']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold))),
                        DataCell(Text(item['description']?.toString() ?? '', style: const TextStyle(fontSize: 10))),
                        DataCell(Text(item['raw_size']?.toString() ?? '—', style: const TextStyle(fontSize: 10))),
                        DataCell(Text(item['finishing_size']?.toString() ?? '—', style: const TextStyle(fontSize: 10))),
                        DataCell(Text(item['process_flow']?.toString() ?? 'LASER CUTTING', style: const TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.w600))),
                        DataCell(Text(item['quantity']?.toString() ?? '0', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red))),
                        DataCell(Text("₹ ${(item['purchase_price'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontSize: 10))),
                        DataCell(Text("₹ ${(item['total_cost'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetaField(String title, String value, {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: isAccent ? 14 : 11, fontWeight: FontWeight.bold, color: isAccent ? const Color(0xFF115E59) : const Color(0xFF1E293B))),
      ],
    );
  }

  // ✅ FIXED: Using standard SnackBarBehavior with safe property tags mapping
  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _getMockFallbackData() {
    return [
      {
        "config_code": "CFG-2026-00001",
        "parent_project_code": "PRJ-2026-0009",
        "project_name": "Heavy Duty Storage Rack Layout",
        "final_configured_quantity": 5,
        "grand_total_estimation_cost": 25000.00,
        "delivery_timeline": "12 Days",
        "created_at": "2026-06-07 11:30 AM",
        "location": "Warehouse Block-A",
        "sold_by_staff_name": "Satish Kumar",
        "configured_items": [
          {"item_no": "MAT-001", "description": "Main Pillar Channel", "raw_size": "40X35", "finishing_size": "38X33", "process_flow": "LASER CUTTING", "quantity": 5, "purchase_price": 3000.00, "total_cost": 15000.00},
          {"item_no": "MAT-002", "description": "Support Angle Plates", "raw_size": "35X25", "finishing_size": "35X25", "process_flow": "BENDING", "quantity": 10, "purchase_price": 1000.00, "total_cost": 10000.00},
        ]
      }
    ];
  }
}