/*
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/bom_project_printting_service.dart';
import '../../../../injection.dart';

class BomProjectHistoryPage extends StatefulWidget {
  const BomProjectHistoryPage({super.key});

  @override
  State<BomProjectHistoryPage> createState() => _BomProjectHistoryPageState();
}

class _BomProjectHistoryPageState extends State<BomProjectHistoryPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = sl<ApiClient>();
  late TabController _tabController;

  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  List<dynamic> _allProjectsList = [];

  Map<String, dynamic>? _selectedProjectDetails;
  String? _selectedConfigCode;

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
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _syncDefaultSelectionForActiveTab();
  }

  Future<void> _fetchDashboardProjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/api/erp/project-dashboard-status/');

      // ✅ Correct parsing of DRF paginated response (`results` key)
      final List rawData = response.data is Map && response.data.containsKey('results')
          ? response.data['results']
          : (response.data is List ? response.data : []);

      setState(() {
        _allProjectsList = rawData;
        _syncDefaultSelectionForActiveTab();
      });
    } catch (e) {
      dev.log("❌ Dashboard sync network error: $e");
      _snack("Network Error: Could not fetch tracking list", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _syncDefaultSelectionForActiveTab() {
    final filtered = _getFilteredProjectsForCurrentTab();
    if (filtered.isNotEmpty) {
      bool selectionExists = filtered.any((e) => e['config_code'] == _selectedConfigCode);
      if (!selectionExists) {
        _selectedConfigCode = filtered.first['config_code'];
        _selectedProjectDetails = filtered.first;
      } else {
        _selectedProjectDetails = filtered.firstWhere((e) => e['config_code'] == _selectedConfigCode);
      }
    } else {
      _selectedConfigCode = null;
      _selectedProjectDetails = null;
    }
    setState(() {});
  }

  List<dynamic> _getFilteredProjectsForCurrentTab() {
    if (_tabController.index == 0) {
      return _allProjectsList.where((p) {
        final st = p['status'] ?? 'ACTIVE';
        return st == 'ACTIVE' || st == 'PENDING' || st == 'HOLD';
      }).toList();
    } else {
      return _allProjectsList.where((p) {
        final st = p['status'] ?? 'ACTIVE';
        return st == 'COMPLETED' || st == 'CANCEL';
      }).toList();
    }
  }

  Future<void> _updateProjectLifecycleStatus(int configId, String statusToken) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final response = await _apiClient.post(
        '/api/erp/project-dashboard-status/$configId/update-status/',
        data: {'status': statusToken},
      );

      if (response.statusCode == 200) {
        _snack("Status updated to $statusToken!", Colors.teal);
        await _fetchDashboardProjects();
      }
    } catch (e) {
      _snack("Failed to update status", Colors.redAccent);
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return const Color(0xFF10B981);
      case 'PENDING': return const Color(0xFFF59E0B);
      case 'HOLD': return const Color(0xFFEF4444);
      case 'COMPLETED': return const Color(0xFF3B82F6);
      case 'CANCEL': return const Color(0xFF64748B);
      default: return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1100;
    final filteredProjects = _getFilteredProjectsForCurrentTab();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "PRODUCTION CONFIGURATION TRACKING DASHBOARD",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _fetchDashboardProjects,
            tooltip: "Refresh List",
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.green.shade400,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          tabs: const [
            Tab(child: Text("ACTIVE PRODUCTION PIPELINE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            Tab(child: Text("ARCHIVED DISPATCHES & HISTORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2))
          : Row(
        children: [
          // LEFT SIDEBAR: Clean List Cards
          Expanded(
            flex: isDesktop ? 3 : 4,
            child: Container(
              color: Colors.white,
              child: filteredProjects.isEmpty
                  ? const Center(child: Text("No records found.", style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  bool isSelected = _selectedConfigCode == project['config_code'];
                  String rowStatus = project['status'] ?? 'ACTIVE';
                  Color rowStatusColor = _getStatusColor(rowStatus);

                  return Card(
                    elevation: isSelected ? 2 : 0,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project['customer_name'] ?? "UNASSIGNED CUSTOMER",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFF1E293B),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rowStatusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rowStatus,
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: rowStatusColor),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Config: ${project['config_code'] ?? '—'}",
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                            Text("Valuation: ₹ ${(project['latest_total_valuation'] ?? 0.0).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF115E59))),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedConfigCode = project['config_code'];
                          _selectedProjectDetails = project;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          // RIGHT PANEL: Clean Detail View
          if (isDesktop || _selectedProjectDetails != null)
            Expanded(
              flex: 7,
              child: _selectedProjectDetails == null
                  ? const Center(child: Text("Select a project configuration to view details.", style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : _buildDetailPanelView(),
            )
        ],
      ),
    );
  }

  Widget _buildDetailPanelView() {
    final details = _selectedProjectDetails!;

    // ✅ CRITICAL FIX: Direct mapping to `configured_items` from JSON response
    final List<dynamic> configuredItems = details['configured_items'] ?? [];

    final String currentStatus = details['status'] ?? 'ACTIVE';
    final int configId = details['id'];
    final bool isReadOnlyMode = _tabController.index == 1;

    final Color primaryStatusColor = _getStatusColor(currentStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Customer: ${details['customer_name'] ?? '—'}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryStatusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: primaryStatusColor, width: 0.8),
                              ),
                              child: Text(
                                currentStatus.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryStatusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Config Code: ${details['config_code'] ?? '—'}  |  Created: ${details['created_at_formatted'] ?? '—'}",
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      if (!isReadOnlyMode)
                        _isUpdatingStatus
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                            : Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentStatus,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              onChanged: (String? nextState) {
                                if (nextState != null && nextState != currentStatus) {
                                  _updateProjectLifecycleStatus(configId, nextState);
                                }
                              },
                              items: _statusChoices.map((Map<String, String> choice) {
                                return DropdownMenuItem<String>(
                                  value: choice['value'],
                                  child: Text(choice['label']!.toUpperCase(), style: const TextStyle(fontSize: 10)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 14),
                        label: const Text("PRINT METRICS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => BomPdfGeneratorHelper.printConfigurationInvoice(details),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // SUMMARY CARD
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RELEASED PRODUCTION ORDER METADATA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF115E59))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 32,
                    runSpacing: 16,
                    children: [
                      _buildMetaField("ORDER QUANTITY", "${details['configured_quantity'] ?? 0} Units"),
                      _buildMetaField("DELIVERY TIMELINE", details['delivery_timeline_formatted'] ?? '—'),
                      _buildMetaField("TOTAL VALUATION", "₹ ${(details['latest_total_valuation'] ?? 0.0).toStringAsFixed(2)}", isAccent: true),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text("ASSIGNED INCHARGES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildInchargeMiniField("PROJECT MANAGER", details['project_incharge'])),
                      Expanded(child: _buildInchargeMiniField("DESIGN ARCHITECT", details['design_incharge'])),
                      Expanded(child: _buildInchargeMiniField("PURCHASE CONTROLLER", details['purchase_incharge'])),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ITEMS TABLE CARD
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CONFIGURED ITEMS MATRIX (${configuredItems.length} ITEMS)",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  configuredItems.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("No items linked to this configuration.", style: TextStyle(fontSize: 11, color: Colors.grey))))
                      : Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
                        headingRowHeight: 34,
                        dataRowMaxHeight: 44,
                        dataRowMinHeight: 36,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Item No', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Description', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Raw Size', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Finishing Size', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Process Flow', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Qty', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Unit Price', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Cost', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        ],
                        rows: configuredItems.map((item) {
                          final String itemNo = item['item_no']?.toString() ?? '—';
                          final String desc = item['description']?.toString() ?? '—';
                          final String rawSize = item['raw_size']?.toString() ?? '—';
                          final String finSize = item['finishing_size']?.toString() ?? '—';
                          final String processFlow = item['process_flow']?.toString() ?? '—';
                          final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                          final double unitRate = double.tryParse(item['purchase_price']?.toString() ?? '0.0') ?? 0.0;
                          final double lineTotal = double.tryParse(item['total_cost']?.toString() ?? '0.0') ?? 0.0;

                          return DataRow(cells: [
                            DataCell(Text(itemNo, style: const TextStyle(fontSize: 10, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold))),
                            DataCell(Text(desc, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(rawSize, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(finSize, style: const TextStyle(fontSize: 10))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: Colors.orange.shade50,
                              child: Text(
                                processFlow.isNotEmpty ? processFlow : '—',
                                style: const TextStyle(fontSize: 9, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                              ),
                            )),
                            DataCell(Text("$qty", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            DataCell(Text("₹ ${unitRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10))),
                            DataCell(Text("₹ ${lineTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF115E59)))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(String title, String value, {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: isAccent ? 13 : 11, fontWeight: FontWeight.bold, color: isAccent ? const Color(0xFF115E59) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildInchargeMiniField(String role, String? officerName) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text((officerName != null && officerName.isNotEmpty) ? officerName : "Unassigned",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ],
        ),
      ],
    );
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }
}*/

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/bom_project_printting_service.dart';
import '../../../../injection.dart';
import '../../../transaction/presentation/pages/bom_project_final_config_page.dart';

