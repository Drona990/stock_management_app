/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA GRID STRUCTURE MAPPING NODE
// ==========================================================================
class TableRowNode {
  String? selectedMaterialCode;
  int? materialId;
  String description;
  String materialType;
  String rawSize;
  String finishingSize;
  String processFlow;
  String uom;
  int quantity;

  TableRowNode({
    this.selectedMaterialCode, this.materialId, this.description = "—", this.materialType = "—",
    this.rawSize = "—", this.finishingSize = "—", this.processFlow = "LASER CUTTING",
    this.uom = "PCS", this.quantity = 1,
  });
}

// ==========================================================================
// 2. PROJECT TRANSACTION BATCH BLoC & REPOSITORY LAYER
// ==========================================================================
class ProjectBomRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<Map<String, dynamic>>> getAvailableMaterialsPool() async {
    final res = await apiClient.get('/api/erp/materials/');
    final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<void> saveProjectBomManifest(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/erp/projects/', data: payload);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Transaction dispatch server failure");
    }
  }
}

abstract class BomEvent {}
class InitializeBomPool extends BomEvent {}
class SubmitBomBatch extends BomEvent { final Map<String, dynamic> payload; final VoidCallback? onSuccess; SubmitBomBatch(this.payload, {this.onSuccess}); }

abstract class BomState {}
class BomInit extends BomState {}
class BomSyncing extends BomState {}
class BomPoolLoaded extends BomState { final List<Map<String, dynamic>> items; BomPoolLoaded(this.items); }
class BomSyncError extends BomState { final String msg; BomSyncError(this.msg); }

class ProjectBomBloc extends Bloc<BomEvent, BomState> {
  final ProjectBomRepository repo;
  ProjectBomBloc(this.repo) : super(BomInit()) {
    on<InitializeBomPool>((e, emit) async {
      emit(BomSyncing());
      try {
        final data = await repo.getAvailableMaterialsPool();
        emit(BomPoolLoaded(data));
      } catch (err) { emit(BomSyncError(err.toString())); }
    });
    on<SubmitBomBatch>((e, emit) async {
      try {
        await repo.saveProjectBomManifest(e.payload);
        if (e.onSuccess != null) e.onSuccess!();
        add(InitializeBomPool());
      } catch (err) { emit(BomSyncError("Batch Submission Failed")); }
    });
  }
}

// ==========================================================================
// 3. MAIN WORKFLOW VISUAL CANVAS SURFACE
// ==========================================================================
class ProjectBomPage extends StatefulWidget {
  const ProjectBomPage({super.key});
  @override
  State<ProjectBomPage> createState() => _ProjectBomPageState();
}

class _ProjectBomPageState extends State<ProjectBomPage> {
  List<Map<String, dynamic>> _liveMaterialsMasterPool = [];
  final List<TableRowNode> _gridRowsList = [];

  final _projNameCtrl = TextEditingController(text: "INNER FEEDER NEW MODEL");
  final _projCodeCtrl = TextEditingController(text: "AUTO GENERATED"); // Set as structural informational placeholder
  final _qtyCtrl = TextEditingController(text: "1");
  final _customerCtrl = TextEditingController(text: "UNIT -8 SUPRAJIT");
  final _inchargeCtrl = TextEditingController(text: "AMIT SHARMA");
  final _timelineCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _designCtrl = TextEditingController(text: "R&D DESIGN DEPT");
  final _purchaseCtrl = TextEditingController(text: "VIVEK KUMAR");

  @override
  void initState() {
    super.initState();
    _appendBlankEntryRow();
  }

  void _appendBlankEntryRow() {
    setState(() { _gridRowsList.add(TableRowNode()); });
  }

