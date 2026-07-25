/*
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as dev;
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. CONFIGURATION DATA MODEL NODE
// ==========================================================================
class ConfigRowNode {
  int? materialId;
  String materialCode;
  String description;
  String materialType;
  String rawSize;
  String finishingSize;
  String processFlow;
  String uom;
  int quantity;
  double purchasePrice;
  double totalCost;

  ConfigRowNode({
    this.materialId,
    required this.materialCode,
    this.description = "",
    this.materialType = "—",
    this.rawSize = "—",
    this.finishingSize = "—",
    this.processFlow = "",
    this.uom = "PCS",
    this.quantity = 1,
    this.purchasePrice = 0.0,
    this.totalCost = 0.0,
  });

  void recalculateCost() {
    totalCost = quantity * purchasePrice;
  }
}

// ==========================================================================
// 2. MAIN WORKSPACE SURFACE (ProjectFinalConfigPage)
// ==========================================================================
class ProjectFinalConfigPage extends StatefulWidget {
  const ProjectFinalConfigPage({super.key});

  @override
  State<ProjectFinalConfigPage> createState() => _ProjectFinalConfigPageState();
}

class _ProjectFinalConfigPageState extends State<ProjectFinalConfigPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiClient _apiClient = sl<ApiClient>();

  // Headboard Controllers
  final _searchCodeCtrl = TextEditingController();
  final _configQtyCtrl = TextEditingController(text: "1");
  final _customerCtrl = TextEditingController();
  final _inchargeCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();

  // Date Handling States
  DateTime _selectedBomDate = DateTime.now();
  final _bomDateDisplayCtrl = TextEditingController();

  DateTime? _selectedTimelineDate;
  final _timelineDisplayCtrl = TextEditingController();

  String _detectedProjectName = "—";
  double _grandTotalCost = 0.0;

  // Cache Lists Matrix
  List<Map<String, dynamic>> _globalMaterialsPool = [];
  List<Map<String, dynamic>> _globalProjectsPool = [];
  final List<ConfigRowNode> _configGridRows = [];

  // Auxiliary Dropdown Pools
  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];

  bool _isFetchingMaster = false;
  bool _isSaving = false;
  int? _selectedProjectId;
  int? _activeTargetRowIndex;

  @override
  void initState() {
    super.initState();
    _updateDateDisplay();
    _loadGlobalMaterialsPool();
    _loadGlobalProjectsPool();
    _loadAuxiliaryPools();
  }

  @override
  void dispose() {
    _searchCodeCtrl.dispose();
    _configQtyCtrl.dispose();
    _customerCtrl.dispose();
    _inchargeCtrl.dispose();
    _designCtrl.dispose();
    _purchaseCtrl.dispose();
    _bomDateDisplayCtrl.dispose();
    _timelineDisplayCtrl.dispose();
    super.dispose();
  }

  void _updateDateDisplay() {
    _bomDateDisplayCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedBomDate);
    if (_selectedTimelineDate != null) {
      _timelineDisplayCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedTimelineDate!);
    }
  }

  Future<void> _selectBomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBomDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0F4C81)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBomDate) {
      setState(() {
        _selectedBomDate = picked;
        _updateDateDisplay();
      });
    }
  }

  Future<void> _pickDeliveryTimelineDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTimelineDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0F4C81)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTimelineDate = picked;
        _updateDateDisplay();
      });
    }
  }

  Future<void> _loadAuxiliaryPools() async {
    try {
      final uomsRes = await _apiClient.get('/api/erp/uoms/');
      final uomsList = (uomsRes.data is Map && uomsRes.data.containsKey('results')) ? uomsRes.data['results'] : uomsRes.data is List ? uomsRes.data : [];

      final typesRes = await _apiClient.get('/api/erp/material-types/');
      final typesList = (typesRes.data is Map && typesRes.data.containsKey('results')) ? typesRes.data['results'] : typesRes.data is List ? typesRes.data : [];

      if (mounted) {
        setState(() {
          _uomsList = List<Map<String, dynamic>>.from(uomsList);
          _typesList = List<Map<String, dynamic>>.from(typesList);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGlobalMaterialsPool() async {
    try {
      final res = await _apiClient.get('/api/erp/materials/');
      final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
      if (mounted) {
        setState(() { _globalMaterialsPool = List<Map<String, dynamic>>.from(d); });
      }
    } catch (e) {
      dev.log("Global Materials Sync Crash: $e");
    }
  }

  Future<void> _loadGlobalProjectsPool() async {
    try {
      final res = await _apiClient.get('/api/erp/projects/');
      final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
      if (mounted) {
        setState(() { _globalProjectsPool = List<Map<String, dynamic>>.from(d); });
      }
    } catch (e) {
      dev.log("Global Projects Sync Crash: $e");
    }
  }

  Future<void> _loadMasterBomTemplate() async {
    final code = _searchCodeCtrl.text.trim();
    final qty = int.tryParse(_configQtyCtrl.text.trim()) ?? 1;

    if (code.isEmpty && _selectedProjectId == null) {
      _snack("Please enter or select a valid Master Project first!", Colors.orange);
      return;
    }

    setState(() { _isFetchingMaster = true; });

    try {
      final res = await _apiClient.post('/api/erp/projects/fetch_bom_estimation/', data: {
        "project_code": code,
        "project_id": _selectedProjectId,
        "quantity": qty
      });

      if (res.statusCode == 200) {
        final resData = res.data as Map<String, dynamic>;
        _configGridRows.clear();

        setState(() {
          _searchCodeCtrl.text = resData['project_code'] ?? code;
          _detectedProjectName = resData['project_name'] ?? "—";
          List itemsList = resData['items'] ?? [];

          for (var item in itemsList) {
            _configGridRows.add(ConfigRowNode(
              materialId: item['material_id'],
              materialCode: item['material_code'] ?? "",
              description: item['description'] ?? "",
              materialType: item['material_type'] ?? "—",
              rawSize: item['raw_size'] ?? "—",
              finishingSize: item['finishing_size'] ?? "—",
              processFlow: item['process_flow'] ?? "",
              uom: item['uom'] ?? "PCS",
              quantity: item['quantity'] ?? 1,
              purchasePrice: double.tryParse(item['purchase_price'].toString()) ?? 0.0,
              totalCost: double.tryParse(item['total_cost'].toString()) ?? 0.0,
            ));
          }
          _updateSummaryCalculations();
        });
      }
    } catch (e) {
      _snack("Master BOM Code not found or Network Error!", Colors.red);
    } finally {
      if (mounted) {
        setState(() { _isFetchingMaster = false; });
      }
    }
  }

  void _updateSummaryCalculations() {
    double tempCalculatedSum = 0.0;
    for (var row in _configGridRows) {
      row.recalculateCost();
      tempCalculatedSum += row.totalCost;
    }
    setState(() { _grandTotalCost = tempCalculatedSum; });
  }

  void _appendManualRow() {
    if (_searchCodeCtrl.text.trim().isEmpty) {
      _snack("Validation Error: Please select a Master Project Template first!", Colors.redAccent);
      return;
    }
    setState(() {
      _configGridRows.add(ConfigRowNode(materialCode: ""));
      _updateSummaryCalculations();
    });
  }

  void _executeManualAutofill(int index, Map<String, dynamic> selectedMaterial) {
    if (index >= _configGridRows.length) return;
    setState(() {
      _configGridRows[index].materialId = selectedMaterial['id'];
      _configGridRows[index].materialCode = selectedMaterial['material_code'] ?? "";
      _configGridRows[index].description = selectedMaterial['name'] ?? "";
      _configGridRows[index].materialType = selectedMaterial['material_type_detail']?['name'] ?? "—";
      _configGridRows[index].rawSize = selectedMaterial['raw_size'] ?? "—";
      _configGridRows[index].finishingSize = selectedMaterial['finishing_size'] ?? "—";
      _configGridRows[index].uom = selectedMaterial['uom_detail']?['uom_name'] ?? "PCS";
      _configGridRows[index].purchasePrice = double.tryParse(selectedMaterial['purchase_price'].toString()) ?? 0.0;
      _updateSummaryCalculations();
    });
  }

  void _flushAllTransactionFormFields() {
    setState(() {
      _searchCodeCtrl.clear();
      _configQtyCtrl.text = "1";
      _customerCtrl.clear();
      _inchargeCtrl.clear();
      _designCtrl.clear();
      _purchaseCtrl.clear();
      _timelineDisplayCtrl.clear();
      _selectedTimelineDate = null;
      _selectedBomDate = DateTime.now();
      _updateDateDisplay();
      _detectedProjectName = "—";
      _grandTotalCost = 0.0;
      _configGridRows.clear();
      _selectedProjectId = null;
    });
  }

  Future<void> _dispatchFinalManifest() async {
    if (_customerCtrl.text.trim().isEmpty) {
      _snack("Validation Error: Customer Name is mandatory!", Colors.redAccent);
      return;
    }
    if (_selectedTimelineDate == null) {
      _snack("Validation Error: Please select a valid Delivery Timeline date!", Colors.redAccent);
      return;
    }
    if (_configGridRows.isEmpty) {
      _snack("Grid configuration matrix contains no items!", Colors.red);
      return;
    }
    if (_configGridRows.any((element) => element.materialId == null)) {
      _snack("Validation Error: Please resolve unselected material code rows.", Colors.red);
      return;
    }

    setState(() { _isSaving = true; });

    final payload = {
      "parent_project_code": _searchCodeCtrl.text.trim(),
      "customer_name": _customerCtrl.text.trim(),
      "project_incharge": _inchargeCtrl.text.trim(),
      "design_incharge": _designCtrl.text.trim(),
      "purchase_incharge": _purchaseCtrl.text.trim(),
      "bom_date": DateFormat('yyyy-MM-dd').format(_selectedBomDate),
      "delivery_timeline": DateFormat('yyyy-MM-dd').format(_selectedTimelineDate!),
      "final_configured_quantity": int.tryParse(_configQtyCtrl.text.trim()) ?? 1,
      "grand_total_estimation_cost": _grandTotalCost,
      "configured_items": _configGridRows.map((r) => {
        "material": r.materialId,
        "item_no": r.materialCode,
        "description": r.description,
        "raw_size": r.rawSize,
        "finishing_size": r.finishingSize,
        "process_flow": r.processFlow,
        "quantity": r.quantity,
        "purchase_price": r.purchasePrice,
        "total_cost": r.totalCost
      }).toList()
    };

    try {
      final res = await _apiClient.post('/api/erp/projects/save_final_configuration/', data: payload);
      if (res.statusCode == 201 || res.statusCode == 200) {
        _snack("🎉 Production Configuration Released & Saved Successfully!", Colors.green);
        _flushAllTransactionFormFields();
      } else {
        _snack("Server rejected the configuration manifest.", Colors.red);
      }
    } catch (e) {
      _snack("Failed to save configuration pipeline: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPrerequisiteFieldsLocked = _searchCodeCtrl.text.trim().isNotEmpty && _configQtyCtrl.text.trim().isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("PROJECT FINAL CONFIGURATION CALCULATOR", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),

      endDrawer: Drawer(
        width: screenWidth > 800 ? 460 : screenWidth * 0.85,
        shape: const RoundedRectangleBorder(),
        child: QuickAddMaterialDrawer(
          uomsList: _uomsList,
          typesList: _typesList,
          apiClient: _apiClient,
          onMaterialSaved: (newMaterial) {
            if (_activeTargetRowIndex != null) {
              _executeManualAutofill(_activeTargetRowIndex!, newMaterial);
            }
            _loadGlobalMaterialsPool();
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headboard Controls Card
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Master Project Search Autocomplete
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Autocomplete<Map<String, dynamic>>(
                            initialValue: TextEditingValue(text: _searchCodeCtrl.text),
                            displayStringForOption: (Map<String, dynamic> option) => option['project_code'] ?? '',
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) { return _globalProjectsPool; }
                              return _globalProjectsPool.where((Map<String, dynamic> option) {
                                final String code = (option['project_code'] ?? '').toString().toLowerCase();
                                final String name = (option['project_name'] ?? '').toString().toLowerCase();
                                final String query = textEditingValue.text.toLowerCase();
                                return code.contains(query) || name.contains(query);
                              });
                            },
                            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  labelText: "SEARCH MASTER PROJECT *",
                                  labelStyle: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  suffixIcon: Icon(Icons.arrow_drop_down, size: 16, color: Colors.blueGrey),
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  color: Colors.white,
                                  child: SizedBox(
                                    width: 400,
                                    height: 220,
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (BuildContext context, int index) {
                                        final Map<String, dynamic> option = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          title: Text("[${option['project_code'] ?? ''}]", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81), fontSize: 11)),
                                          subtitle: Text(option['project_name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            onSelected: (Map<String, dynamic> selection) {
                              setState(() {
                                _selectedProjectId = selection['id'];
                                _searchCodeCtrl.text = selection['project_code'] ?? "";
                                _detectedProjectName = selection['project_name'] ?? "—";
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Quantity Input
                      Expanded(
                        flex: 1,
                        child: _buildHeaderCompactField(_configQtyCtrl, "TARGET QTY *", isN: true, onChanged: (value) {
                          final trimmedVal = value.trim();
                          final parsedQty = int.tryParse(trimmedVal);
                          if (trimmedVal.isNotEmpty && parsedQty != null && parsedQty > 0 && _searchCodeCtrl.text.trim().isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && _configQtyCtrl.text.trim() == trimmedVal) {
                                _loadMasterBomTemplate();
                              }
                            });
                          }
                        }),
                      ),
                      const SizedBox(width: 8),

                      // Date Field (BOM Date)
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () => _selectBomDate(context),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("BOM DATE *", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    const SizedBox(height: 1),
                                    Text(_bomDateDisplayCtrl.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0F4C81)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Load & Re-Multiply Action Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0),
                        onPressed: _isFetchingMaster ? null : _loadMasterBomTemplate,
                        icon: const Icon(Icons.sync_alt, size: 14),
                        label: const Text("LOAD & RE-MULTIPLY BOM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Customer & Incharge Row Details
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildHeaderCompactField(_customerCtrl, "CUSTOMER NAME *")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderCompactField(_inchargeCtrl, "PROJECT INCHARGE")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderCompactField(_designCtrl, "DESIGN INCHARGE")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderCompactField(_purchaseCtrl, "PURCHASE INCHARGE")),
                      const SizedBox(width: 8),

                      // Delivery Timeline Picker Field
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () => _pickDeliveryTimelineDate(context),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("DELIVERY TIMELINE *", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    const SizedBox(height: 1),
                                    Text(
                                      _timelineDisplayCtrl.text.isEmpty ? "Select Date..." : _timelineDisplayCtrl.text,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _timelineDisplayCtrl.text.isEmpty ? Colors.grey.shade400 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.event_available, size: 13, color: Colors.blueGrey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text("IDENTIFIED MASTER TEMPLATE: $_detectedProjectName", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("LIVE TARGET COST ESTIMATION ADJUSTMENT SPREADSHEET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPrerequisiteFieldsLocked ? const Color(0xFF115E59) : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(),
                    elevation: 0,
                  ),
                  onPressed: isPrerequisiteFieldsLocked ? _appendManualRow : () => _snack("Validation Warning: Please select a Master Project Template first!", Colors.redAccent),
                  icon: const Icon(Icons.playlist_add, size: 14),
                  label: const Text("INSERT ADDITIONAL ITEM", style: TextStyle(fontSize: 9)),
                )
              ],
            ),
            const SizedBox(height: 8),

            // Data Grid View
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
                width: double.infinity,
                child: _isFetchingMaster
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowHeight: 32,
                      dataRowHeight: 45,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                      columns: const [
                        DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('SEARCH MATERIAL (CODE / NAME) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F4C81)))),
                        DataColumn(label: Text('MATERIAL NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('MATERIAL TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('RAW SIZE *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blue))),
                        DataColumn(label: Text('FINISHING SIZE *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blue))),
                        DataColumn(label: Text('PROCESS FLOW *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.deepOrange))),
                        DataColumn(label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('UNIT RATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('QTY *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.red))),
                        DataColumn(label: Text('TOTAL COST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                      ],
                      rows: List<DataRow>.generate(_configGridRows.length, (idx) {
                        final rowNode = _configGridRows[idx];
                        return DataRow(cells: [
                          DataCell(Text((idx + 1).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),

                          // Inline Material Autocomplete Search
                          DataCell(SizedBox(
                            width: 215,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Autocomplete<Map<String, dynamic>>(
                                    initialValue: TextEditingValue(text: rowNode.materialCode),
                                    displayStringForOption: (Map<String, dynamic> option) => option['material_code'] ?? '',
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (!isPrerequisiteFieldsLocked) {
                                        return const Iterable<Map<String, dynamic>>.empty();
                                      }
                                      if (textEditingValue.text.isEmpty) { return _globalMaterialsPool; }
                                      return _globalMaterialsPool.where((Map<String, dynamic> option) {
                                        final String code = (option['material_code'] ?? '').toString().toLowerCase();
                                        final String name = (option['name'] ?? '').toString().toLowerCase();
                                        final String query = textEditingValue.text.toLowerCase();
                                        return code.contains(query) || name.contains(query);
                                      });
                                    },
                                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                      return TextFormField(
                                        controller: textController,
                                        focusNode: focusNode,
                                        enabled: isPrerequisiteFieldsLocked,
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold),
                                        decoration: InputDecoration(
                                          hintText: !isPrerequisiteFieldsLocked ? "Locked - Set Master Template First" : "Search...",
                                          hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      );
                                    },
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0,
                                          color: Colors.white,
                                          child: SizedBox(
                                            width: 320,
                                            height: 220,
                                            child: ListView.separated(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                              itemBuilder: (BuildContext context, int index) {
                                                final Map<String, dynamic> option = options.elementAt(index);
                                                return ListTile(
                                                  dense: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  title: Text(option['material_code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                  subtitle: Text(option['name'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                                  onTap: () => onSelected(option),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    onSelected: (Map<String, dynamic> selection) {
                                      _executeManualAutofill(idx, selection);
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0F4C81)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: "Quick Add Material (Drawer)",
                                  onPressed: !isPrerequisiteFieldsLocked ? null : () {
                                    setState(() { _activeTargetRowIndex = idx; });
                                    _scaffoldKey.currentState?.openEndDrawer();
                                  },
                                ),
                              ],
                            ),
                          )),

                          DataCell(SizedBox(width: 140, child: TextFormField(initialValue: rowNode.description, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(border: InputBorder.none), onChanged: (v) => rowNode.description = v))),
                          DataCell(Text(rowNode.materialType, style: const TextStyle(fontSize: 10.5))),

                          DataCell(SizedBox(width: 80, child: TextFormField(initialValue: rowNode.rawSize, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(border: InputBorder.none), onChanged: (v) => rowNode.rawSize = v))),
                          DataCell(SizedBox(width: 80, child: TextFormField(initialValue: rowNode.finishingSize, style: const TextStyle(fontSize: 11), decoration: const InputDecoration(border: InputBorder.none), onChanged: (v) => rowNode.finishingSize = v))),

                          DataCell(SizedBox(
                            width: 130,
                            child: TextFormField(
                              initialValue: rowNode.processFlow,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              decoration: const InputDecoration(
                                hintText: "Type Process...",
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (value) { rowNode.processFlow = value; },
                            ),
                          )),

                          DataCell(Text(rowNode.uom, style: const TextStyle(fontSize: 10.5))),

                          DataCell(SizedBox(
                            width: 80,
                            child: TextFormField(
                              key: ValueKey('rate_${idx}_${rowNode.purchasePrice}'),
                              initialValue: rowNode.purchasePrice.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(prefixText: "₹ ", border: InputBorder.none),
                              onChanged: (v) {
                                rowNode.purchasePrice = double.tryParse(v) ?? 0.0;
                                _updateSummaryCalculations();
                              },
                            ),
                          )),

                          DataCell(SizedBox(
                            width: 50,
                            child: TextFormField(
                              initialValue: rowNode.quantity.toString(),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                              decoration: const InputDecoration(border: InputBorder.none),
                              onChanged: (v) {
                                rowNode.quantity = int.tryParse(v) ?? 1;
                                _updateSummaryCalculations();
                              },
                            ),
                          )),

                          DataCell(Text("₹ ${rowNode.totalCost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.indigo))),
                          DataCell(IconButton(icon: const Icon(Icons.cancel, size: 14, color: Colors.red), padding: EdgeInsets.zero, onPressed: () { setState(() { _configGridRows.removeAt(idx); _updateSummaryCalculations(); }); })),
                        ]);
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ESTIMATED PIPELINE MANIFEST COST VALUATION", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Text("₹ ${_grandTotalCost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: const RoundedRectangleBorder()),
                  onPressed: _isSaving ? null : _dispatchFinalManifest,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SAVE & RELEASE PRODUCTION CONFIGURATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCompactField(TextEditingController ctrl, String label, {bool isN = false, ValueChanged<String>? onChanged}) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(color: Colors.white),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isN ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0F4C81), width: 1.2)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }
}

// ==========================================================================
// 3. ISOLATED SLIDEOUT QUICK DRAWER ADD MATERIAL WIDGET
// ==========================================================================
class QuickAddMaterialDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> uomsList;
  final List<Map<String, dynamic>> typesList;
  final ApiClient apiClient;
  final Function(Map<String, dynamic>) onMaterialSaved;

  const QuickAddMaterialDrawer({
    super.key,
    required this.uomsList,
    required this.typesList,
    required this.apiClient,
    required this.onMaterialSaved,
  });

  @override
  State<QuickAddMaterialDrawer> createState() => _QuickAddMaterialDrawerState();
}

class _QuickAddMaterialDrawerState extends State<QuickAddMaterialDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _purCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: "1");

  String? _localPickedImagePath;
  Uint8List? _webImageMemoryBytes;
  final ImagePicker _picker = ImagePicker();

  int? _selectedUomId;
  int? _selectedTypeId;
  bool _isSavingMaterial = false;

  @override
  void initState() {
    super.initState();
    if (widget.uomsList.isNotEmpty) {
      _selectedUomId = int.tryParse(widget.uomsList.first['id'].toString());
    }
    if (widget.typesList.isNotEmpty) {
      _selectedTypeId = int.tryParse(widget.typesList.first['id'].toString());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _rawCtrl.dispose();
    _finCtrl.dispose();
    _purCtrl.dispose();
    _salesCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Add Materials", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B))),
                IconButton(onPressed: _isSavingMaterial ? null : () => Navigator.pop(context), icon: const Icon(Icons.close, size: 16))
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MATERIAL IMAGE ATTACHMENT (OPTIONAL)", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _isSavingMaterial ? null : () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          if (kIsWeb) {
                            final bytes = await image.readAsBytes();
                            setState(() { _webImageMemoryBytes = bytes; _localPickedImagePath = image.path; });
                          } else {
                            setState(() { _localPickedImagePath = image.path; });
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity, height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: (_localPickedImagePath != null || _webImageMemoryBytes != null) ? Colors.green.shade400 : Colors.grey.shade300),
                        ),
                        child: (_localPickedImagePath != null || _webImageMemoryBytes != null)
                            ? Stack(
                          children: [
                            Positioned.fill(
                                child: kIsWeb
                                    ? Image.memory(_webImageMemoryBytes!, fit: BoxFit.cover)
                                    : Image.file(File(_localPickedImagePath!), fit: BoxFit.cover)
                            ),
                            Container(color: Colors.black38),
                            const Center(child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text("IMAGE ATTACHED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ))
                          ],
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 18, color: Colors.blueGrey),
                            SizedBox(height: 6),
                            Text("CHOOSE OPTIONAL PRODUCT IMAGE FROM GALLERY POOL", style: TextStyle(fontSize: 8.5, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(child: _buildModalCompactField(_codeCtrl, "CODE *", readOnly: _isSavingMaterial)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_nameCtrl, "NAME *", readOnly: _isSavingMaterial)),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedUomId,
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                          decoration: _buildDropdownDecorationMatrix("UOM SPEC *"),
                          items: widget.uomsList.map<DropdownMenuItem<int>>((u) {
                            return DropdownMenuItem<int>(value: int.tryParse(u['id'].toString()), child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 10)));
                          }).toList(),
                          onChanged: _isSavingMaterial ? null : (v) => setState(() => _selectedUomId = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_unitsCtrl, "UNITS TOTAL *", isNumeric: true, readOnly: _isSavingMaterial)),
                    ]),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _selectedTypeId,
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                      decoration: _buildDropdownDecorationMatrix("MATERIAL TYPE MASTER REFERENCE *"),
                      items: widget.typesList.map<DropdownMenuItem<int>>((t) {
                        return DropdownMenuItem<int>(value: int.tryParse(t['id'].toString()), child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 10)));
                      }).toList(),
                      onChanged: _isSavingMaterial ? null : (v) => setState(() => _selectedTypeId = v),
                    ),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _buildModalCompactField(_rawCtrl, "RAW SIZE", readOnly: _isSavingMaterial)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_finCtrl, "FINISHING SIZE", readOnly: _isSavingMaterial)),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _buildModalCompactField(_purCtrl, "PURCHASE RATE *", isNumeric: true, readOnly: _isSavingMaterial)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_salesCtrl, "SALES RATE *", isNumeric: true, readOnly: _isSavingMaterial)),
                    ]),
                  ],
                ),
              ),
            ),

            const Divider(height: 20),
            SizedBox(
              width: double.infinity, height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0),
                onPressed: _isSavingMaterial ? null : () async {
                  if (_formKey.currentState!.validate() && _selectedUomId != null && _selectedTypeId != null) {
                    setState(() { _isSavingMaterial = true; });

                    try {
                      final Map<String, dynamic> textMultipartFields = {
                        "entry_date": DateTime.now().toString().split(" ")[0],
                        "material_code": _codeCtrl.text.trim().toUpperCase(),
                        "name": _nameCtrl.text.trim(),
                        "uom": _selectedUomId.toString(),
                        "units": _unitsCtrl.text.trim(),
                        "material_type": _selectedTypeId.toString(),
                        "purchase_price": _purCtrl.text.trim(),
                        "sales_price": _salesCtrl.text.trim(),
                        if (_rawCtrl.text.trim().isNotEmpty) "raw_size": _rawCtrl.text.trim(),
                        if (_finCtrl.text.trim().isNotEmpty) "finishing_size": _finCtrl.text.trim(),
                      };

                      final res = await widget.apiClient.postMultipart(
                        '/api/erp/materials/',
                        fields: textMultipartFields,
                        filePath: kIsWeb ? null : _localPickedImagePath,
                        webBytes: _webImageMemoryBytes,
                        fileKey: "image",
                      );

                      final Map<String, dynamic> generatedMaterialNode = Map<String, dynamic>.from(res.data);
                      widget.onMaterialSaved(generatedMaterialNode);

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() { _isSavingMaterial = false; });
                      }
                      dev.log("Drawer submission operation crash: $e");
                    }
                  }
                },
                child: _isSavingMaterial
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("SAVE MASTER MATERIAL & AUTOFILL ROW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModalCompactField(TextEditingController ctrl, String label, {bool isNumeric = false, bool readOnly = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey),
        filled: true,
        fillColor: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) && label.contains('*') ? 'Mandatory' : null,
    );
  }

  InputDecoration _buildDropdownDecorationMatrix(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as dev;
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. CONFIGURATION DATA MODEL NODE
// ==========================================================================
class ConfigRowNode {
  int? materialId;
  String materialCode;
  String description;
  String materialType;
  String rawSize;
  String finishingSize;
  String processFlow;
  String uom;
  int quantity;
  double purchasePrice;
  double totalCost;

  ConfigRowNode({
    this.materialId,
    required this.materialCode,
    this.description = "",
    this.materialType = "—",
    this.rawSize = "—",
    this.finishingSize = "—",
    this.processFlow = "",
    this.uom = "PCS",
    this.quantity = 1,
    this.purchasePrice = 0.0,
    this.totalCost = 0.0,
  });

  void recalculateCost() {
    totalCost = quantity * purchasePrice;
  }
}

// ==========================================================================
// 2. MAIN WORKSPACE SURFACE (ProjectFinalConfigPage)
// ==========================================================================
class ProjectFinalConfigPage extends StatefulWidget {
  final Map<String, dynamic>? initialData; // OPTIONAL DATA FOR EDIT MODE

  const ProjectFinalConfigPage({super.key, this.initialData});

  @override
  State<ProjectFinalConfigPage> createState() => _ProjectFinalConfigPageState();
}

class _ProjectFinalConfigPageState extends State<ProjectFinalConfigPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiClient _apiClient = sl<ApiClient>();

  // Headboard Controllers
  final _searchCodeCtrl = TextEditingController();
  final _configQtyCtrl = TextEditingController(text: "1");
  final _customerCtrl = TextEditingController();
  final _inchargeCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();

  // Date Handling States
  DateTime _selectedBomDate = DateTime.now();
  final _bomDateDisplayCtrl = TextEditingController();

  DateTime? _selectedTimelineDate;
  final _timelineDisplayCtrl = TextEditingController();

  String _detectedProjectName = "—";
  double _grandTotalCost = 0.0;

  // Cache Lists Matrix
  List<Map<String, dynamic>> _globalMaterialsPool = [];
  List<Map<String, dynamic>> _globalProjectsPool = [];
  final List<ConfigRowNode> _configGridRows = [];

  // Auxiliary Dropdown Pools
  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];

  bool _isFetchingMaster = false;
  bool _isSaving = false;
  int? _selectedProjectId;
  int? _activeTargetRowIndex;

  bool _isEditMode = false;
  int? _editingConfigId;

  @override
  void initState() {
    super.initState();
    _updateDateDisplay();
    _loadGlobalMaterialsPool();
    _loadGlobalProjectsPool();
    _loadAuxiliaryPools();

    // AUTO FETCH & POPULATE IF PASSED FROM DASHBOARD FOR EDITING
    if (widget.initialData != null) {
      _populateDataForEditing(widget.initialData!);
    }
  }

  @override
  void dispose() {
    _searchCodeCtrl.dispose();
    _configQtyCtrl.dispose();
    _customerCtrl.dispose();
    _inchargeCtrl.dispose();
    _designCtrl.dispose();
    _purchaseCtrl.dispose();
    _bomDateDisplayCtrl.dispose();
    _timelineDisplayCtrl.dispose();
    super.dispose();
  }

  void _populateDataForEditing(Map<String, dynamic> data) {
    setState(() {
      _isEditMode = true;
      _editingConfigId = data['id'];
      _searchCodeCtrl.text = data['parent_project_code'] ?? data['config_code'] ?? "";
      _detectedProjectName = data['project_name'] ?? "—";
      _configQtyCtrl.text = (data['configured_quantity'] ?? 1).toString();
      _customerCtrl.text = data['customer_name'] ?? "";
      _inchargeCtrl.text = data['project_incharge'] ?? "";
      _designCtrl.text = data['design_incharge'] ?? "";
      _purchaseCtrl.text = data['purchase_incharge'] ?? "";

      if (data['delivery_timeline'] != null) {
        _selectedTimelineDate = DateTime.tryParse(data['delivery_timeline'].toString());
      }
      if (data['bom_date'] != null) {
        _selectedBomDate = DateTime.tryParse(data['bom_date'].toString()) ?? DateTime.now();
      }
      _updateDateDisplay();

      // Populate Items Table
      _configGridRows.clear();
      List items = data['configured_items'] ?? data['items'] ?? [];
      for (var item in items) {
        int? matId = item['material'] ?? item['material_id'];
        _configGridRows.add(ConfigRowNode(
          materialId: matId,
          materialCode: item['item_no'] ?? item['material_code'] ?? "",
          description: item['description'] ?? "",
          materialType: item['material_type'] ?? "—",
          rawSize: item['raw_size'] ?? "—",
          finishingSize: item['finishing_size'] ?? "—",
          processFlow: item['process_flow'] ?? "",
          uom: item['uom'] ?? "PCS",
          quantity: item['quantity'] ?? 1,
          purchasePrice: double.tryParse(item['purchase_price'].toString()) ?? 0.0,
          totalCost: double.tryParse(item['total_cost'].toString()) ?? 0.0,
        ));
      }
      _updateSummaryCalculations();
    });
  }

  void _updateDateDisplay() {
    _bomDateDisplayCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedBomDate);
    if (_selectedTimelineDate != null) {
      _timelineDisplayCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedTimelineDate!);
    }
  }

  Future<void> _selectBomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBomDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0F4C81))),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedBomDate) {
      setState(() {
        _selectedBomDate = picked;
        _updateDateDisplay();
      });
    }
  }

  Future<void> _pickDeliveryTimelineDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTimelineDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0F4C81))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTimelineDate = picked;
        _updateDateDisplay();
      });
    }
  }

  Future<void> _loadAuxiliaryPools() async {
    try {
      final uomsRes = await _apiClient.get('/api/erp/uoms/');
      final uomsList = (uomsRes.data is Map && uomsRes.data.containsKey('results')) ? uomsRes.data['results'] : uomsRes.data is List ? uomsRes.data : [];

      final typesRes = await _apiClient.get('/api/erp/material-types/');
      final typesList = (typesRes.data is Map && typesRes.data.containsKey('results')) ? typesRes.data['results'] : typesRes.data is List ? typesRes.data : [];

      if (mounted) {
        setState(() {
          _uomsList = List<Map<String, dynamic>>.from(uomsList);
          _typesList = List<Map<String, dynamic>>.from(typesList);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGlobalMaterialsPool() async {
    try {
      final res = await _apiClient.get('/api/erp/materials/');
      final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
      if (mounted) setState(() { _globalMaterialsPool = List<Map<String, dynamic>>.from(d); });
    } catch (e) { dev.log("Global Materials Sync Crash: $e"); }
  }

  Future<void> _loadGlobalProjectsPool() async {
    try {
      final res = await _apiClient.get('/api/erp/projects/');
      final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
      if (mounted) setState(() { _globalProjectsPool = List<Map<String, dynamic>>.from(d); });
    } catch (e) { dev.log("Global Projects Sync Crash: $e"); }
  }

  Future<void> _loadMasterBomTemplate() async {
    final code = _searchCodeCtrl.text.trim();
    final qty = int.tryParse(_configQtyCtrl.text.trim()) ?? 1;

    if (code.isEmpty && _selectedProjectId == null) {
      _snack("Please enter or select a valid Master Project first!", Colors.orange);
      return;
    }

    setState(() { _isFetchingMaster = true; });

    try {
      final res = await _apiClient.post('/api/erp/projects/fetch_bom_estimation/', data: {
        "project_code": code,
        "project_id": _selectedProjectId,
        "quantity": qty
      });

      if (res.statusCode == 200) {
        final resData = res.data as Map<String, dynamic>;
        _configGridRows.clear();

        setState(() {
          _searchCodeCtrl.text = resData['project_code'] ?? code;
          _detectedProjectName = resData['project_name'] ?? "—";
          List itemsList = resData['items'] ?? [];

          for (var item in itemsList) {
            _configGridRows.add(ConfigRowNode(
              materialId: item['material_id'],
              materialCode: item['material_code'] ?? "",
              description: item['description'] ?? "",
              materialType: item['material_type'] ?? "—",
              rawSize: item['raw_size'] ?? "—",
              finishingSize: item['finishing_size'] ?? "—",
              processFlow: item['process_flow'] ?? "",
              uom: item['uom'] ?? "PCS",
              quantity: item['quantity'] ?? 1,
              purchasePrice: double.tryParse(item['purchase_price'].toString()) ?? 0.0,
              totalCost: double.tryParse(item['total_cost'].toString()) ?? 0.0,
            ));
          }
          _updateSummaryCalculations();
        });
      }
    } catch (e) {
      _snack("Master BOM Code not found or Network Error!", Colors.red);
    } finally {
      if (mounted) setState(() { _isFetchingMaster = false; });
    }
  }

  void _updateSummaryCalculations() {
    double tempCalculatedSum = 0.0;
    for (var row in _configGridRows) {
      row.recalculateCost();
      tempCalculatedSum += row.totalCost;
    }
    setState(() { _grandTotalCost = tempCalculatedSum; });
  }

  void _appendManualRow() {
    if (_searchCodeCtrl.text.trim().isEmpty) {
      _snack("Validation Error: Please select a Master Project Template first!", Colors.redAccent);
      return;
    }
    setState(() {
      _configGridRows.add(ConfigRowNode(materialCode: ""));
      _updateSummaryCalculations();
    });
  }

  // 🌟 ACCURATE AUTOFILL LOGIC FOR SELECTED MATERIAL
  void _executeManualAutofill(int index, Map<String, dynamic> selectedMaterial) {
    if (index >= _configGridRows.length) return;

    final String extractedType = selectedMaterial['material_type_detail']?['name'] ??
        selectedMaterial['material_type_name'] ??
        (selectedMaterial['material_type']?.toString() ?? "—");

    final String extractedUom = selectedMaterial['uom_detail']?['uom_name'] ??
        selectedMaterial['uom_name'] ??
        (selectedMaterial['uom']?.toString() ?? "PCS");

    setState(() {
      _configGridRows[index].materialId = int.tryParse(selectedMaterial['id'].toString());
      _configGridRows[index].materialCode = selectedMaterial['material_code'] ?? "";
      _configGridRows[index].description = selectedMaterial['name'] ?? selectedMaterial['description'] ?? "";
      _configGridRows[index].materialType = extractedType;
      _configGridRows[index].rawSize = selectedMaterial['raw_size'] ?? "—";
      _configGridRows[index].finishingSize = selectedMaterial['finishing_size'] ?? "—";
      _configGridRows[index].uom = extractedUom;
      _configGridRows[index].purchasePrice = double.tryParse(selectedMaterial['purchase_price'].toString()) ?? 0.0;
      _updateSummaryCalculations();
    });
  }

  void _flushAllTransactionFormFields() {
    setState(() {
      _searchCodeCtrl.clear();
      _configQtyCtrl.text = "1";
      _customerCtrl.clear();
      _inchargeCtrl.clear();
      _designCtrl.clear();
      _purchaseCtrl.clear();
      _timelineDisplayCtrl.clear();
      _selectedTimelineDate = null;
      _selectedBomDate = DateTime.now();
      _updateDateDisplay();
      _detectedProjectName = "—";
      _grandTotalCost = 0.0;
      _configGridRows.clear();
      _selectedProjectId = null;
      _isEditMode = false;
      _editingConfigId = null;
    });
  }

  Future<void> _dispatchFinalManifest() async {
    if (_customerCtrl.text.trim().isEmpty) {
      _snack("Validation Error: Customer Name is mandatory!", Colors.redAccent);
      return;
    }
    if (_selectedTimelineDate == null) {
      _snack("Validation Error: Please select a valid Delivery Timeline date!", Colors.redAccent);
      return;
    }
    if (_configGridRows.isEmpty) {
      _snack("Grid configuration matrix contains no items!", Colors.red);
      return;
    }
    if (_configGridRows.any((element) => element.materialId == null)) {
      _snack("Validation Error: Please resolve unselected material code rows.", Colors.red);
      return;
    }

    setState(() { _isSaving = true; });

    final payload = {
      "parent_project_code": _searchCodeCtrl.text.trim(),
      "customer_name": _customerCtrl.text.trim(),
      "project_incharge": _inchargeCtrl.text.trim(),
      "design_incharge": _designCtrl.text.trim(),
      "purchase_incharge": _purchaseCtrl.text.trim(),
      "bom_date": DateFormat('yyyy-MM-dd').format(_selectedBomDate),
      "delivery_timeline": DateFormat('yyyy-MM-dd').format(_selectedTimelineDate!),
      "final_configured_quantity": int.tryParse(_configQtyCtrl.text.trim()) ?? 1,
      "grand_total_estimation_cost": _grandTotalCost,
      "configured_items": _configGridRows.map((r) => {
        "material": r.materialId,
        "item_no": r.materialCode,
        "description": r.description,
        "raw_size": r.rawSize,
        "finishing_size": r.finishingSize,
        "process_flow": r.processFlow,
        "quantity": r.quantity,
        "purchase_price": r.purchasePrice,
        "total_cost": r.totalCost
      }).toList()
    };

    try {
      dynamic res;
      if (_isEditMode && _editingConfigId != null) {
        res = await _apiClient.put(
          '/api/erp/project-dashboard-status/$_editingConfigId/update_configuration/',
          data: payload,
        );
      } else {
        res = await _apiClient.post('/api/erp/projects/save_final_configuration/', data: payload);
      }

      if (res.statusCode == 201 || res.statusCode == 200) {
        _snack(_isEditMode ? "🎉 Production Configuration Updated Successfully!" : "🎉 Production Configuration Released Successfully!", Colors.green);
        if (_isEditMode) {
          Navigator.pop(context, true);
        } else {
          _flushAllTransactionFormFields();
        }
      } else {
        _snack("Server rejected the configuration manifest.", Colors.red);
      }
    } catch (e) {
      _snack("Failed to save configuration pipeline: $e", Colors.red);
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPrerequisiteFieldsLocked = _searchCodeCtrl.text.trim().isNotEmpty && _configQtyCtrl.text.trim().isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          tooltip: "Back to History",
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text(
          _isEditMode ? "EDIT PRODUCTION CONFIGURATION" : "PROJECT FINAL CONFIGURATION CALCULATOR",
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      endDrawer: Drawer(
        width: screenWidth > 800 ? 460 : screenWidth * 0.85,
        shape: const RoundedRectangleBorder(),
        child: QuickAddMaterialDrawer(
          uomsList: _uomsList,
          typesList: _typesList,
          apiClient: _apiClient,
          onMaterialSaved: (newMaterial) {
            if (_activeTargetRowIndex != null) {
              _executeManualAutofill(_activeTargetRowIndex!, newMaterial);
            }
            _loadGlobalMaterialsPool();
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headboard Controls Card
            Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Master Project Search Autocomplete
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Autocomplete<Map<String, dynamic>>(
                            initialValue: TextEditingValue(text: _searchCodeCtrl.text),
                            displayStringForOption: (Map<String, dynamic> option) => option['project_code'] ?? '',
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) { return _globalProjectsPool; }
                              return _globalProjectsPool.where((Map<String, dynamic> option) {
                                final String code = (option['project_code'] ?? '').toString().toLowerCase();
                                final String name = (option['project_name'] ?? '').toString().toLowerCase();
                                final String query = textEditingValue.text.toLowerCase();
                                return code.contains(query) || name.contains(query);
                              });
                            },
                            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  labelText: "SEARCH MASTER PROJECT *",
                                  labelStyle: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  suffixIcon: Icon(Icons.arrow_drop_down, size: 16, color: Colors.blueGrey),
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  color: Colors.white,
                                  child: SizedBox(
                                    width: 400, height: 220,
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                                      separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (BuildContext context, int index) {
                                        final Map<String, dynamic> option = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          title: Text("[${option['project_code'] ?? ''}]", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81), fontSize: 11)),
                                          subtitle: Text(option['project_name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            onSelected: (Map<String, dynamic> selection) {
                              setState(() {
                                _selectedProjectId = selection['id'];
                                _searchCodeCtrl.text = selection['project_code'] ?? "";
                                _detectedProjectName = selection['project_name'] ?? "—";
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        flex: 1,
                        child: _buildHeaderCompactField(_configQtyCtrl, "TARGET QTY *", isN: true, onChanged: (value) {
                          final trimmedVal = value.trim();
                          final parsedQty = int.tryParse(trimmedVal);
                          if (trimmedVal.isNotEmpty && parsedQty != null && parsedQty > 0 && _searchCodeCtrl.text.trim().isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && _configQtyCtrl.text.trim() == trimmedVal) {
                                _loadMasterBomTemplate();
                              }
                            });
                          }
                        }),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () => _selectBomDate(context),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("BOM DATE *", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    const SizedBox(height: 1),
                                    Text(_bomDateDisplayCtrl.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ],
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0F4C81)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0),
                        onPressed: _isFetchingMaster ? null : _loadMasterBomTemplate,
                        icon: const Icon(Icons.sync_alt, size: 14),
                        label: const Text("LOAD & RE-MULTIPLY BOM", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildHeaderCompactField(_customerCtrl, "CUSTOMER NAME *")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderCompactField(_inchargeCtrl, "PROJECT INCHARGE")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderCompactField(_designCtrl, "DESIGN INCHARGE")),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHeaderCompactField(_purchaseCtrl, "PURCHASE INCHARGE")),
                      const SizedBox(width: 8),

                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () => _pickDeliveryTimelineDate(context),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("DELIVERY TIMELINE *", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    const SizedBox(height: 1),
                                    Text(
                                      _timelineDisplayCtrl.text.isEmpty ? "Select Date..." : _timelineDisplayCtrl.text,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _timelineDisplayCtrl.text.isEmpty ? Colors.grey.shade400 : Colors.black87),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.event_available, size: 13, color: Colors.blueGrey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text("IDENTIFIED MASTER TEMPLATE: $_detectedProjectName", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Divider(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("LIVE TARGET COST ESTIMATION ADJUSTMENT SPREADSHEET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPrerequisiteFieldsLocked ? const Color(0xFF115E59) : Colors.grey.shade400,
                    foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0,
                  ),
                  onPressed: isPrerequisiteFieldsLocked ? _appendManualRow : () => _snack("Validation Warning: Please select a Master Project Template first!", Colors.redAccent),
                  icon: const Icon(Icons.playlist_add, size: 14),
                  label: const Text("INSERT ADDITIONAL ITEM", style: TextStyle(fontSize: 9)),
                )
              ],
            ),
            const SizedBox(height: 8),

            // Grid View Matrix
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
                width: double.infinity,
                child: _isFetchingMaster
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowHeight: 32, dataRowHeight: 45,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                      columns: const [
                        DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('SEARCH MATERIAL (CODE / NAME) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F4C81)))),
                        DataColumn(label: Text('MATERIAL NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('MATERIAL TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('RAW SIZE *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blue))),
                        DataColumn(label: Text('FINISHING SIZE *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blue))),
                        DataColumn(label: Text('PROCESS FLOW *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.deepOrange))),
                        DataColumn(label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('UNIT RATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('QTY *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.red))),
                        DataColumn(label: Text('TOTAL COST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                        DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                      ],
                      rows: List<DataRow>.generate(_configGridRows.length, (idx) {
                        final rowNode = _configGridRows[idx];

                        return DataRow(
                          key: ValueKey('row_${idx}_${rowNode.materialId}_${rowNode.materialCode}'),
                          cells: [
                            DataCell(Text((idx + 1).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),

                            // Inline Material Autocomplete Search Cell
                            DataCell(SizedBox(
                              width: 215,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Autocomplete<Map<String, dynamic>>(
                                      initialValue: TextEditingValue(text: rowNode.materialCode),
                                      displayStringForOption: (Map<String, dynamic> option) => option['material_code'] ?? '',
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (!isPrerequisiteFieldsLocked) return const Iterable<Map<String, dynamic>>.empty();
                                        if (textEditingValue.text.isEmpty) return _globalMaterialsPool;
                                        return _globalMaterialsPool.where((Map<String, dynamic> option) {
                                          final String code = (option['material_code'] ?? '').toString().toLowerCase();
                                          final String name = (option['name'] ?? '').toString().toLowerCase();
                                          final String query = textEditingValue.text.toLowerCase();
                                          return code.contains(query) || name.contains(query);
                                        });
                                      },
                                      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                        return TextFormField(
                                          controller: textController,
                                          focusNode: focusNode,
                                          enabled: isPrerequisiteFieldsLocked,
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            hintText: !isPrerequisiteFieldsLocked ? "Locked - Set Master Template First" : "Search...",
                                            hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                                            border: InputBorder.none,
                                            isDense: true,
                                          ),
                                        );
                                      },
                                      optionsViewBuilder: (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4.0,
                                            color: Colors.white,
                                            shape: const RoundedRectangleBorder(),
                                            child: SizedBox(
                                              width: 320, height: 220,
                                              child: ListView.separated(
                                                padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                                                separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                                itemBuilder: (BuildContext context, int index) {
                                                  final Map<String, dynamic> option = options.elementAt(index);
                                                  return ListTile(
                                                    dense: true,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    title: Text(option['material_code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                    subtitle: Text(option['name'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                                    onTap: () => onSelected(option),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      onSelected: (Map<String, dynamic> selection) {
                                        _executeManualAutofill(idx, selection);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0F4C81)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Quick Add Material (Drawer)",
                                    onPressed: !isPrerequisiteFieldsLocked ? null : () {
                                      setState(() { _activeTargetRowIndex = idx; });
                                      _scaffoldKey.currentState?.openEndDrawer();
                                    },
                                  ),
                                ],
                              ),
                            )),

                            // Description Cell
                            DataCell(SizedBox(
                              width: 140,
                              child: TextFormField(
                                key: ValueKey('desc_${idx}_${rowNode.description}'),
                                initialValue: rowNode.description,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) => rowNode.description = v,
                              ),
                            )),

                            // Material Type Cell
                            DataCell(Text(rowNode.materialType, style: const TextStyle(fontSize: 10.5))),

                            // Raw Size Cell
                            DataCell(SizedBox(
                              width: 80,
                              child: TextFormField(
                                key: ValueKey('raw_${idx}_${rowNode.rawSize}'),
                                initialValue: rowNode.rawSize,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) => rowNode.rawSize = v,
                              ),
                            )),

                            // Finishing Size Cell
                            DataCell(SizedBox(
                              width: 80,
                              child: TextFormField(
                                key: ValueKey('fin_${idx}_${rowNode.finishingSize}'),
                                initialValue: rowNode.finishingSize,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) => rowNode.finishingSize = v,
                              ),
                            )),

                            // Process Flow Cell
                            DataCell(SizedBox(
                              width: 130,
                              child: TextFormField(
                                key: ValueKey('proc_${idx}_${rowNode.processFlow}'),
                                initialValue: rowNode.processFlow,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                decoration: const InputDecoration(hintText: "Type Process...", hintStyle: TextStyle(fontSize: 9, color: Colors.grey), border: InputBorder.none, isDense: true),
                                onChanged: (v) => rowNode.processFlow = v,
                              ),
                            )),

                            // UOM Cell
                            DataCell(Text(rowNode.uom, style: const TextStyle(fontSize: 10.5))),

                            // Purchase Price Cell
                            DataCell(SizedBox(
                              width: 80,
                              child: TextFormField(
                                key: ValueKey('rate_${idx}_${rowNode.purchasePrice}'),
                                initialValue: rowNode.purchasePrice.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(prefixText: "₹ ", border: InputBorder.none),
                                onChanged: (v) {
                                  rowNode.purchasePrice = double.tryParse(v) ?? 0.0;
                                  _updateSummaryCalculations();
                                },
                              ),
                            )),

                            // Quantity Cell
                            DataCell(SizedBox(
                              width: 50,
                              child: TextFormField(
                                key: ValueKey('qty_${idx}_${rowNode.quantity}'),
                                initialValue: rowNode.quantity.toString(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) {
                                  rowNode.quantity = int.tryParse(v) ?? 1;
                                  _updateSummaryCalculations();
                                },
                              ),
                            )),

                            // Total Cost Cell
                            DataCell(Text("₹ ${rowNode.totalCost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.indigo))),

                            // Remove Action Cell
                            DataCell(IconButton(
                              icon: const Icon(Icons.cancel, size: 14, color: Colors.red),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _configGridRows.removeAt(idx);
                                  _updateSummaryCalculations();
                                });
                              },
                            )),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ESTIMATED PIPELINE MANIFEST COST VALUATION", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Text("₹ ${_grandTotalCost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: _isSaving ? null : _dispatchFinalManifest,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditMode ? "UPDATE EXISTING CONFIGURATION" : "SAVE & RELEASE PRODUCTION CONFIGURATION", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCompactField(TextEditingController ctrl, String label, {bool isN = false, ValueChanged<String>? onChanged}) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(color: Colors.white),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isN ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0F4C81), width: 1.2)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }
}

// ==========================================================================
// 3. ISOLATED SLIDEOUT QUICK DRAWER ADD MATERIAL WIDGET
// ==========================================================================
class QuickAddMaterialDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> uomsList;
  final List<Map<String, dynamic>> typesList;
  final ApiClient apiClient;
  final Function(Map<String, dynamic>) onMaterialSaved;

  const QuickAddMaterialDrawer({
    super.key,
    required this.uomsList,
    required this.typesList,
    required this.apiClient,
    required this.onMaterialSaved,
  });

  @override
  State<QuickAddMaterialDrawer> createState() => _QuickAddMaterialDrawerState();
}

class _QuickAddMaterialDrawerState extends State<QuickAddMaterialDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _purCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: "1");

  String? _localPickedImagePath;
  Uint8List? _webImageMemoryBytes;
  final ImagePicker _picker = ImagePicker();

  int? _selectedUomId;
  int? _selectedTypeId;
  bool _isSavingMaterial = false;

  @override
  void initState() {
    super.initState();
    if (widget.uomsList.isNotEmpty) {
      _selectedUomId = int.tryParse(widget.uomsList.first['id'].toString());
    }
    if (widget.typesList.isNotEmpty) {
      _selectedTypeId = int.tryParse(widget.typesList.first['id'].toString());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _rawCtrl.dispose();
    _finCtrl.dispose();
    _purCtrl.dispose();
    _salesCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Add Materials", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B))),
                IconButton(onPressed: _isSavingMaterial ? null : () => Navigator.pop(context), icon: const Icon(Icons.close, size: 16))
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MATERIAL IMAGE ATTACHMENT (OPTIONAL)", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _isSavingMaterial ? null : () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          if (kIsWeb) {
                            final bytes = await image.readAsBytes();
                            setState(() { _webImageMemoryBytes = bytes; _localPickedImagePath = image.path; });
                          } else {
                            setState(() { _localPickedImagePath = image.path; });
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity, height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: (_localPickedImagePath != null || _webImageMemoryBytes != null) ? Colors.green.shade400 : Colors.grey.shade300),
                        ),
                        child: (_localPickedImagePath != null || _webImageMemoryBytes != null)
                            ? Stack(
                          children: [
                            Positioned.fill(
                                child: kIsWeb
                                    ? Image.memory(_webImageMemoryBytes!, fit: BoxFit.cover)
                                    : Image.file(File(_localPickedImagePath!), fit: BoxFit.cover)
                            ),
                            Container(color: Colors.black38),
                            const Center(child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text("IMAGE ATTACHED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ))
                          ],
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 18, color: Colors.blueGrey),
                            SizedBox(height: 6),
                            Text("CHOOSE OPTIONAL PRODUCT IMAGE FROM GALLERY POOL", style: TextStyle(fontSize: 8.5, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(child: _buildModalCompactField(_codeCtrl, "CODE *", readOnly: _isSavingMaterial)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_nameCtrl, "NAME *", readOnly: _isSavingMaterial)),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedUomId,
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                          decoration: _buildDropdownDecorationMatrix("UOM SPEC *"),
                          items: widget.uomsList.map<DropdownMenuItem<int>>((u) {
                            return DropdownMenuItem<int>(value: int.tryParse(u['id'].toString()), child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 10)));
                          }).toList(),
                          onChanged: _isSavingMaterial ? null : (v) => setState(() => _selectedUomId = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_unitsCtrl, "UNITS TOTAL *", isNumeric: true, readOnly: _isSavingMaterial)),
                    ]),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _selectedTypeId,
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                      decoration: _buildDropdownDecorationMatrix("MATERIAL TYPE MASTER REFERENCE *"),
                      items: widget.typesList.map<DropdownMenuItem<int>>((t) {
                        return DropdownMenuItem<int>(value: int.tryParse(t['id'].toString()), child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 10)));
                      }).toList(),
                      onChanged: _isSavingMaterial ? null : (v) => setState(() => _selectedTypeId = v),
                    ),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _buildModalCompactField(_rawCtrl, "RAW SIZE", readOnly: _isSavingMaterial)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_finCtrl, "FINISHING SIZE", readOnly: _isSavingMaterial)),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _buildModalCompactField(_purCtrl, "PURCHASE RATE *", isNumeric: true, readOnly: _isSavingMaterial)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildModalCompactField(_salesCtrl, "SALES RATE *", isNumeric: true, readOnly: _isSavingMaterial)),
                    ]),
                  ],
                ),
              ),
            ),

            const Divider(height: 20),
            SizedBox(
              width: double.infinity, height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0),
                onPressed: _isSavingMaterial ? null : () async {
                  if (_formKey.currentState!.validate() && _selectedUomId != null && _selectedTypeId != null) {
                    setState(() { _isSavingMaterial = true; });

                    try {
                      final Map<String, dynamic> textMultipartFields = {
                        "entry_date": DateTime.now().toString().split(" ")[0],
                        "material_code": _codeCtrl.text.trim().toUpperCase(),
                        "name": _nameCtrl.text.trim(),
                        "uom": _selectedUomId.toString(),
                        "units": _unitsCtrl.text.trim(),
                        "material_type": _selectedTypeId.toString(),
                        "purchase_price": _purCtrl.text.trim(),
                        "sales_price": _salesCtrl.text.trim(),
                        if (_rawCtrl.text.trim().isNotEmpty) "raw_size": _rawCtrl.text.trim(),
                        if (_finCtrl.text.trim().isNotEmpty) "finishing_size": _finCtrl.text.trim(),
                      };

                      final res = await widget.apiClient.postMultipart(
                        '/api/erp/materials/',
                        fields: textMultipartFields,
                        filePath: kIsWeb ? null : _localPickedImagePath,
                        webBytes: _webImageMemoryBytes,
                        fileKey: "image",
                      );

                      final Map<String, dynamic> generatedMaterialNode = Map<String, dynamic>.from(res.data);
                      widget.onMaterialSaved(generatedMaterialNode);

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() { _isSavingMaterial = false; });
                      }
                      dev.log("Drawer submission operation crash: $e");
                    }
                  }
                },
                child: _isSavingMaterial
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("SAVE MASTER MATERIAL & AUTOFILL ROW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModalCompactField(TextEditingController ctrl, String label, {bool isNumeric = false, bool readOnly = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey),
        filled: true,
        fillColor: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) && label.contains('*') ? 'Mandatory' : null,
    );
  }

  InputDecoration _buildDropdownDecorationMatrix(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    );
  }
}