class BomProjectHistoryPage extends StatefulWidget {
  const BomProjectHistoryPage({super.key});

  @override
  State<BomProjectHistoryPage> createState() => _BomProjectHistoryPageState();
}

class _BomProjectHistoryPageState extends State<BomProjectHistoryPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = sl<ApiClient>();
  late TabController _tabController;

  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  List<dynamic> _allProjectsList = [];

  Map<String, dynamic>? _selectedProjectDetails;
  String? _selectedConfigCode;

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
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _syncDefaultSelectionForActiveTab();
  }

  Future<void> _fetchDashboardProjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/api/erp/project-dashboard-status/');

      final List rawData = response.data is Map && response.data.containsKey('results')
          ? response.data['results']
          : (response.data is List ? response.data : []);

      setState(() {
        _allProjectsList = rawData;
        _syncDefaultSelectionForActiveTab();
      });
    } catch (e) {
      dev.log("❌ Dashboard sync network error: $e");
      _snack("Network Error: Could not fetch tracking list", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _syncDefaultSelectionForActiveTab() {
    final filtered = _getFilteredProjectsForCurrentTab();
    if (filtered.isNotEmpty) {
      bool selectionExists = filtered.any((e) => e['config_code'] == _selectedConfigCode);
      if (!selectionExists) {
        _selectedConfigCode = filtered.first['config_code'];
        _selectedProjectDetails = filtered.first;
      } else {
        _selectedProjectDetails = filtered.firstWhere((e) => e['config_code'] == _selectedConfigCode);
      }
    } else {
      _selectedConfigCode = null;
      _selectedProjectDetails = null;
    }
    setState(() {});
  }

  List<dynamic> _getFilteredProjectsForCurrentTab() {
    if (_tabController.index == 0) {
      return _allProjectsList.where((p) {
        final st = p['status'] ?? 'ACTIVE';
        return st == 'ACTIVE' || st == 'PENDING' || st == 'HOLD';
      }).toList();
    } else {
      return _allProjectsList.where((p) {
        final st = p['status'] ?? 'ACTIVE';
        return st == 'COMPLETED' || st == 'CANCEL';
      }).toList();
    }
  }

  Future<void> _updateProjectLifecycleStatus(int configId, String statusToken) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final response = await _apiClient.post(
        '/api/erp/project-dashboard-status/$configId/update-status/',
        data: {'status': statusToken},
      );

      if (response.statusCode == 200) {
        _snack("Status updated to $statusToken!", Colors.teal);
        await _fetchDashboardProjects();
      }
    } catch (e) {
      _snack("Failed to update status", Colors.redAccent);
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  // 🌟 NAVIGATE TO EDIT SCREEN WITH PRE-FILLED DATA
  Future<void> _navigateToEditScreen(Map<String, dynamic> projectDetails) async {
    final bool? isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectFinalConfigPage(initialData: projectDetails),
      ),
    );

    if (isUpdated == true) {
      _fetchDashboardProjects(); // Auto refresh dashboard list after saving updates
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return const Color(0xFF10B981);
      case 'PENDING': return const Color(0xFFF59E0B);
      case 'HOLD': return const Color(0xFFEF4444);
      case 'COMPLETED': return const Color(0xFF3B82F6);
      case 'CANCEL': return const Color(0xFF64748B);
      default: return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1100;
    final filteredProjects = _getFilteredProjectsForCurrentTab();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "PRODUCTION CONFIGURATION TRACKING DASHBOARD",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _fetchDashboardProjects,
            tooltip: "Refresh List",
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.green.shade400,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          tabs: const [
            Tab(child: Text("ACTIVE PRODUCTION PIPELINE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            Tab(child: Text("ARCHIVED DISPATCHES & HISTORY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2))
          : Row(
        children: [
          // LEFT SIDEBAR: Clean List Cards
          Expanded(
            flex: isDesktop ? 3 : 4,
            child: Container(
              color: Colors.white,
              child: filteredProjects.isEmpty
                  ? const Center(child: Text("No records found.", style: TextStyle(fontSize: 12, color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  bool isSelected = _selectedConfigCode == project['config_code'];
                  String rowStatus = project['status'] ?? 'ACTIVE';
                  Color rowStatusColor = _getStatusColor(rowStatus);

                  return Card(
                    elevation: isSelected ? 2 : 0,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0F4C81) : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project['customer_name'] ?? "UNASSIGNED CUSTOMER",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFF1E293B),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rowStatusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rowStatus,
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: rowStatusColor),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Config: ${project['config_code'] ?? '—'}",
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                            Text("Valuation: ₹ ${(project['latest_total_valuation'] ?? 0.0).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF115E59))),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedConfigCode = project['config_code'];
                          _selectedProjectDetails = project;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          // RIGHT PANEL: Clean Detail View
          if (isDesktop || _selectedProjectDetails != null)
            Expanded(
              flex: 7,
              child: _selectedProjectDetails == null
                  ? const Center(child: Text("Select a project configuration to view details.", style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : _buildDetailPanelView(),
            )
        ],
      ),
    );
  }

  Widget _buildDetailPanelView() {
    final details = _selectedProjectDetails!;

    final List<dynamic> configuredItems = details['configured_items'] ?? [];

    final String currentStatus = details['status'] ?? 'ACTIVE';
    final int configId = details['id'];
    final bool isReadOnlyMode = _tabController.index == 1;

    final Color primaryStatusColor = _getStatusColor(currentStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Customer: ${details['customer_name'] ?? '—'}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryStatusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: primaryStatusColor, width: 0.8),
                              ),
                              child: Text(
                                currentStatus.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryStatusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("Config Code: ${details['config_code'] ?? '—'}  |  Created: ${details['created_at_formatted'] ?? '—'}",
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      // 🌟 EDIT CONFIGURATION BUTTON
                      if (!isReadOnlyMode)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text("EDIT CONFIG", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          onPressed: () => _navigateToEditScreen(details),
                        ),
                      if (!isReadOnlyMode) const SizedBox(width: 8),

                      if (!isReadOnlyMode)
                        _isUpdatingStatus
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                            : Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentStatus,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              onChanged: (String? nextState) {
                                if (nextState != null && nextState != currentStatus) {
                                  _updateProjectLifecycleStatus(configId, nextState);
                                }
                              },
                              items: _statusChoices.map((Map<String, String> choice) {
                                return DropdownMenuItem<String>(
                                  value: choice['value'],
                                  child: Text(choice['label']!.toUpperCase(), style: const TextStyle(fontSize: 10)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 14),
                        label: const Text("PRINT METRICS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => BomPdfGeneratorHelper.printConfigurationInvoice(details),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // SUMMARY CARD
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RELEASED PRODUCTION ORDER METADATA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF115E59))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 32,
                    runSpacing: 16,
                    children: [
                      _buildMetaField("ORDER QUANTITY", "${details['configured_quantity'] ?? 0} Units"),
                      _buildMetaField("DELIVERY TIMELINE", details['delivery_timeline_formatted'] ?? '—'),
                      _buildMetaField("TOTAL VALUATION", "₹ ${(details['latest_total_valuation'] ?? 0.0).toStringAsFixed(2)}", isAccent: true),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text("ASSIGNED INCHARGES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildInchargeMiniField("PROJECT MANAGER", details['project_incharge'])),
                      Expanded(child: _buildInchargeMiniField("DESIGN ARCHITECT", details['design_incharge'])),
                      Expanded(child: _buildInchargeMiniField("PURCHASE CONTROLLER", details['purchase_incharge'])),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ITEMS TABLE CARD
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CONFIGURED ITEMS MATRIX (${configuredItems.length} ITEMS)",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  configuredItems.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("No items linked to this configuration.", style: TextStyle(fontSize: 11, color: Colors.grey))))
                      : Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
                        headingRowHeight: 34,
                        dataRowMaxHeight: 44,
                        dataRowMinHeight: 36,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Item No', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Description', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Raw Size', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Finishing Size', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Process Flow', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Qty', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Unit Price', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Cost', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold))),
                        ],
                        rows: configuredItems.map((item) {
                          final String itemNo = item['item_no']?.toString() ?? '—';
                          final String desc = item['description']?.toString() ?? '—';
                          final String rawSize = item['raw_size']?.toString() ?? '—';
                          final String finSize = item['finishing_size']?.toString() ?? '—';
                          final String processFlow = item['process_flow']?.toString() ?? '—';
                          final int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                          final double unitRate = double.tryParse(item['purchase_price']?.toString() ?? '0.0') ?? 0.0;
                          final double lineTotal = double.tryParse(item['total_cost']?.toString() ?? '0.0') ?? 0.0;

                          return DataRow(cells: [
                            DataCell(Text(itemNo, style: const TextStyle(fontSize: 10, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold))),
                            DataCell(Text(desc, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(rawSize, style: const TextStyle(fontSize: 10))),
                            DataCell(Text(finSize, style: const TextStyle(fontSize: 10))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: Colors.orange.shade50,
                              child: Text(
                                processFlow.isNotEmpty ? processFlow : '—',
                                style: const TextStyle(fontSize: 9, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                              ),
                            )),
                            DataCell(Text("$qty", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            DataCell(Text("₹ ${unitRate.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10))),
                            DataCell(Text("₹ ${lineTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF115E59)))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(String title, String value, {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: isAccent ? 13 : 11, fontWeight: FontWeight.bold, color: isAccent ? const Color(0xFF115E59) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildInchargeMiniField(String role, String? officerName) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text((officerName != null && officerName.isNotEmpty) ? officerName : "Unassigned",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ],
        ),
      ],
    );
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }
}