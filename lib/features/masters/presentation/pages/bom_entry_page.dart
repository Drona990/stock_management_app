/*
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
}*/


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
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

  Future<List<Map<String, dynamic>>> getUomsPool() async {
    final res = await apiClient.get('/api/erp/uoms/');
    final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<List<Map<String, dynamic>>> getMaterialTypesPool() async {
    final res = await apiClient.get('/api/erp/material-types/');
    final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<Map<String, dynamic>> saveQuickInlineMaterialMultipart({
    required Map<String, dynamic> fields,
    required String? imagePath,
    required Uint8List? webBytes,
  }) async {
    final res = await apiClient.postMultipart(
      '/api/erp/materials/',
      fields: fields,
      filePath: kIsWeb ? null : imagePath,
      webBytes: webBytes,
      fileKey: "image",
    );
    return Map<String, dynamic>.from(res.data);
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProjectBomRepository _bomRepository = ProjectBomRepository();
  List<Map<String, dynamic>> _liveMaterialsMasterPool = [];
  final List<TableRowNode> _gridRowsList = [];

  final _projNameCtrl = TextEditingController();
  final _projCodeCtrl = TextEditingController(text: "AUTO GENERATED");
  final _qtyCtrl = TextEditingController(text: "1");
  final _customerCtrl = TextEditingController();
  final _inchargeCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();

  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];

  int? _activeTargetRowIndex;

  @override
  void initState() {
    super.initState();
    _appendBlankEntryRow();
    _loadAuxiliaryPools();
  }

  @override
  void dispose() {
    _projNameCtrl.dispose(); _projCodeCtrl.dispose(); _qtyCtrl.dispose();
    _customerCtrl.dispose(); _inchargeCtrl.dispose(); _designCtrl.dispose();
    _purchaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuxiliaryPools() async {
    try {
      final uoms = await _bomRepository.getUomsPool();
      final types = await _bomRepository.getMaterialTypesPool();
      setState(() { _uomsList = uoms; _typesList = types; });
    } catch (_) {}
  }

  void _appendBlankEntryRow() {
    setState(() { _gridRowsList.add(TableRowNode()); });
  }

  void _executeCellReactiveAutofill(int index, Map<String, dynamic> selectedMaterial) {
    setState(() {
      _gridRowsList[index].selectedMaterialCode = selectedMaterial['material_code'];
      _gridRowsList[index].materialId = int.tryParse(selectedMaterial['id'].toString());
      _gridRowsList[index].description = selectedMaterial['name'] ?? "—";
      _gridRowsList[index].materialType = selectedMaterial['material_type_detail']?['name'] ?? (selectedMaterial['material_type_name'] ?? "—");
      _gridRowsList[index].rawSize = selectedMaterial['raw_size'] ?? "—";
      _gridRowsList[index].finishingSize = selectedMaterial['finishing_size'] ?? "—";
      _gridRowsList[index].uom = selectedMaterial['uom_detail']?['uom_name'] ?? (selectedMaterial['uom_name'] ?? "—");
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
    double screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) => ProjectBomBloc(ProjectBomRepository())..add(InitializeBomPool()),
      child: Builder(
        builder: (scaffoldContext) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF8FAFB),

            endDrawer: Drawer(
              width: screenWidth > 800 ? 460 : screenWidth * 0.85,
              shape: const RoundedRectangleBorder(),
              child: _buildRightSideFormPanel(BlocProvider.of<ProjectBomBloc>(scaffoldContext)),
            ),

            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocConsumer<ProjectBomBloc, BomState>(
                listener: (context, state) {
                  if (state is BomPoolLoaded) { _liveMaterialsMasterPool = state.items; }
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
                                  DataColumn(label: Text('MATERIAL NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
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
                                      width: 215,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Autocomplete<Map<String, dynamic>>(
                                              initialValue: TextEditingValue(text: node.selectedMaterialCode ?? ''),
                                              displayStringForOption: (Map<String, dynamic> option) => option['material_code'] ?? '',
                                              optionsBuilder: (TextEditingValue textEditingValue) {
                                                if (textEditingValue.text.isEmpty) { return _liveMaterialsMasterPool; }
                                                return _liveMaterialsMasterPool.where((Map<String, dynamic> option) {
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
                                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF0F4C81), fontWeight: FontWeight.bold),
                                                  decoration: const InputDecoration(
                                                    hintText: "Search...",
                                                    hintStyle: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.normal),
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
                                              onSelected: (Map<String, dynamic> selection) { _executeCellReactiveAutofill(idx, selection); },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0F4C81)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: "Quick Add Material (Drawer)",
                                            onPressed: () {
                                              setState(() { _activeTargetRowIndex = idx; });
                                              _scaffoldKey.currentState?.openEndDrawer();
                                            },
                                          ),
                                        ],
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
                                        onChanged: (value) { node.processFlow = value; },
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
          );
        },
      ),
    );
  }

  Widget _buildRightSideFormPanel(ProjectBomBloc blocInstance) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final rawCtrl = TextEditingController();
    final finCtrl = TextEditingController();
    final purCtrl = TextEditingController();
    final salesCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: "1");

    String? localPickedImagePath;
    Uint8List? webImageMemoryBytes;
    final ImagePicker picker = ImagePicker();

    int? selectedUomId = _uomsList.isNotEmpty ? int.tryParse(_uomsList.first['id'].toString()) : null;
    int? selectedTypeId = _typesList.isNotEmpty ? int.tryParse(_typesList.first['id'].toString()) : null;

    // 🌟 LOCAL CONTROLLER FOR BUTTON LOADING TRIGGER STATE
    bool isSavingMaterial = false;

    return StatefulBuilder(
      builder: (context, setPanelState) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Add Materials", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B))),
                    IconButton(onPressed: isSavingMaterial ? null : () => Navigator.pop(context), icon: const Icon(Icons.close, size: 16))
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
                          onTap: isSavingMaterial ? null : () async {
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (image != null) {
                              if (kIsWeb) {
                                final bytes = await image.readAsBytes();
                                setPanelState(() { webImageMemoryBytes = bytes; localPickedImagePath = image.path; });
                              } else {
                                setPanelState(() { localPickedImagePath = image.path; });
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity, height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: (localPickedImagePath != null || webImageMemoryBytes != null) ? Colors.green.shade400 : Colors.grey.shade300),
                            ),
                            child: (localPickedImagePath != null || webImageMemoryBytes != null)
                                ? Stack(
                              children: [
                                Positioned.fill(
                                    child: kIsWeb
                                        ? Image.memory(webImageMemoryBytes!, fit: BoxFit.cover)
                                        : Image.file(File(localPickedImagePath!), fit: BoxFit.cover)
                                ),
                                Container(color: Colors.black38),
                                const Center(child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text("IMAGE ATTACHED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ))
                              ],
                            )
                                : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 18, color: Colors.blueGrey),
                                const SizedBox(height: 6),
                                Text("CHOOSE OPTIONAL PRODUCT IMAGE FROM GALLERY POOL", style: TextStyle(fontSize: 8.5, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(children: [
                          Expanded(child: _buildModalCompactField(codeCtrl, "CODE *", readOnly: isSavingMaterial)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildModalCompactField(nameCtrl, "NAME *", readOnly: isSavingMaterial)),
                        ]),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedUomId,
                              style: const TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: _buildDropdownDecorationMatrix("UOM SPEC *"),
                              items: _uomsList.map<DropdownMenuItem<int>>((u) {
                                return DropdownMenuItem<int>(value: int.tryParse(u['id'].toString()), child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 10)));
                              }).toList(),
                              onChanged: isSavingMaterial ? null : (v) => setPanelState(() => selectedUomId = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: _buildModalCompactField(unitsCtrl, "UNITS TOTAL *", isNumeric: true, readOnly: isSavingMaterial)),
                        ]),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<int>(
                          value: selectedTypeId,
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                          decoration: _buildDropdownDecorationMatrix("MATERIAL TYPE MASTER REFERENCE *"),
                          items: _typesList.map<DropdownMenuItem<int>>((t) {
                            return DropdownMenuItem<int>(value: int.tryParse(t['id'].toString()), child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 10)));
                          }).toList(),
                          onChanged: isSavingMaterial ? null : (v) => setPanelState(() => selectedTypeId = v),
                        ),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(child: _buildModalCompactField(rawCtrl, "RAW SIZE", readOnly: isSavingMaterial)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildModalCompactField(finCtrl, "FINISHING SIZE", readOnly: isSavingMaterial)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _buildModalCompactField(purCtrl, "PURCHASE RATE *", isNumeric: true, readOnly: isSavingMaterial),),
                          const SizedBox(width: 10),
                          Expanded(child: _buildModalCompactField(salesCtrl, "SALES RATE *", isNumeric: true, readOnly: isSavingMaterial)),
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
                    onPressed: isSavingMaterial ? null : () async {
                      if (formKey.currentState!.validate() && selectedUomId != null && selectedTypeId != null && _activeTargetRowIndex != null) {

                        // 🟢 START LOADING ACTION
                        setPanelState(() { isSavingMaterial = true; });

                        try {
                          final Map<String, dynamic> textMultipartFields = {
                            "entry_date": DateTime.now().toString().split(" ")[0],
                            "material_code": codeCtrl.text.trim().toUpperCase(),
                            "name": nameCtrl.text.trim(),
                            "uom": selectedUomId.toString(),
                            "units": unitsCtrl.text.trim(),
                            "material_type": selectedTypeId.toString(),
                            "purchase_price": purCtrl.text.trim(),
                            "sales_price": salesCtrl.text.trim(),
                            if (rawCtrl.text.trim().isNotEmpty) "raw_size": rawCtrl.text.trim(),
                            if (finCtrl.text.trim().isNotEmpty) "finishing_size": finCtrl.text.trim(),
                          };

                          final Map<String, dynamic> generatedMaterialNode = await _bomRepository.saveQuickInlineMaterialMultipart(
                            fields: textMultipartFields,
                            imagePath: localPickedImagePath,
                            webBytes: webImageMemoryBytes,
                          );

                          // 🟢 END LOADING & AUTO-CLOSE TRIGGER SEQUENCE
                          _executeCellReactiveAutofill(_activeTargetRowIndex!, generatedMaterialNode);
                          blocInstance.add(InitializeBomPool());

                          Navigator.pop(context); // 👈 Auto Close Modal Drawer seamlessly after 201 success

                        } catch (e) {
                          setPanelState(() { isSavingMaterial = false; });
                          dev.log("Drawer submission operation matrix crash: $e");
                        }
                      }
                    },
                    // 🌟 DYNAMIC LOADING INDICATOR FOR INDUSTRIAL UI INTEGRITY
                    child: isSavingMaterial
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("SAVE MASTER MATERIAL & AUTOFILL ROW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCellHeader(String label, TextEditingController ctrl, {int f = 1, bool isN = false, bool readOnly = false}) {
    return Expanded(
      flex: f,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 42,
          decoration: BoxDecoration(color: readOnly ? Colors.grey.shade100 : Colors.white),
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