  void _executeCellReactiveAutofill(int index, String? materialCode) {
    if (materialCode == null) return;
    final matchingMaterialObject = _liveMaterialsMasterPool.firstWhere(
          (m) => m['material_code'] == materialCode,
      orElse: () => {},
    );
    if (matchingMaterialObject.isEmpty) return;

    setState(() {
      _gridRowsList[index].selectedMaterialCode = materialCode;
      _gridRowsList[index].materialId = int.tryParse(matchingMaterialObject['id'].toString());
      _gridRowsList[index].description = matchingMaterialObject['name'] ?? "—";
      _gridRowsList[index].materialType = matchingMaterialObject['material_type_detail']?['name'] ?? "—";
      _gridRowsList[index].rawSize = matchingMaterialObject['raw_size'] ?? "—";
      _gridRowsList[index].finishingSize = matchingMaterialObject['finishing_size'] ?? "—";
      _gridRowsList[index].uom = matchingMaterialObject['uom_detail']?['uom_name'] ?? "—";
    });
  }

  void _flushAllTransactionFormFields() {
    setState(() {
      _projNameCtrl.clear();
      _projCodeCtrl.text = "AUTO GENERATED";
      _qtyCtrl.text = "1";
      _customerCtrl.clear(); _inchargeCtrl.clear();
      _timelineCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _designCtrl.clear(); _purchaseCtrl.clear();
      _gridRowsList.clear();
      _appendBlankEntryRow();
    });
  }

