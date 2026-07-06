/*
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
}*/

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

class _BomProjectHistoryPageState extends State<BomProjectHistoryPage> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = sl<ApiClient>();
  late TabController _tabController;

  // ✅ FIXED: Dedicated vertical scroll controller to resolve the scroll position assertion error cleanly
  final ScrollController _verticalTableScrollController = ScrollController();

  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  List<dynamic> _allProjectsList = [];

  Map<String, dynamic>? _selectedProjectDetails;
  String? _selectedProjectCode;

  final List<Map<String, String>> _statusChoices = [
    {'value': 'PENDING', 'label': 'Pending Design/BOM'},
    {'value': 'ACTIVE', 'label': 'Active in Production'},
    {'value': 'COMPLETED', 'label': 'Dispatched & Completed'},
    {'value': 'HOLD', 'label': 'On Hold'},
    {'value': 'CANCEL', 'label': 'Project Cancel'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchDashboardProjects();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _verticalTableScrollController.dispose(); // Memory cleanup guard
    super.dispose();
  }
  void _handleTabSelection() {
    // ✅ FIXED: Changed from indexChanging to indexIsChanging property tag
    if (_tabController.indexIsChanging) return;
    _syncDefaultSelectionForActiveTab();
  }

  // ✅ Fetching master backend list without status filtering
  Future<void> _fetchDashboardProjects() async {
    setState(() => _isLoading = true);
    try {
      dev.log("➡️ Syncing Production Active Projects Dashboard Stream...");
      final response = await _apiClient.get('/api/erp/project-dashboard-status/');
      print("response data $response");

      final List rawData = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data['data'] ?? []);

      print("raw data $rawData");

      setState(() {
        _allProjectsList = rawData;
        _syncDefaultSelectionForActiveTab();
      });
    } catch (e) {
      dev.log("❌ Dashboard sync network collapse error: $e");
      _snack("Network Sync Error: Could not load data fields from backend registries", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Ensures right panel selection automatically re-attaches upon tab switching
  void _syncDefaultSelectionForActiveTab() {
    final filtered = _getFilteredProjectsForCurrentTab();
    if (filtered.isNotEmpty) {
      bool selectionExists = filtered.any((e) => e['project_code'] == _selectedProjectCode);
      if (!selectionExists) {
        _selectedProjectCode = filtered.first['project_code'];
        _selectedProjectDetails = filtered.first;
      } else {
        _selectedProjectDetails = filtered.firstWhere((e) => e['project_code'] == _selectedProjectCode);
      }
    } else {
      _selectedProjectCode = null;
      _selectedProjectDetails = null;
    }
    setState(() {});
  }

  // ✅ STATUS TAB FILTER MATRICES LOOKUP
  List<dynamic> _getFilteredProjectsForCurrentTab() {
    if (_tabController.index == 0) {
      // Tab 1: Live Workflow Pipeline Items
      return _allProjectsList.where((p) {
        final st = p['status'] ?? 'ACTIVE';
        return st == 'ACTIVE' || st == 'PENDING' || st == 'HOLD';
      }).toList();
    } else {
      // Tab 2: Dispatched & Archived Historical Snapshots
      return _allProjectsList.where((p) {
        final st = p['status'] ?? 'ACTIVE';
        return st == 'COMPLETED' || st == 'CANCEL';
      }).toList();
    }
  }

  Future<void> _updateProjectLifecycleStatus(int projectId, String statusToken) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final response = await _apiClient.post(
        '/api/erp/project-dashboard-status/$projectId/update-status/',
        data: {'status': statusToken},
      );

      if (response.statusCode == 200) {
        _snack("Project tracking status shifted to $statusToken cleanly!", Colors.teal);
        await _fetchDashboardProjects();
      }
    } catch (e) {
      _snack("Failed to patch workflow position context", Colors.redAccent);
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return const Color(0xFF10B981); // Green
      case 'PENDING': return const Color(0xFFF59E0B); // Amber
      case 'HOLD': return const Color(0xFFEF4444); // Red
      case 'COMPLETED': return const Color(0xFF3B82F6); // Blue
      case 'CANCEL': return const Color(0xFF64748B); // Slate
      default: return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1100;
    final filteredProjects = _getFilteredProjectsForCurrentTab();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("ERP INDUSTRIAL PROJECT TRACKING DASHBOARD ENGINE",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
            onPressed: _fetchDashboardProjects,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.yellowAccent.shade400,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(child: Text("ACTIVE PRODUCTION PIPELINE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            Tab(child: Text("ARCHIVED DISPATCHES & HISTORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 1.5))
          : Row(
        children: [
          // LEFT SIDE BAR: Filtered target index grid row
          Expanded(
            flex: isDesktop ? 2 : 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: filteredProjects.isEmpty
                  ? const Center(child: Text("No items inside this tracking segment framework.", style: TextStyle(fontSize: 11, color: Colors.grey)))
                  : ListView.separated(
                itemCount: filteredProjects.length,
                separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  bool isSelected = _selectedProjectCode == project['project_code'];
                  int ageDays = project['days_elapsed'] ?? 0;
                  String rowStatus = project['status'] ?? 'ACTIVE';
                  Color rowStatusColor = _getStatusColor(rowStatus);

                  return Material(
                    color: isSelected ? const Color(0xFFE2E8F0) : Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(left: BorderSide(color: rowStatusColor, width: 4))
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.only(left: isSelected ? 12 : 16, right: 16, top: 10, bottom: 10),
                        selected: isSelected,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(project['project_name'] ?? "UNASSIGNED NAME",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFF1E293B), overflow: TextOverflow.ellipsis)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: rowStatusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                rowStatus,
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: rowStatusColor),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text("$ageDays Days", style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500))
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Code Ref: ${project['project_code'] ?? 'N/A'}", style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: Colors.blueGrey)),
                            const SizedBox(height: 2),
                            Text("Client: ${project['customer_name'] ?? '—'}", style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
                          ],
                        ),
                        trailing: Text("₹ ${(project['latest_total_valuation'] ?? 0.0).toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF115E59))),
                        onTap: () {
                          setState(() {
                            _selectedProjectCode = project['project_code'];
                            _selectedProjectDetails = project;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // RIGHT PANEL: Spreadsheet detail segment area
          if (isDesktop || _selectedProjectDetails != null)
            Expanded(
              flex: 6,
              child: _selectedProjectDetails == null
                  ? const Center(child: Text("Select an operational tracking row item to populate specifications data matrix.", style: TextStyle(color: Colors.grey, fontSize: 11)))
                  : _buildDetailPanelView(),
            )
        ],
      ),
    );
  }

  Widget _buildDetailPanelView() {
    final details = _selectedProjectDetails!;
    final List<dynamic> items = details['items'] ?? [];
    final String currentStatus = details['status'] ?? 'ACTIVE';
    final int projectId = details['id'];

    // ✅ CRITICAL OPERATION FLAG: If inside archived dispatches tab, freeze operations completely
    final bool isReadOnlyMode = _tabController.index == 1;

    final String deliveryTimeline = (details['delivery_timeline'] != null)
        ? details['delivery_timeline'].toString()
        : ((details['delivery_timeline_formatted'] != null && details['delivery_timeline_formatted'] != "—")
        ? details['delivery_timeline_formatted']
        : "Timeline Not Set");

    final Color primaryStatusColor = _getStatusColor(currentStatus);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
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
                    Row(
                      children: [
                        Text(details['project_name'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryStatusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: primaryStatusColor, width: 1),
                          ),
                          child: Text(
                            currentStatus.toUpperCase(),
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: primaryStatusColor, letterSpacing: 0.5),
                          ),
                        ),
                        if (isReadOnlyMode) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: Colors.grey.shade100,
                            child: const Row(
                              children: [
                                Icon(Icons.lock_clock_outlined, size: 11, color: Colors.grey),
                                SizedBox(width: 4),
                                Text("READ-ONLY ARCHIVE", style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Project ID Token: ${details['project_code'] ?? '—'}  |  Snapshot Ref: ${details['latest_config_code'] ?? '—'}",
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Dropdown automatically completely shifts to gone state if inside read-only history tab
              if (!isReadOnlyMode)
                _isUpdatingStatus
                    ? const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0F172A))))
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentStatus,
                      icon: const Icon(Icons.swap_horizontal_circle_outlined, size: 14, color: Color(0xFF334155)),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      onChanged: (String? nextState) {
                        if (nextState != null && nextState != currentStatus) {
                          _updateProjectLifecycleStatus(projectId, nextState);
                        }
                      },
                      items: _statusChoices.map((Map<String, String> choice) {
                        return DropdownMenuItem<String>(
                          value: choice['value'],
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(choice['label']!.toUpperCase(), style: const TextStyle(fontSize: 10.5, letterSpacing: 0.3)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(width: 8),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.print_rounded, size: 14),
                label: const Text("PRINT MASTER METRICS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () => BomPdfGeneratorHelper.printConfigurationInvoice(details),
              )
            ],
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),

          Wrap(
            spacing: 36,
            runSpacing: 16,
            children: [
              _buildMetaField("CUSTOMER / CLIENT ENDPOINT", details['customer_name'] ?? '—'),
              _buildMetaField("TOTAL PROJECT QUANTITY", "${details['quantity'] ?? 0} Units"),
              _buildMetaField("PROJECT INITIALIZATION DATE", details['created_at_formatted'] ?? '—'),
              _buildMetaField("DELIVERY DATE", deliveryTimeline),
              _buildMetaField("TOTAL RUNNING DAY", "${details['days_elapsed'] ?? 0} Days Running"),
              _buildMetaField("TOTAL VALUATION COST", "₹ ${(details['latest_total_valuation'] ?? 0.0).toStringAsFixed(2)}", isAccent: true),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PROJECT OPERATIONAL INCHARGES DEPLOYMENT", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 0.3)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildInchargeMiniField("PROJECT MANAGER", details['project_incharge'])),
                    Expanded(child: _buildInchargeMiniField("DESIGN ARCHITECT", details['design_incharge'])),
                    Expanded(child: _buildInchargeMiniField("PURCHASE CONTROLLER", details['purchase_incharge'])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text("COMPREHENSIVE BILL OF MATERIALS (BOM) SPEC MATRIX (${items.length} ROWS)", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
              child: items.isEmpty
                  ? const Center(child: Text("No item specifications linked with this active project.", style: TextStyle(fontSize: 11, color: Colors.grey)))
                  : Scrollbar(
                thumbVisibility: true,
                // ✅ FIXED: Attaching explicit bound ScrollController parameter tag here to block layout crashes
                controller: _verticalTableScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: _verticalTableScrollController, // Bound tracker mirror
                  physics: const BouncingScrollPhysics(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
                      headingRowHeight: 36,
                      dataRowMaxHeight: 52,
                      dataRowMinHeight: 36,
                      horizontalMargin: 12,
                      columnSpacing: 28,
                      border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
                      columns: const [
                        DataColumn(label: Text('Item No', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Material Code / Registry Name', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Specs Description', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Process Flow Route', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Quantity', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Unit Rate', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total Valuation', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                      ],
                      rows: items.map((item) {
                        final matDetail = item['material_detail'] ?? {};
                        final String materialCode = matDetail['material_code'] ?? item['item_no']?.toString() ?? 'UNTRACKED';
                        final String materialName = matDetail['name'] ?? item['description'] ?? '';

                        final double unitRate = double.tryParse(matDetail['purchase_price']?.toString() ?? '') ?? double.tryParse(item['purchase_price']?.toString() ?? '') ?? 0.0;
                        final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                        final double lineTotal = unitRate * qty;

                        return DataRow(cells: [
                          DataCell(Text(item['item_no']?.toString() ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold))),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(materialCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              if (materialName.isNotEmpty) Text(materialName, style: const TextStyle(fontSize: 8.5, color: Colors.grey, overflow: TextOverflow.ellipsis)),
                            ],
                          )),
                          DataCell(Text(item['description']?.toString() ?? '—', style: const TextStyle(fontSize: 10))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: Colors.orange.shade50,
                            child: Text((item['process_flow']?.toString().isNotEmpty == true) ? item['process_flow'] : 'LASER CUTTING', style: const TextStyle(fontSize: 9.5, color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                          )),
                          DataCell(Text("$qty", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          DataCell(Text("₹ ${unitRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10))),
                          DataCell(Text("₹ ${lineTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF115E59)))),
                        ]);
                      }).toList(),
                    ),
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
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isAccent ? 14 : 11, fontWeight: FontWeight.bold, color: isAccent ? const Color(0xFF115E59) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildInchargeMiniField(String corporateRole, String? officerName) {
    return Row(
      children: [
        const Icon(Icons.verified_user_outlined, size: 12, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(corporateRole, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500)),
            Text(officerName ?? "UNASSIGNED STAFF", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ],
        ),
      ],
    );
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}