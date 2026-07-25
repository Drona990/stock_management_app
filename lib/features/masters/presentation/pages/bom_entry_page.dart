/*

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
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<List<Map<String, dynamic>>> getUomsPool() async {
    final res = await apiClient.get('/api/erp/uoms/');
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<List<Map<String, dynamic>>> getMaterialTypesPool() async {
    final res = await apiClient.get('/api/erp/material-types/');
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
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
      throw Exception("Transaction server failure");
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
  final _descriptionCtrl = TextEditingController();

  DateTime _selectedBomDate = DateTime.now();
  final _dateDisplayCtrl = TextEditingController();

  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];
  int? _activeTargetRowIndex;

  @override
  void initState() {
    super.initState();
    _updateDateDisplay();
    _appendBlankEntryRow();
    _loadAuxiliaryPools();
  }

  @override
  void dispose() {
    _projNameCtrl.dispose();
    _projCodeCtrl.dispose();
    _descriptionCtrl.dispose();
    _dateDisplayCtrl.dispose();
    super.dispose();
  }

  void _updateDateDisplay() {
    _dateDisplayCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedBomDate);
  }

  Future<void> _selectBomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBomDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0F4C81)),
        ),
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

  Future<void> _loadAuxiliaryPools() async {
    try {
      final uoms = await _bomRepository.getUomsPool();
      final types = await _bomRepository.getMaterialTypesPool();
      if (mounted) {
        setState(() {
          _uomsList = uoms;
          _typesList = types;
        });
      }
    } catch (_) {}
  }

  void _appendBlankEntryRow() {
    setState(() {
      _gridRowsList.add(TableRowNode());
    });
  }

  void _executeCellReactiveAutofill(
      int index, Map<String, dynamic> selectedMaterial) {
    if (index >= _gridRowsList.length) return;

    final String extractedType = selectedMaterial['material_type_detail']
    ?['name'] ??
        selectedMaterial['material_type_name'] ??
        (selectedMaterial['material_type']?.toString() ?? "—");

    final String extractedUom = selectedMaterial['uom_detail']?['uom_name'] ??
        selectedMaterial['uom_name'] ??
        (selectedMaterial['uom']?.toString() ?? "PCS");

    setState(() {
      _gridRowsList[index].selectedMaterialCode = selectedMaterial['material_code'];
      _gridRowsList[index].materialId = int.tryParse(selectedMaterial['id'].toString());
      _gridRowsList[index].description = selectedMaterial['name'] ?? selectedMaterial['description'] ?? "—";
      _gridRowsList[index].materialType = extractedType;
      _gridRowsList[index].rawSize = selectedMaterial['raw_size'] ?? "—";
      _gridRowsList[index].finishingSize = selectedMaterial['finishing_size'] ?? "—";
      _gridRowsList[index].uom = extractedUom;
    });
  }

  void _flushAllTransactionFormFields() {
    setState(() {
      _projNameCtrl.clear();
      _projCodeCtrl.text = "AUTO GENERATED";
      _descriptionCtrl.clear();
      _selectedBomDate = DateTime.now();
      _updateDateDisplay();
      _gridRowsList.clear();
      _appendBlankEntryRow();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) => ProjectBomBloc(_bomRepository)..add(InitializeBomPool()),
      child: Builder(
        builder: (scaffoldContext) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF8FAFB),
            endDrawer: Drawer(
              width: screenWidth > 800 ? 460 : screenWidth * 0.85,
              child: QuickAddMaterialDrawer(
                uomsList: _uomsList,
                typesList: _typesList,
                repository: _bomRepository,
                onMaterialSaved: (newMaterial) {
                  if (_activeTargetRowIndex != null) {
                    _executeCellReactiveAutofill(_activeTargetRowIndex!, newMaterial);
                  }
                  BlocProvider.of<ProjectBomBloc>(scaffoldContext).add(InitializeBomPool());
                },
              ),
            ),
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
                      const Text(
                        "MASTER BILL OF MATERIALS (BOM) TEMPLATE CREATOR",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildGridCellHeader("MASTER BOM NAME *", _projNameCtrl, f: 3),
                                _buildGridCellHeader("BOM CODE", _projCodeCtrl, readOnly: true),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Container(
                                      height: 42,
                                      color: Colors.white,
                                      child: TextFormField(
                                        controller: _dateDisplayCtrl,
                                        readOnly: true,
                                        onTap: () => _selectBomDate(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                        decoration: InputDecoration(
                                          labelText: "BOM DATE *",
                                          labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F4C81)),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
                                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0F4C81), width: 1.2)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(children: [_buildGridCellHeader("TEMPLATE DESCRIPTION / NOTES", _descriptionCtrl, f: 1)]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("SPECIFICATION MATRIX (STANDARD ITEM LIST)", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white, elevation: 0),
                            onPressed: _appendBlankEntryRow,
                            icon: const Icon(Icons.add, size: 12),
                            label: const Text("APPEND ROW", style: TextStyle(fontSize: 9)),
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
                                headingRowHeight: 30,
                                dataRowHeight: 42,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                                columns: const [
                                  DataColumn(label: Text('SI.NO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('SEARCH MATERIAL *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F4C81)))),
                                  DataColumn(label: Text('MATERIAL NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('MATERIAL TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('RAW SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('FINISHING SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('PROCESS FLOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.deepOrange))),
                                  DataColumn(label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('BASE QTY *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                ],
                                rows: List<DataRow>.generate(_gridRowsList.length, (idx) {
                                  final node = _gridRowsList[idx];
                                  return DataRow(
                                    key: ValueKey('bom_row_${idx}_${node.materialId}_${node.selectedMaterialCode}'),
                                    cells: [
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
                                                  if (textEditingValue.text.isEmpty) return _liveMaterialsMasterPool;
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
                                                    decoration: const InputDecoration(hintText: "Search...", border: InputBorder.none, isDense: true),
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
                                                  _executeCellReactiveAutofill(idx, selection);
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0F4C81)),
                                              onPressed: () {
                                                setState(() {
                                                  _activeTargetRowIndex = idx;
                                                });
                                                _scaffoldKey.currentState?.openEndDrawer();
                                              },
                                            ),
                                          ],
                                        ),
                                      )),
                                      DataCell(Text(node.description, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(Text(node.materialType, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                                      DataCell(Text(node.rawSize, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(Text(node.finishingSize, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(SizedBox(
                                        width: 130,
                                        child: TextFormField(
                                          key: ValueKey('proc_${idx}_${node.processFlow}'),
                                          initialValue: node.processFlow,
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                          onChanged: (v) => node.processFlow = v,
                                        ),
                                      )),
                                      DataCell(Text(node.uom, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(SizedBox(
                                        width: 40,
                                        child: TextFormField(
                                          key: ValueKey('qty_${idx}_${node.quantity}'),
                                          initialValue: node.quantity.toString(),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          onChanged: (v) => node.quantity = int.tryParse(v) ?? 1,
                                        ),
                                      )),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: Colors.red),
                                        onPressed: () => setState(() => _gridRowsList.removeAt(idx)),
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

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                          onPressed: () {
                            if (_projNameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Master BOM Template Name."), backgroundColor: Colors.red));
                              return;
                            }
                            if (_gridRowsList.any((e) => e.materialId == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select valid material codes."), backgroundColor: Colors.red));
                              return;
                            }

                            final Map<String, dynamic> requestPayloadBOM = {
                              "project_name": _projNameCtrl.text.trim(),
                              "project_code": null,
                              "description": _descriptionCtrl.text.trim(),
                              "bom_date": DateFormat('yyyy-MM-dd').format(_selectedBomDate),
                              "items": _gridRowsList.map((row) => {
                                "material": row.materialId,
                                "item_no": row.selectedMaterialCode,
                                "description": row.description,
                                "process_flow": row.processFlow,
                                "quantity": row.quantity
                              }).toList()
                            };

                            bomBlocInstance.add(SubmitBomBatch(requestPayloadBOM, onSuccess: () {
                              _flushAllTransactionFormFields();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Master BOM Saved Successfully!"), backgroundColor: Colors.green));
                            }));
                          },
                          child: const Text("SAVE MASTER BOM TEMPLATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildGridCellHeader(String label, TextEditingController ctrl, {int f = 1, bool readOnly = false}) {
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: readOnly ? Colors.grey : Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0F4C81), width: 1.2)),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// 4. ISOLATED DRAWER WIDGET (COMPLETE WITH ALL FORM FIELDS & IMAGE PICKER)
// ==========================================================================
class QuickAddMaterialDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> uomsList;
  final List<Map<String, dynamic>> typesList;
  final ProjectBomRepository repository;
  final Function(Map<String, dynamic>) onMaterialSaved;

  const QuickAddMaterialDrawer({
    super.key,
    required this.uomsList,
    required this.typesList,
    required this.repository,
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
                      onTap: _isSavingMaterial
                          ? null
                          : () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          if (kIsWeb) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              _webImageMemoryBytes = bytes;
                              _localPickedImagePath = image.path;
                            });
                          } else {
                            setState(() {
                              _localPickedImagePath = image.path;
                            });
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(
                              color: (_localPickedImagePath != null || _webImageMemoryBytes != null)
                                  ? Colors.green.shade400
                                  : Colors.grey.shade300),
                        ),
                        child: (_localPickedImagePath != null || _webImageMemoryBytes != null)
                            ? Stack(
                          children: [
                            Positioned.fill(
                                child: kIsWeb
                                    ? Image.memory(_webImageMemoryBytes!, fit: BoxFit.cover)
                                    : Image.file(File(_localPickedImagePath!), fit: BoxFit.cover)),
                            Container(color: Colors.black38),
                            const Center(
                                child: Row(
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
                            return DropdownMenuItem<int>(
                                value: int.tryParse(u['id'].toString()),
                                child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 10)));
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
                        return DropdownMenuItem<int>(
                            value: int.tryParse(t['id'].toString()),
                            child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 10)));
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
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                onPressed: _isSavingMaterial
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate() &&
                      _selectedUomId != null &&
                      _selectedTypeId != null) {
                    setState(() {
                      _isSavingMaterial = true;
                    });

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

                      final Map<String, dynamic> generatedMaterialNode =
                      await widget.repository.saveQuickInlineMaterialMultipart(
                        fields: textMultipartFields,
                        imagePath: _localPickedImagePath,
                        webBytes: _webImageMemoryBytes,
                      );

                      widget.onMaterialSaved(generatedMaterialNode);

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSavingMaterial = false;
                        });
                      }
                      dev.log("Drawer submission operation crash: $e");
                    }
                  }
                },
                child: _isSavingMaterial
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  "SAVE MASTER MATERIAL & AUTOFILL ROW",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModalCompactField(TextEditingController ctrl, String label,
      {bool isNumeric = false, bool readOnly = false}) {
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
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<List<Map<String, dynamic>>> getUomsPool() async {
    final res = await apiClient.get('/api/erp/uoms/');
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<List<Map<String, dynamic>>> getMaterialTypesPool() async {
    final res = await apiClient.get('/api/erp/material-types/');
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
    return List<Map<String, dynamic>>.from(d);
  }

  Future<List<Map<String, dynamic>>> fetchMasterBomHistory() async {
    final res = await apiClient.get('/api/erp/projects/');
    final List d = (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
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

  Future<void> saveProjectBomManifest(Map<String, dynamic> payload, {int? editProjectId}) async {
    dynamic response;
    if (editProjectId != null) {
      response = await apiClient.put('/api/erp/projects/$editProjectId/', data: payload);
    } else {
      response = await apiClient.post('/api/erp/projects/', data: payload);
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Transaction server failure");
    }
  }
}

abstract class BomEvent {}

class InitializeBomPool extends BomEvent {}

class SubmitBomBatch extends BomEvent {
  final Map<String, dynamic> payload;
  final int? editProjectId;
  final VoidCallback? onSuccess;
  SubmitBomBatch(this.payload, {this.editProjectId, this.onSuccess});
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
        await repo.saveProjectBomManifest(e.payload, editProjectId: e.editProjectId);
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
  final _descriptionCtrl = TextEditingController();

  DateTime _selectedBomDate = DateTime.now();
  final _dateDisplayCtrl = TextEditingController();

  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];
  int? _activeTargetRowIndex;

  // 🟢 EDIT MODE TRACKING STATES
  bool _isEditMode = false;
  int? _editingProjectId;

  @override
  void initState() {
    super.initState();
    _updateDateDisplay();
    _appendBlankEntryRow();
    _loadAuxiliaryPools();
  }

  @override
  void dispose() {
    _projNameCtrl.dispose();
    _projCodeCtrl.dispose();
    _descriptionCtrl.dispose();
    _dateDisplayCtrl.dispose();
    super.dispose();
  }

  void _updateDateDisplay() {
    _dateDisplayCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedBomDate);
  }

  Future<void> _selectBomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBomDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0F4C81)),
        ),
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

  Future<void> _loadAuxiliaryPools() async {
    try {
      final uoms = await _bomRepository.getUomsPool();
      final types = await _bomRepository.getMaterialTypesPool();
      if (mounted) {
        setState(() {
          _uomsList = uoms;
          _typesList = types;
        });
      }
    } catch (_) {}
  }

  void _appendBlankEntryRow() {
    setState(() {
      _gridRowsList.add(TableRowNode());
    });
  }

  void _executeCellReactiveAutofill(
      int index, Map<String, dynamic> selectedMaterial) {
    if (index >= _gridRowsList.length) return;

    final String extractedType = selectedMaterial['material_type_detail']
    ?['name'] ??
        selectedMaterial['material_type_name'] ??
        (selectedMaterial['material_type']?.toString() ?? "—");

    final String extractedUom = selectedMaterial['uom_detail']?['uom_name'] ??
        selectedMaterial['uom_name'] ??
        (selectedMaterial['uom']?.toString() ?? "PCS");

    setState(() {
      _gridRowsList[index].selectedMaterialCode = selectedMaterial['material_code'];
      _gridRowsList[index].materialId = int.tryParse(selectedMaterial['id'].toString());
      _gridRowsList[index].description = selectedMaterial['name'] ?? selectedMaterial['description'] ?? "—";
      _gridRowsList[index].materialType = extractedType;
      _gridRowsList[index].rawSize = selectedMaterial['raw_size'] ?? "—";
      _gridRowsList[index].finishingSize = selectedMaterial['finishing_size'] ?? "—";
      _gridRowsList[index].uom = extractedUom;
    });
  }

  void _flushAllTransactionFormFields() {
    setState(() {
      _isEditMode = false;
      _editingProjectId = null;
      _projNameCtrl.clear();
      _projCodeCtrl.text = "AUTO GENERATED";
      _descriptionCtrl.clear();
      _selectedBomDate = DateTime.now();
      _updateDateDisplay();
      _gridRowsList.clear();
      _appendBlankEntryRow();
    });
  }

// 🌟 POPULATE DATA WHEN USER CLICKS EDIT IN HISTORY MODAL (FIXED MATERIAL TYPE)
  void _populateDataForEditing(Map<String, dynamic> projectData) {
    setState(() {
      _isEditMode = true;
      _editingProjectId = projectData['id'];
      _projNameCtrl.text = projectData['project_name'] ?? "";
      _projCodeCtrl.text = projectData['project_code'] ?? "AUTO GENERATED";
      _descriptionCtrl.text = projectData['description'] ?? "";

      if (projectData['bom_date'] != null) {
        _selectedBomDate = DateTime.tryParse(projectData['bom_date'].toString()) ?? DateTime.now();
      }
      _updateDateDisplay();

      // Populate Grid Rows List
      _gridRowsList.clear();
      List items = projectData['items'] ?? [];
      for (var item in items) {
        int? matId = item['material'] ?? item['material_id'];

        // 🟢 1. Live materials pool se master object dhoondo
        Map<String, dynamic> matchedMaterial = _liveMaterialsMasterPool.firstWhere(
              (m) => int.tryParse(m['id'].toString()) == matId,
          orElse: () => {},
        );

        // 🟢 2. Multi-level extraction logic for Material Type
        String matType = "—";

        // Pehle API Item detail response me check karo
        if (item['material_type_detail'] != null && item['material_type_detail']['name'] != null) {
          matType = item['material_type_detail']['name'].toString();
        } else if (item['material_type_name'] != null && item['material_type_name'].toString().isNotEmpty) {
          matType = item['material_type_name'].toString();
        } else if (item['material_type'] != null && item['material_type'] is String && item['material_type'].toString().isNotEmpty && item['material_type'] != "—") {
          matType = item['material_type'].toString();
        }
        // Agar item me nahi mila, toh matched master material Object me check karo
        else if (matchedMaterial.isNotEmpty) {
          matType = matchedMaterial['material_type_detail']?['name'] ??
              matchedMaterial['material_type_name'] ??
              matchedMaterial['material_type']?.toString() ?? "—";
        }

        // 🟢 3. Multi-level extraction for UOM, Raw Size, Finishing Size
        String uomVal = item['uom_detail']?['uom_name'] ??
            item['uom_name'] ??
            item['uom'] ??
            matchedMaterial['uom_detail']?['uom_name'] ??
            matchedMaterial['uom_name'] ?? "PCS";

        String rawS = item['raw_size'] ?? matchedMaterial['raw_size'] ?? "—";
        String finS = item['finishing_size'] ?? matchedMaterial['finishing_size'] ?? "—";

        _gridRowsList.add(TableRowNode(
          materialId: matId,
          selectedMaterialCode: item['item_no'] ?? item['material_code'] ?? matchedMaterial['material_code'] ?? "",
          description: item['description'] ?? matchedMaterial['name'] ?? "—",
          materialType: matType,
          rawSize: rawS,
          finishingSize: finS,
          processFlow: item['process_flow'] ?? "",
          uom: uomVal,
          quantity: item['quantity'] ?? 1,
        ));
      }

      if (_gridRowsList.isEmpty) {
        _appendBlankEntryRow();
      }
    });
  }
  // 🌟 SHOW MASTER BOM HISTORY MODAL DIALOG
  void _openBomHistoryDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 800,
            height: 550,
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _bomRepository.fetchMasterBomHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F4C81)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error fetching history: ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 11)));
                }

                final historyList = snapshot.data ?? [];
                if (historyList.isEmpty) {
                  return const Center(child: Text("No Master BOM templates recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 11)));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history_rounded, color: Color(0xFF0F4C81), size: 18),
                            SizedBox(width: 8),
                            Text("MASTER BOM TEMPLATES HISTORY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B))),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(dialogContext),
                        )
                      ],
                    ),
                    const Divider(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: historyList.length,
                        separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final project = historyList[idx];
                          List items = project['items'] ?? [];

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            title: Row(
                              children: [
                                Text("[${project['project_code'] ?? 'N/A'}] ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81), fontSize: 11)),
                                Text(project['project_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                              ],
                            ),
                            subtitle: Text("BOM Date: ${project['bom_date'] ?? 'N/A'} • Total Items: ${items.length} • ${project['description'] ?? 'No Notes'}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C81),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: const RoundedRectangleBorder(),
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 12),
                              label: const Text("EDIT / RE-LOAD", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _populateDataForEditing(project);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) => ProjectBomBloc(_bomRepository)..add(InitializeBomPool()),
      child: Builder(
        builder: (scaffoldContext) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF8FAFB),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              title: Text(
                _isEditMode ? "EDIT MASTER BOM TEMPLATE" : "MASTER BILL OF MATERIALS (BOM) CREATOR",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              actions: [
                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton.icon(
                      onPressed: _flushAllTransactionFormFields,
                      icon: const Icon(Icons.add, color: Colors.amber, size: 14),
                      label: const Text("CREATE NEW TEMPLATE", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: _openBomHistoryDialog,
                    icon: const Icon(Icons.history_rounded, size: 14),
                    label: const Text("VIEW BOM HISTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            endDrawer: Drawer(
              width: screenWidth > 800 ? 460 : screenWidth * 0.85,
              child: QuickAddMaterialDrawer(
                uomsList: _uomsList,
                typesList: _typesList,
                repository: _bomRepository,
                onMaterialSaved: (newMaterial) {
                  if (_activeTargetRowIndex != null) {
                    _executeCellReactiveAutofill(_activeTargetRowIndex!, newMaterial);
                  }
                  BlocProvider.of<ProjectBomBloc>(scaffoldContext).add(InitializeBomPool());
                },
              ),
            ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEditMode ? "EDITING MASTER TEMPLATE: ${_projCodeCtrl.text}" : "MASTER BILL OF MATERIALS (BOM) TEMPLATE CREATOR",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: _isEditMode ? const Color(0xFF0284C7) : const Color(0xFF1E293B)),
                          ),
                          if (_isEditMode)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              color: const Color(0xFFE0F2FE),
                              child: const Text("EDIT MODE ACTIVE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildGridCellHeader("MASTER BOM NAME *", _projNameCtrl, f: 3),
                                _buildGridCellHeader("BOM CODE", _projCodeCtrl, readOnly: true),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Container(
                                      height: 42,
                                      color: Colors.white,
                                      child: TextFormField(
                                        controller: _dateDisplayCtrl,
                                        readOnly: true,
                                        onTap: () => _selectBomDate(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                        decoration: InputDecoration(
                                          labelText: "BOM DATE *",
                                          labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F4C81)),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
                                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0F4C81), width: 1.2)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(children: [_buildGridCellHeader("TEMPLATE DESCRIPTION / NOTES", _descriptionCtrl, f: 1)]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("SPECIFICATION MATRIX (STANDARD ITEM LIST)", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C81), foregroundColor: Colors.white, elevation: 0),
                            onPressed: _appendBlankEntryRow,
                            icon: const Icon(Icons.add, size: 12),
                            label: const Text("APPEND ROW", style: TextStyle(fontSize: 9)),
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
                                headingRowHeight: 30,
                                dataRowHeight: 42,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                                columns: const [
                                  DataColumn(label: Text('SI.NO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('SEARCH MATERIAL *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F4C81)))),
                                  DataColumn(label: Text('MATERIAL NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('MATERIAL TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('RAW SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('FINISHING SIZE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('PROCESS FLOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.deepOrange))),
                                  DataColumn(label: Text('UOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('BASE QTY *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                  DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9))),
                                ],
                                rows: List<DataRow>.generate(_gridRowsList.length, (idx) {
                                  final node = _gridRowsList[idx];
                                  return DataRow(
                                    key: ValueKey('bom_row_${idx}_${node.materialId}_${node.selectedMaterialCode}'),
                                    cells: [
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
                                                  if (textEditingValue.text.isEmpty) return _liveMaterialsMasterPool;
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
                                                    decoration: const InputDecoration(hintText: "Search...", border: InputBorder.none, isDense: true),
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
                                                  _executeCellReactiveAutofill(idx, selection);
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0F4C81)),
                                              onPressed: () {
                                                setState(() {
                                                  _activeTargetRowIndex = idx;
                                                });
                                                _scaffoldKey.currentState?.openEndDrawer();
                                              },
                                            ),
                                          ],
                                        ),
                                      )),
                                      DataCell(Text(node.description, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(Text(node.materialType, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                                      DataCell(Text(node.rawSize, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(Text(node.finishingSize, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(SizedBox(
                                        width: 130,
                                        child: TextFormField(
                                          key: ValueKey('proc_${idx}_${node.processFlow}'),
                                          initialValue: node.processFlow,
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                          onChanged: (v) => node.processFlow = v,
                                        ),
                                      )),
                                      DataCell(Text(node.uom, style: const TextStyle(fontSize: 10.5))),
                                      DataCell(SizedBox(
                                        width: 40,
                                        child: TextFormField(
                                          key: ValueKey('qty_${idx}_${node.quantity}'),
                                          initialValue: node.quantity.toString(),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(border: InputBorder.none),
                                          onChanged: (v) => node.quantity = int.tryParse(v) ?? 1,
                                        ),
                                      )),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: Colors.red),
                                        onPressed: () => setState(() => _gridRowsList.removeAt(idx)),
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

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditMode ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          onPressed: () {
                            if (_projNameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Master BOM Template Name."), backgroundColor: Colors.red));
                              return;
                            }
                            if (_gridRowsList.any((e) => e.materialId == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select valid material codes."), backgroundColor: Colors.red));
                              return;
                            }

                            final Map<String, dynamic> requestPayloadBOM = {
                              "project_name": _projNameCtrl.text.trim(),
                              "project_code": _isEditMode ? _projCodeCtrl.text.trim() : null,
                              "description": _descriptionCtrl.text.trim(),
                              "bom_date": DateFormat('yyyy-MM-dd').format(_selectedBomDate),
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
                              editProjectId: _editingProjectId,
                              onSuccess: () {
                                String successMsg = _isEditMode ? "Master BOM Updated Successfully!" : "Master BOM Saved Successfully!";
                                _flushAllTransactionFormFields();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg), backgroundColor: Colors.green));
                              },
                            ));
                          },
                          child: Text(_isEditMode ? "UPDATE MASTER BOM TEMPLATE" : "SAVE MASTER BOM TEMPLATE", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildGridCellHeader(String label, TextEditingController ctrl, {int f = 1, bool readOnly = false}) {
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: readOnly ? Colors.grey : Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey.shade300, width: 1)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF0F4C81), width: 1.2)),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// 4. ISOLATED DRAWER WIDGET (COMPLETE WITH ALL FORM FIELDS & IMAGE PICKER)
// ==========================================================================
class QuickAddMaterialDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> uomsList;
  final List<Map<String, dynamic>> typesList;
  final ProjectBomRepository repository;
  final Function(Map<String, dynamic>) onMaterialSaved;

  const QuickAddMaterialDrawer({
    super.key,
    required this.uomsList,
    required this.typesList,
    required this.repository,
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
                      onTap: _isSavingMaterial
                          ? null
                          : () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          if (kIsWeb) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              _webImageMemoryBytes = bytes;
                              _localPickedImagePath = image.path;
                            });
                          } else {
                            setState(() {
                              _localPickedImagePath = image.path;
                            });
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(
                              color: (_localPickedImagePath != null || _webImageMemoryBytes != null)
                                  ? Colors.green.shade400
                                  : Colors.grey.shade300),
                        ),
                        child: (_localPickedImagePath != null || _webImageMemoryBytes != null)
                            ? Stack(
                          children: [
                            Positioned.fill(
                                child: kIsWeb
                                    ? Image.memory(_webImageMemoryBytes!, fit: BoxFit.cover)
                                    : Image.file(File(_localPickedImagePath!), fit: BoxFit.cover)),
                            Container(color: Colors.black38),
                            const Center(
                                child: Row(
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
                            return DropdownMenuItem<int>(
                                value: int.tryParse(u['id'].toString()),
                                child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 10)));
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
                        return DropdownMenuItem<int>(
                            value: int.tryParse(t['id'].toString()),
                            child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 10)));
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
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                onPressed: _isSavingMaterial
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate() &&
                      _selectedUomId != null &&
                      _selectedTypeId != null) {
                    setState(() {
                      _isSavingMaterial = true;
                    });

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

                      final Map<String, dynamic> generatedMaterialNode =
                      await widget.repository.saveQuickInlineMaterialMultipart(
                        fields: textMultipartFields,
                        imagePath: _localPickedImagePath,
                        webBytes: _webImageMemoryBytes,
                      );

                      widget.onMaterialSaved(generatedMaterialNode);

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSavingMaterial = false;
                        });
                      }
                      dev.log("Drawer submission operation crash: $e");
                    }
                  }
                },
                child: _isSavingMaterial
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  "SAVE MASTER MATERIAL & AUTOFILL ROW",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModalCompactField(TextEditingController ctrl, String label,
      {bool isNumeric = false, bool readOnly = false}) {
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