  Future<void> _pickDeliveryTimelineDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _timelineCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectBomBloc(ProjectBomRepository())..add(InitializeBomPool()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<ProjectBomBloc, BomState>(
            listener: (context, state) {
              if (state is BomPoolLoaded) {
                _liveMaterialsMasterPool = state.items;
              }
            },
            builder: (context, state) {
              final bomBlocInstance = BlocProvider.of<ProjectBomBloc>(context);

              if (state is BomSyncing && _liveMaterialsMasterPool.isEmpty) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PROJECT TRANSACTIONS MANAGER - BILL OF MATERIALS (BOM)",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B), letterSpacing: 0.3)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(children: [
                          _buildGridCellHeader("PROJECT NAME", _projNameCtrl, f: 3),
                          _buildGridCellHeader("PROJECT CODE", _projCodeCtrl, readOnly: true), // Formatted Native Read-Only Layer
                          _buildGridCellHeader("QTY", _qtyCtrl, isN: true)
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          _buildGridCellHeader("CUSTOMER", _customerCtrl, f: 2),
                          _buildGridCellHeader("PROJECT INCHARGE", _inchargeCtrl),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => _pickDeliveryTimelineDate(context),
                                child: Container(
                                  height: 30, decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200)), padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Row(
                                    children: [
                                      const Text("DELIVERY TIMELINE: ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                      Expanded(child: Text(_timelineCtrl.text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))),
                                      const Icon(Icons.calendar_today, size: 12, color: Colors.blueGrey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [_buildGridCellHeader("DESIGN INCHARGE", _designCtrl), _buildGridCellHeader("PURCHASE INCHARGE", _purchaseCtrl), Expanded(child: const SizedBox())]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("PRODUCTION TRANSACTION SPECIFICATION SHEET DATA MATRIX", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0),
                        onPressed: _appendBlankEntryRow, icon: const Icon(Icons.add, size: 12), label: const Text("APPEND EXPANDABLE ROW", style: TextStyle(fontSize: 9)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowHeight: 30, dataRowHeight: 42,
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
                            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                            columns: const [
                              DataColumn(label: Text('SI.NO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('ITEM NO. (SELECT CODE) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F4C81)))),
                              DataColumn(label: Text('DESCRIPTION SPECIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('MATERIAL TYPE (AUTOFILL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('RAW SIZE (AUTOFILL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('FINISHING SIZE (AUTOFILL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('PROCESS FLOW *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.deepOrange))),
                              DataColumn(label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('QTY. *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              DataColumn(label: Text('WIPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                            ],
                            rows: List<DataRow>.generate(_gridRowsList.length, (idx) {
                              final node = _gridRowsList[idx];
                              return DataRow(cells: [
                                DataCell(Text((idx + 1).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),

                                DataCell(SizedBox(
                                  width: 110,
                                  child: DropdownButtonFormField<String>(
                                    value: _liveMaterialsMasterPool.any((element) => element['material_code'] == node.selectedMaterialCode) ? node.selectedMaterialCode : null,
                                    hint: const Text("Select", style: TextStyle(fontSize: 10.5)),
                                    isDense: true, decoration: const InputDecoration(border: InputBorder.none), style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold),
                                    items: _liveMaterialsMasterPool.map<DropdownMenuItem<String>>((m) {
                                      String code = m['material_code'] ?? '';
                                      return DropdownMenuItem<String>(value: code, child: Text(code, style: const TextStyle(fontSize: 10.5)));
                                    }).toList(),
                                    onChanged: (val) => _executeCellReactiveAutofill(idx, val),
                                  ),
                                )),

                                DataCell(Text(node.description, style: const TextStyle(fontSize: 10.5, color: Colors.black87))),
                                DataCell(Text(node.materialType, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                                DataCell(Text(node.rawSize, style: const TextStyle(fontSize: 10.5))),
                                DataCell(Text(node.finishingSize, style: const TextStyle(fontSize: 10.5))),

                                DataCell(SizedBox(
                                  width: 130,
                                  child: DropdownButtonFormField<String>(
                                    value: node.processFlow, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    items: const [
                                      DropdownMenuItem(value: "LASER CUTTING", child: Text("LASER CUTTING", style: TextStyle(fontSize: 10))),
                                      DropdownMenuItem(value: "MECHANICAL", child: Text("MECHANICAL", style: TextStyle(fontSize: 10))),
                                      DropdownMenuItem(value: "PNEUMATIC", child: Text("PNEUMATIC", style: TextStyle(fontSize: 10))),
                                      DropdownMenuItem(value: "EN8 ASSEMBLY", child: Text("EN8 ASSEMBLY", style: TextStyle(fontSize: 10))),
                                    ],
                                    onChanged: (v) => setState(() { _gridRowsList[idx].processFlow = v!; }),
                                  ),
                                )),

                                DataCell(Text(node.uom, style: const TextStyle(fontSize: 10.5))),
                                DataCell(SizedBox(width: 40, child: TextFormField(initialValue: node.quantity.toString(), keyboardType: TextInputType.number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none), onChanged: (v) => node.quantity = int.tryParse(v) ?? 1))),
                                DataCell(IconButton(icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: Colors.red), padding: EdgeInsets.zero, onPressed: () { setState(() { _gridRowsList.removeAt(idx); }); })),
                              ]);
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: const RoundedRectangleBorder(), elevation: 0),
                      onPressed: () {
                        if (_gridRowsList.any((element) => element.materialId == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validation Error: Please select valid material codes across rows matrices."), backgroundColor: Colors.red));
                          return;
                        }

                        final Map<String, dynamic> requestPayloadBOM = {
                          "project_name": _projNameCtrl.text.trim(),
                          "project_code": null, // Backend auto-generates this sequentially
                          "quantity": int.tryParse(_qtyCtrl.text.trim()) ?? 1,
                          "customer_name": _customerCtrl.text.trim(),
                          "project_incharge": _inchargeCtrl.text.trim(),
                          "delivery_timeline": _timelineCtrl.text.trim(), // yyyy-MM-dd clean string formatting mapped
                          "design_incharge": _designCtrl.text.trim(),
                          "purchase_incharge": _purchaseCtrl.text.trim(),
                          "items": _gridRowsList.map((row) => {
                            "material": row.materialId,
                            "item_no": row.selectedMaterialCode,
                            "description": row.description,
                            "process_flow": row.processFlow,
                            "quantity": row.quantity
                          }).toList()
                        };

                        bomBlocInstance.add(SubmitBomBatch(
                            requestPayloadBOM,
                            onSuccess: () {
                              _flushAllTransactionFormFields();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BOM Manifest Saved & Synced into ERP Pipeline Successfully!"), backgroundColor: Colors.green));
                            }
                        ));
                      },
                      child: const Text("SAVE PROJECT BOM BATCH TRANSACTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridCellHeader(String label, TextEditingController ctrl, {int f = 1, bool isN = false, bool readOnly = false}) {
    return Expanded(
      flex: f,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 30, decoration: BoxDecoration(color: readOnly ? Colors.grey.shade100 : Colors.white, border: Border.all(color: Colors.grey.shade200)), padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Text("$label: ", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Expanded(child: TextField(controller: ctrl, readOnly: readOnly, keyboardType: isN ? TextInputType.number : TextInputType.text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: readOnly ? Colors.grey : Colors.black87), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(bottom: 8)))),
            ],
          ),
        ),
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA GRID STRUCTURE MAPPING NODE
// ==========================================================================
class TableRowNode {
  String? selectedMaterialCode;
  int? materialId;
  String description;
  String materialType;
  String rawSize;
  String finishingSize;
  String processFlow;
  String uom;
  int quantity;

  TableRowNode({
    this.selectedMaterialCode,
    this.materialId,
    this.description = "—",
    this.materialType = "—",
    this.rawSize = "—",
    this.finishingSize = "—",
    this.processFlow = "",
    this.uom = "PCS",
    this.quantity = 1,
  });
}

// ==========================================================================
// 2. PROJECT TRANSACTION BATCH BLoC & REPOSITORY LAYER
// ==========================================================================
class ProjectBomRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<Map<String, dynamic>>> getAvailableMaterialsPool() async {
    final res = await apiClient.get('/api/erp/materials/');
    final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<void> saveProjectBomManifest(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/erp/projects/', data: payload);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Transaction dispatch server failure");
    }
  }
}

abstract class BomEvent {}
class InitializeBomPool extends BomEvent {}
class SubmitBomBatch extends BomEvent {
  final Map<String, dynamic> payload;
  final VoidCallback? onSuccess;
  SubmitBomBatch(this.payload, {this.onSuccess});
}

abstract class BomState {}
class BomInit extends BomState {}
class BomSyncing extends BomState {}
class BomPoolLoaded extends BomState {
  final List<Map<String, dynamic>> items;
  BomPoolLoaded(this.items);
}
class BomSyncError extends BomState {
  final String msg;
  BomSyncError(this.msg);
}

class ProjectBomBloc extends Bloc<BomEvent, BomState> {
  final ProjectBomRepository repo;
  ProjectBomBloc(this.repo) : super(BomInit()) {
    on<InitializeBomPool>((e, emit) async {
      emit(BomSyncing());
      try {
        final data = await repo.getAvailableMaterialsPool();
        emit(BomPoolLoaded(data));
      } catch (err) {
        emit(BomSyncError(err.toString()));
      }
    });
    on<SubmitBomBatch>((e, emit) async {
      try {
        await repo.saveProjectBomManifest(e.payload);
        if (e.onSuccess != null) e.onSuccess!();
        add(InitializeBomPool());
      } catch (err) {
        emit(BomSyncError("Batch Submission Failed"));
      }
    });
  }
}

// ==========================================================================
// 3. MAIN WORKFLOW VISUAL CANVAS SURFACE
// ==========================================================================
class ProjectBomPage extends StatefulWidget {
  const ProjectBomPage({super.key});
  @override
  State<ProjectBomPage> createState() => _ProjectBomPageState();
}

class _ProjectBomPageState extends State<ProjectBomPage> {
  List<Map<String, dynamic>> _liveMaterialsMasterPool = [];
  final List<TableRowNode> _gridRowsList = [];

  final _projNameCtrl = TextEditingController();
  final _projCodeCtrl = TextEditingController(text: "AUTO GENERATED");
  final _qtyCtrl = TextEditingController(text: "1");
  final _customerCtrl = TextEditingController();
  final _inchargeCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appendBlankEntryRow();
  }

  void _appendBlankEntryRow() {
    setState(() {
      _gridRowsList.add(TableRowNode());
    });
  }

  // ✅ FIXED: Pure Map Object tracking pipeline parameter signature to ensure materialId is NEVER null
  void _executeCellReactiveAutofill(int index, Map<String, dynamic> selectedMaterial) {
    setState(() {
      _gridRowsList[index].selectedMaterialCode = selectedMaterial['material_code'];
      _gridRowsList[index].materialId = int.tryParse(selectedMaterial['id'].toString());
      _gridRowsList[index].description = selectedMaterial['name'] ?? "—";
      _gridRowsList[index].materialType = selectedMaterial['material_type_detail']?['name'] ?? "—";
      _gridRowsList[index].rawSize = selectedMaterial['raw_size'] ?? "—";
      _gridRowsList[index].finishingSize = selectedMaterial['finishing_size'] ?? "—";
      _gridRowsList[index].uom = selectedMaterial['uom_detail']?['uom_name'] ?? "—";
    });
  }

  void _flushAllTransactionFormFields() {
    setState(() {
      _projNameCtrl.clear();
      _projCodeCtrl.text = "AUTO GENERATED";
      _qtyCtrl.text = "1";
      _customerCtrl.clear();
      _inchargeCtrl.clear();
      _designCtrl.clear();
      _purchaseCtrl.clear();
      _gridRowsList.clear();
      _appendBlankEntryRow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectBomBloc(ProjectBomRepository())..add(InitializeBomPool()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<ProjectBomBloc, BomState>(
            listener: (context, state) {
              if (state is BomPoolLoaded) {
                _liveMaterialsMasterPool = state.items;
              }
            },
            builder: (context, state) {
              final bomBlocInstance = BlocProvider.of<ProjectBomBloc>(context);

              if (state is BomSyncing && _liveMaterialsMasterPool.isEmpty) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PROJECT TRANSACTIONS MANAGER - BILL OF MATERIALS (BOM)",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B), letterSpacing: 0.3)),
                  const SizedBox(height: 12),

                  // Header Meta panel
                  Container(
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(children: [
                          _buildGridCellHeader("PROJECT NAME", _projNameCtrl, f: 3),
                          _buildGridCellHeader("PROJECT CODE", _projCodeCtrl, readOnly: true),
                          _buildGridCellHeader("QTY", _qtyCtrl, isN: true)
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          _buildGridCellHeader("CUSTOMER NAME", _customerCtrl, f: 2),
                          _buildGridCellHeader("PROJECT INCHARGE", _inchargeCtrl),
                          _buildGridCellHeader("DESIGN INCHARGE", _designCtrl),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          _buildGridCellHeader("PURCHASE INCHARGE", _purchaseCtrl),
                          Expanded(flex: 2, child: const SizedBox())
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("PRODUCTION TRANSACTION SPECIFICATION SHEET DATA MATRIX", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white, shape: const RoundedRectangleBorder(), elevation: 0),
                        onPressed: _appendBlankEntryRow,
                        icon: const Icon(Icons.add, size: 12),
                        label: const Text("APPEND EXPANDABLE ROW", style: TextStyle(fontSize: 9)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
                      width: double.infinity,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {},
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowHeight: 30,
                              dataRowHeight: 42,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                              columns: const [
                                DataColumn(label: Text('SI.NO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('SEARCH MATERIAL (CODE / NAME) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F4C81)))),
                                DataColumn(label: Text('DESCRIPTION SPECIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('MATERIAL TYPE (AUTOFILL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('RAW SIZE (AUTOFILL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('FINISHING SIZE (AUTOFILL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('PROCESS FLOW *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.deepOrange))),
                                DataColumn(label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('QTY. *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                DataColumn(label: Text('WIPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                              ],
                              rows: List<DataRow>.generate(_gridRowsList.length, (idx) {
                                final node = _gridRowsList[idx];
                                return DataRow(cells: [
                                  DataCell(Text((idx + 1).toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),

                                  // SEARCHABLE DROPDOWN AUTOCOMPLETE CELL ENGINE
                                  DataCell(SizedBox(
                                    width: 180,
                                    child: Autocomplete<Map<String, dynamic>>(
                                      initialValue: TextEditingValue(text: node.selectedMaterialCode ?? ''),
                                      displayStringForOption: (Map<String, dynamic> option) => option['material_code'] ?? '',
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text.isEmpty) {
                                          return _liveMaterialsMasterPool;
                                        }
                                        return _liveMaterialsMasterPool.where((Map<String, dynamic> option) {
                                          final String code = (option['material_code'] ?? '').toString().toLowerCase();
                                          final String name = (option['name'] ?? '').toString().toLowerCase();
                                          final String query = textEditingValue.text.toLowerCase();
                                          return code.contains(query) || name.contains(query);
                                        });
                                      },
                                      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                                        return InkWell(
                                          onTap: () {
                                            if (!focusNode.hasFocus) {
                                              focusNode.requestFocus();
                                            }
                                            if (textController.text.isEmpty) {
                                              textController.value = const TextEditingValue(
                                                text: '',
                                                selection: TextSelection.collapsed(offset: 0),
                                              );
                                            }
                                          },
                                          child: TextFormField(
                                            controller: textController,
                                            focusNode: focusNode,
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold),
                                            decoration: const InputDecoration(
                                              hintText: "Click or Type Search...",
                                              hintStyle: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.normal),
                                              border: InputBorder.none,
                                              isDense: true,
                                              suffixIcon: Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF0F4C81)),
                                            ),
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
                                        // ✅ Linked dynamically to the object mapping parser method
                                        _executeCellReactiveAutofill(idx, selection);
                                      },
                                    ),
                                  )),

                                  DataCell(Text(node.description, style: const TextStyle(fontSize: 10.5, color: Colors.black87))),
                                  DataCell(Text(node.materialType, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                                  DataCell(Text(node.rawSize, style: const TextStyle(fontSize: 10.5))),
                                  DataCell(Text(node.finishingSize, style: const TextStyle(fontSize: 10.5))),

                                  DataCell(SizedBox(
                                    width: 130,
                                    child: TextFormField(
                                      initialValue: node.processFlow,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                      decoration: const InputDecoration(
                                        hintText: "Type Process...",
                                        hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.normal),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        node.processFlow = value;
                                      },
                                    ),
                                  )),

                                  DataCell(Text(node.uom, style: const TextStyle(fontSize: 10.5))),
                                  DataCell(SizedBox(width: 40, child: TextFormField(initialValue: node.quantity.toString(), keyboardType: TextInputType.number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none), onChanged: (v) => node.quantity = int.tryParse(v) ?? 1))),
                                  DataCell(IconButton(icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: Colors.red), padding: EdgeInsets.zero, onPressed: () { setState(() { _gridRowsList.removeAt(idx); }); })),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: const RoundedRectangleBorder(), elevation: 0),
                      onPressed: () {
                        if (_gridRowsList.any((element) => element.materialId == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Validation Error: Please select valid material codes across rows matrices."), backgroundColor: Colors.red));
                          return;
                        }

                        final Map<String, dynamic> requestPayloadBOM = {
                          "project_name": _projNameCtrl.text.trim(),
                          "project_code": null,
                          "quantity": int.tryParse(_qtyCtrl.text.trim()) ?? 1,
                          "customer_name": _customerCtrl.text.trim(),
                          "project_incharge": _inchargeCtrl.text.trim(),
                          "delivery_timeline": null,
                          "design_incharge": _designCtrl.text.trim(),
                          "purchase_incharge": _purchaseCtrl.text.trim(),
                          "items": _gridRowsList.map((row) => {
                            "material": row.materialId,
                            "item_no": row.selectedMaterialCode,
                            "description": row.description,
                            "process_flow": row.processFlow,
                            "quantity": row.quantity
                          }).toList()
                        };

                        bomBlocInstance.add(SubmitBomBatch(
                            requestPayloadBOM,
                            onSuccess: () {
                              _flushAllTransactionFormFields();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BOM Manifest Saved & Synced into ERP Pipeline Successfully!"), backgroundColor: Colors.green));
                            }
                        ));
                      },
                      child: const Text("SAVE PROJECT BOM BATCH TRANSACTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridCellHeader(String label, TextEditingController ctrl, {int f = 1, bool isN = false, bool readOnly = false}) {
    return Expanded(
      flex: f,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
          child: TextFormField(
            controller: ctrl,
            readOnly: readOnly,
            keyboardType: isN ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: readOnly ? Colors.grey : Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }
}