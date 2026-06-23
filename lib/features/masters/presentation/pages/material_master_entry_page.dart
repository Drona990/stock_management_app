/*


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL DATA STRUCT ARCHITECTURE
// ==========================================================================
class MaterialEntity {
  final int? id;
  final String entryDate;
  final String materialCode;
  final String name;
  final int uomId;
  final String? uomName;
  final int units;
  final int materialTypeId;
  final String? materialTypeName;
  final String? rawSize;
  final String? finishingSize;
  final double purchasePrice;
  final double salesPrice;
  final String? imagePath;
  final Uint8List? webImageBytes;

  MaterialEntity({
    this.id, required this.entryDate, required this.materialCode, required this.name,
    required this.uomId, this.uomName, required this.units, required this.materialTypeId,
    this.materialTypeName, this.rawSize, this.finishingSize, required this.purchasePrice, required this.salesPrice,
    this.imagePath, this.webImageBytes,
  });

  factory MaterialEntity.fromJson(Map<String, dynamic> json) => MaterialEntity(
    id: json['id'],
    entryDate: json['entry_date'] ?? DateFormat('MM/dd/yyyy').format(DateTime.now()),
    materialCode: json['material_code'] ?? "",
    name: json['name'] ?? "",
    uomId: json['uom'] ?? 0,
    uomName: json['uom_detail']?['uom_name'] ?? "—",
    units: json['units'] ?? 1,
    materialTypeId: json['material_type'] ?? 0,
    materialTypeName: json['material_type_detail']?['name'] ?? "—",
    rawSize: json['raw_size'],
    finishingSize: json['finishing_size'],
    purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0,
    salesPrice: double.tryParse(json['sales_price']?.toString() ?? '0') ?? 0.0,
    imagePath: json['image'],
  );

  Map<String, dynamic> toJson() => {
    "entry_date": entryDate,
    "material_code": materialCode.trim().toUpperCase(),
    "name": name.trim(),
    "uom": uomId,
    "units": units,
    "material_type": materialTypeId,
    "raw_size": rawSize?.trim().isEmpty == true ? null : rawSize?.trim(),
    "finishing_size": finishingSize?.trim().isEmpty == true ? null : finishingSize?.trim(),
    "purchase_price": purchasePrice,
    "sales_price": salesPrice,
  };
}

// ==========================================================================
// 2. REPOSITORY ARCHITECTURE DATA PIPELINE
// ==========================================================================
class MaterialMasterRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<MaterialEntity>> getMaterials({String? query}) async {
    final res = await apiClient.get('/api/erp/materials/', query: query != null ? {'search': query} : null);
    final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
    return d.map((x) => MaterialEntity.fromJson(x)).toList();
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

  Future<void> saveWithMultipart(MaterialEntity item) async {
    final Map<String, dynamic> requestFields = {
      "entry_date": item.entryDate,
      "material_code": item.materialCode.toUpperCase().trim(),
      "name": item.name.trim(),
      "uom": item.uomId.toString(),
      "units": item.units.toString(),
      "material_type": item.materialTypeId.toString(),
      "purchase_price": item.purchasePrice.toString(),
      "sales_price": item.salesPrice.toString(),
      if (item.rawSize != null && item.rawSize!.trim().isNotEmpty)
        "raw_size": item.rawSize!.trim(),
      if (item.finishingSize != null && item.finishingSize!.trim().isNotEmpty)
        "finishing_size": item.finishingSize!.trim(),
    };

    await apiClient.postMultipart(
      '/api/erp/materials/',
      fields: requestFields,
      filePath: kIsWeb ? null : item.imagePath,
      webBytes: item.webImageBytes,
      fileKey: "image",
    );
  }

  Future<void> delete(int id) async => await apiClient.delete('/api/erp/materials/$id/');
}

// ==========================================================================
// 3. BLoC BUSINESS PATTERN ENGINE
// ==========================================================================
abstract class MatEvent {}
class LoadMats extends MatEvent { final String? query; LoadMats({this.query}); }
class AddMat extends MatEvent { final MaterialEntity item; final VoidCallback? onSuccess; AddMat(this.item, {this.onSuccess}); }
class DeleteMat extends MatEvent { final int id; DeleteMat(this.id); }

abstract class MatState {}
class MatInitial extends MatState {}
class MatLoading extends MatState {}
class MatLoaded extends MatState { final List<MaterialEntity> items; MatLoaded(this.items); }
class MatError extends MatState { final String msg; MatError(this.msg); }

class MaterialMasterBloc extends Bloc<MatEvent, MatState> {
  final MaterialMasterRepository repo;
  MaterialMasterBloc(this.repo) : super(MatInitial()) {
    on<LoadMats>((e, emit) async {
      emit(MatLoading());
      try { final d = await repo.getMaterials(query: e.query); emit(MatLoaded(d)); }
      catch (err) { emit(MatError(err.toString())); }
    });
    on<AddMat>((e, emit) async {
      try {
        await repo.saveWithMultipart(e.item);
        if (e.onSuccess != null) e.onSuccess!();
        add(LoadMats());
      } catch (_) {}
    });
    on<DeleteMat>((e, emit) async {
      try { await repo.delete(e.id); add(LoadMats()); } catch (_) {}
    });
  }
}

// ==========================================================================
// 4. MAIN WORKSPACE SURFACE (Split Screen Presentation)
// ==========================================================================
class MaterialMasterPage extends StatefulWidget {
  const MaterialMasterPage({super.key});
  @override
  State<MaterialMasterPage> createState() => _MaterialMasterPageState();
}

class _MaterialMasterPageState extends State<MaterialMasterPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();

  // Form Controllers
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _purCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: "1");

  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];
  bool _isInitialPoolLoading = true;

  // Media parameters state containers
  String? _localPickedImageFile;
  Uint8List? _webImageMemoryBytes;
  int? _selectedUomId;
  int? _selectedTypeId;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDropdownMastersPool();
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _codeCtrl.dispose(); _nameCtrl.dispose();
    _rawCtrl.dispose(); _finCtrl.dispose(); _purCtrl.dispose();
    _salesCtrl.dispose(); _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownMastersPool() async {
    try {
      final repo = MaterialMasterRepository();
      final uoms = await repo.getUomsPool();
      final types = await repo.getMaterialTypesPool();
      setState(() {
        _uomsList = uoms;
        _typesList = types;
        _isInitialPoolLoading = false;
        if (_uomsList.isNotEmpty) _selectedUomId = int.tryParse(_uomsList.first['id'].toString());
        if (_typesList.isNotEmpty) _selectedTypeId = int.tryParse(_typesList.first['id'].toString());
      });
    } catch (e) { setState(() => _isInitialPoolLoading = false); }
  }

  void _onSave(MaterialMasterBloc bloc) {
    if (_formKey.currentState!.validate() && _selectedUomId != null && _selectedTypeId != null) {
      final String currentSystemDateString = DateFormat('MM/dd/yyyy').format(DateTime.now());

      bloc.add(AddMat(
          MaterialEntity(
            entryDate: currentSystemDateString,
            materialCode: _codeCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            uomId: _selectedUomId!,
            units: int.tryParse(_unitsCtrl.text.trim()) ?? 1,
            materialTypeId: _selectedTypeId!,
            rawSize: _rawCtrl.text.trim().isEmpty ? null : _rawCtrl.text.trim(),
            finishingSize: _finCtrl.text.trim().isEmpty ? null : _finCtrl.text.trim(),
            purchasePrice: double.tryParse(_purCtrl.text.trim()) ?? 0.0,
            salesPrice: double.tryParse(_salesCtrl.text.trim()) ?? 0.0,
            imagePath: _localPickedImageFile,
            webImageBytes: _webImageMemoryBytes,
          ),
          onSuccess: () {
            _resetForm();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Product Registry Master Sync Complete!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
            );
          }
      ));
    }
  }

  void _resetForm() {
    setState(() {
      _codeCtrl.clear(); _nameCtrl.clear(); _rawCtrl.clear();
      _finCtrl.clear(); _purCtrl.clear(); _salesCtrl.clear();
      _unitsCtrl.text = "1";
      _localPickedImageFile = null;
      _webImageMemoryBytes = null;
      if (_uomsList.isNotEmpty) _selectedUomId = int.tryParse(_uomsList.first['id'].toString());
      if (_typesList.isNotEmpty) _selectedTypeId = int.tryParse(_typesList.first['id'].toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool useSplitView = screenWidth > 950;

    if (_isInitialPoolLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)));
    }

    return BlocProvider(
      create: (c) => MaterialMasterBloc(MaterialMasterRepository())..add(LoadMats()),
      child: Builder(
        builder: (newContext) {
          final bloc = newContext.read<MaterialMasterBloc>();

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ➡️ LEFT SIDE: PERSISTENT DIRECTORY TABLE LIST
                if (useSplitView) _buildLeftDirectoryPane(bloc),

                // ➡️ RIGHT SIDE: MAIN CORE DATA ENTRY CANVAS
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildTopActionBar(useSplitView, bloc),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!useSplitView) ...[
                                    _buildMobileDirectoryButton(bloc),
                                    const SizedBox(height: 12),
                                  ],
                                  _buildFormCard(bloc),
                                ],
                              ),
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
        },
      ),
    );
  }

  Widget _buildLeftDirectoryPane(MaterialMasterBloc bloc) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: const Color(0xFF1E293B),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent, size: 16),
                SizedBox(width: 10),
                Text("PRODUCT DIRECTORY POOL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5))
              ],
            ),
          ),
          // Industrial White Search Box Frame
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade700, width: 0.5),
                borderRadius: BorderRadius.zero,
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                onChanged: (v) => bloc.add(LoadMats(query: v.trim())),
                decoration: const InputDecoration(
                  hintText: "Search items or tokens...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MaterialMasterBloc, MatState>(
              builder: (context, state) {
                if (state is MatLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent));
                }
                if (state is MatLoaded) {
                  if (state.items.isEmpty) {
                    return const Center(child: Text("Zero registries match", style: TextStyle(color: Colors.grey, fontSize: 11)));
                  }

                  final String serverBase = bloc.repo.apiClient.baseUrl;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: state.items.length,
                    itemBuilder: (context, idx) {
                      final item = state.items[idx];
                      return Container(
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5))
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 30, height: 32,
                            decoration: BoxDecoration(color: const Color(0xFF1E293B), border: Border.all(color: Colors.grey.shade800, width: 0.5)),
                            child: _renderInlineGridThumbnail(item.imagePath, serverBase),
                          ),
                          title: Text(item.materialCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.cyanAccent)),
                          subtitle: Text(item.name, style: TextStyle(color: Colors.grey.shade300, fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            onPressed: () => bloc.add(DeleteMat(item.id!)),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text("Directory Sync Error", style: TextStyle(color: Colors.red)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionBar(bool splitView, MaterialMasterBloc bloc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                "NEW PRODUCT DATA MASTER".toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.red),
                label: const Text("RESET FIELDS", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _onSave(bloc),
                icon: const Icon(Icons.save_outlined, size: 14),
                label: Text("SAVE MASTER".toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFormCard(MaterialMasterBloc bloc) {
    final String currentSystemDateString = DateFormat('MM/dd/yyyy').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("1. SYSTEM IDENTIFICATION PARAMETERS"),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("LOG COMPILATION SYSTEM DATE:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Text(currentSystemDateString, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F4C81))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_codeCtrl, "MATERIAL CODE KEY (e.g. MAT001) *", mandatory: true)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _sharpTextField(_nameCtrl, "PRODUCT NAME *", mandatory: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: (_uomsList.any((element) => int.tryParse(element['id'].toString()) == _selectedUomId)) ? _selectedUomId : null,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                decoration: _buildDropdownDecoration("UOM PARAMETER SPEC *"),
                items: _uomsList.map<DropdownMenuItem<int>>((u) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(u['id'].toString()),
                    child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedUomId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_unitsCtrl, "UNITS CONVERSION BOUND TOTAL *", isNum: true, mandatory: true)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: (_typesList.any((element) => int.tryParse(element['id'].toString()) == _selectedTypeId)) ? _selectedTypeId : null,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                decoration: _buildDropdownDecoration("MATERIAL MASTER TYPE *"),
                items: _typesList.map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(t['id'].toString()),
                    child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedTypeId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("2. PHYSICAL GEOMETRY DIMENSIONAL MATRIX"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_rawCtrl, "RAW MATERIAL SIZE (e.g. 100mm)")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_finCtrl, "FINISHING SIZE(e.g. 98mm)")),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("3. COMMERCIAL VALUATION METRICS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_purCtrl, "PURCHASE RATE (₹) *", isNum: true, mandatory: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_salesCtrl, "SALES RATE (₹) *", isNum: true, color: Colors.green, mandatory: true)),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("4. PRODUCT IMAGE CONTROL"),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
            if (image != null) {
              if (kIsWeb) {
                final bytes = await image.readAsBytes();
                setState(() { _webImageMemoryBytes = bytes; _localPickedImageFile = image.path; });
              } else {
                setState(() { _localPickedImageFile = image.path; });
              }
            }
          },
          child: Container(
            width: double.infinity, height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: (_localPickedImageFile != null || _webImageMemoryBytes != null) ? Colors.green.shade400 : Colors.grey.shade300),
            ),
            child: (_localPickedImageFile != null || _webImageMemoryBytes != null)
                ? Stack(
              children: [
                Positioned.fill(
                    child: kIsWeb
                        ? Image.memory(_webImageMemoryBytes!, fit: BoxFit.cover)
                        : Image.file(File(_localPickedImageFile!), fit: BoxFit.cover)
                ),
                Container(color: Colors.black38),
                const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_sharp, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text("ASSET ATTACHMENT SECURED (TAP TO OVERRIDE)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    )
                )
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.blueGrey),
                SizedBox(height: 6),
                Text("TAP TO MAP PRODUCT IMAGE BINARY THROUGH FILESTREAM POOL", style: TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sharpTextField(TextEditingController ctrl, String label, {
    bool isNum = false,
    bool readOnly = false,
    Color? color,
    int maxLines = 1,
    bool mandatory = false,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.black87),
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) && mandatory ? 'Required' : null,
    );
  }

  InputDecoration _buildDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }

  Widget _renderInlineGridThumbnail(String? partialPath, String serverUrl) {
    if (partialPath == null || partialPath.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, size: 14, color: Colors.grey);
    }
    final String completeTargetUrl = partialPath.startsWith('http') ? partialPath : '$serverUrl$partialPath';
    return Image.network(
      completeTargetUrl,
      fit: BoxFit.cover,
      errorBuilder: (c, o, s) => const Icon(Icons.broken_image_outlined, size: 14, color: Colors.redAccent),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1)));
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: const Color(0xFFF1F5F9),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
    );
  }

  Widget _buildMobileDirectoryButton(MaterialMasterBloc bloc) {
    return ElevatedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: _buildLeftDirectoryPane(bloc),
          ),
        );
      },
      icon: const Icon(Icons.list_alt_rounded, size: 14),
      label: const Text("VIEW PRODUCT REGISTRY DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
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

import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL DATA STRUCT ARCHITECTURE
// ==========================================================================
class MaterialEntity {
  final int? id;
  final String entryDate;
  final String materialCode;
  final String name;
  final int uomId;
  final String? uomName;
  final int units;
  final int materialTypeId;
  final String? materialTypeName;
  final String? rawSize;
  final String? finishingSize;
  final double purchasePrice;
  final double salesPrice;
  final String? imagePath;
  final Uint8List? webImageBytes;

  MaterialEntity({
    this.id, required this.entryDate, required this.materialCode, required this.name,
    required this.uomId, this.uomName, required this.units, required this.materialTypeId,
    this.materialTypeName, this.rawSize, this.finishingSize, required this.purchasePrice, required this.salesPrice,
    this.imagePath, this.webImageBytes,
  });

  factory MaterialEntity.fromJson(Map<String, dynamic> json) {
    String formattedDate = "";
    try {
      if (json['entry_date'] != null) {
        DateTime parsedDate = DateTime.parse(json['entry_date'].toString());
        formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
      } else {
        formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
      }
    } catch (_) {
      formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    }

    return MaterialEntity(
      id: json['id'],
      entryDate: formattedDate,
      materialCode: json['material_code'] ?? "",
      name: json['name'] ?? "",
      uomId: json['uom'] ?? 0,
      uomName: json['uom_detail']?['uom_name'] ?? "—",
      units: json['units'] ?? 1,
      materialTypeId: json['material_type'] ?? 0,
      materialTypeName: json['material_type_detail']?['name'] ?? "—",
      rawSize: json['raw_size'],
      finishingSize: json['finishing_size'],
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0,
      salesPrice: double.tryParse(json['sales_price']?.toString() ?? '0') ?? 0.0,
      imagePath: json['image'],
    );
  }

  Map<String, dynamic> toJson() => {
    "entry_date": DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(entryDate)),
    "material_code": materialCode.trim().toUpperCase(),
    "name": name.trim(),
    "uom": uomId,
    "units": units,
    "material_type": materialTypeId,
    "raw_size": rawSize?.trim().isEmpty == true ? null : rawSize?.trim(),
    "finishing_size": finishingSize?.trim().isEmpty == true ? null : finishingSize?.trim(),
    "purchase_price": purchasePrice,
    "sales_price": salesPrice,
  };
}

// ==========================================================================
// 2. REPOSITORY ARCHITECTURE DATA PIPELINE
// ==========================================================================
class MaterialMasterRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<MaterialEntity>> getMaterials({String? query}) async {
    final res = await apiClient.get('/api/erp/materials/', query: query != null ? {'search': query} : null);
    final List d = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data is List ? res.data : [];
    return d.map((x) => MaterialEntity.fromJson(x)).toList();
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

  Future<void> saveWithMultipart(MaterialEntity item) async {
    final bool isUpdate = item.id != null;
    final String path = isUpdate ? '/api/erp/materials/${item.id}/' : '/api/erp/materials/';

    String backendDate = DateTime.now().toString().split(" ")[0];
    try {
      DateTime parsed = DateFormat('dd-MM-yyyy').parse(item.entryDate);
      backendDate = DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {}

    final Map<String, dynamic> requestFields = {
      if (isUpdate) "_method": "PUT", // 🟢 Method override ensures images upload smoothly on update
      "entry_date": backendDate,
      "material_code": item.materialCode.toUpperCase().trim(),
      "name": item.name.trim(),
      "uom": item.uomId.toString(),
      "units": item.units.toString(),
      "material_type": item.materialTypeId.toString(),
      "purchase_price": item.purchasePrice.toString(),
      "sales_price": item.salesPrice.toString(),
      if (item.rawSize != null && item.rawSize!.trim().isNotEmpty) "raw_size": item.rawSize!.trim(),
      if (item.finishingSize != null && item.finishingSize!.trim().isNotEmpty) "finishing_size": item.finishingSize!.trim(),
    };

    await apiClient.postMultipart(
      path,
      fields: requestFields,
      filePath: kIsWeb ? null : item.imagePath,
      webBytes: item.webImageBytes,
      fileKey: "image",
    );
  }

  Future<void> delete(int id) async => await apiClient.delete('/api/erp/materials/$id/');
}

// ==========================================================================
// 3. BLoC BUSINESS PATTERN ENGINE
// ==========================================================================
abstract class MatEvent {}
class LoadMats extends MatEvent { final String? query; LoadMats({this.query}); }
class AddMat extends MatEvent { final MaterialEntity item; final VoidCallback? onSuccess; AddMat(this.item, {this.onSuccess}); }
class DeleteMat extends MatEvent { final int id; DeleteMat(this.id); }

abstract class MatState {}
class MatInitial extends MatState {}
class MatLoading extends MatState {}
class MatLoaded extends MatState { final List<MaterialEntity> items; MatLoaded(this.items); }
class MatError extends MatState { final String msg; MatError(this.msg); }

class MaterialMasterBloc extends Bloc<MatEvent, MatState> {
  final MaterialMasterRepository repo;
  MaterialMasterBloc(this.repo) : super(MatInitial()) {
    on<LoadMats>((e, emit) async {
      emit(MatLoading());
      try { final d = await repo.getMaterials(query: e.query); emit(MatLoaded(d)); }
      catch (err) { emit(MatError(err.toString())); }
    });
    on<AddMat>((e, emit) async {
      try {
        await repo.saveWithMultipart(e.item);
        if (e.onSuccess != null) e.onSuccess!();
        add(LoadMats());
      } catch (err) {
        emit(MatError(err.toString().contains("already exists") ? "Error: Duplicate Material Code not allowed!" : err.toString()));
      }
    });
    on<DeleteMat>((e, emit) async {
      try { await repo.delete(e.id); add(LoadMats()); } catch (_) {}
    });
  }
}

// ==========================================================================
// 4. MAIN WORKSPACE SURFACE (Split Screen Presentation Matrix)
// ==========================================================================
class MaterialMasterPage extends StatefulWidget {
  const MaterialMasterPage({super.key});
  @override
  State<MaterialMasterPage> createState() => _MaterialMasterPageState();
}

class _MaterialMasterPageState extends State<MaterialMasterPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();

  // Form Field Target Controllers
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final _purCtrl = TextEditingController();
  final _salesCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: "1");

  List<Map<String, dynamic>> _uomsList = [];
  List<Map<String, dynamic>> _typesList = [];
  bool _isInitialPoolLoading = true;

  // Media & Tracking State references
  String? _localPickedImageFile;
  Uint8List? _webImageMemoryBytes;
  int? _selectedUomId;
  int? _selectedTypeId;
  final ImagePicker _picker = ImagePicker();

  MaterialEntity? _editingMaterialNode;

  @override
  void initState() {
    super.initState();
    _loadDropdownMastersPool();
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _codeCtrl.dispose(); _nameCtrl.dispose();
    _rawCtrl.dispose(); _finCtrl.dispose(); _purCtrl.dispose();
    _salesCtrl.dispose(); _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownMastersPool() async {
    try {
      final repo = MaterialMasterRepository();
      final uoms = await repo.getUomsPool();
      final types = await repo.getMaterialTypesPool();
      setState(() {
        _uomsList = uoms;
        _typesList = types;
        _isInitialPoolLoading = false;
        if (_uomsList.isNotEmpty) _selectedUomId = int.tryParse(_uomsList.first['id'].toString());
        if (_typesList.isNotEmpty) _selectedTypeId = int.tryParse(_typesList.first['id'].toString());
      });
    } catch (e) { setState(() => _isInitialPoolLoading = false); }
  }

  void _populateFormForEdit(MaterialEntity item) {
    setState(() {
      _editingMaterialNode = item;
      _codeCtrl.text = item.materialCode;
      _nameCtrl.text = item.name;
      _rawCtrl.text = item.rawSize ?? "";
      _finCtrl.text = item.finishingSize ?? "";
      _purCtrl.text = item.purchasePrice.toString();
      _salesCtrl.text = item.salesPrice.toString();
      _unitsCtrl.text = item.units.toString();
      _selectedUomId = item.uomId;
      _selectedTypeId = item.materialTypeId;
      _localPickedImageFile = null;
      _webImageMemoryBytes = null;
    });
  }

  void _onSave(MaterialMasterBloc bloc) {
    if (_formKey.currentState!.validate() && _selectedUomId != null && _selectedTypeId != null) {
      final String entryDateString = _editingMaterialNode?.entryDate ?? DateFormat('dd-MM-yyyy').format(DateTime.now());

      bloc.add(AddMat(
          MaterialEntity(
            id: _editingMaterialNode?.id,
            entryDate: entryDateString,
            materialCode: _codeCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            uomId: _selectedUomId!,
            units: int.tryParse(_unitsCtrl.text.trim()) ?? 1,
            materialTypeId: _selectedTypeId!,
            rawSize: _rawCtrl.text.trim().isEmpty ? null : _rawCtrl.text.trim(),
            finishingSize: _finCtrl.text.trim().isEmpty ? null : _finCtrl.text.trim(),
            purchasePrice: double.tryParse(_purCtrl.text.trim()) ?? 0.0,
            salesPrice: double.tryParse(_salesCtrl.text.trim()) ?? 0.0,
            imagePath: _localPickedImageFile,
            webImageBytes: _webImageMemoryBytes,
          ),
          onSuccess: () {
            _resetForm();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 Product Master Profile Synced Successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
            );
          }
      ));
    }
  }

  void _resetForm() {
    setState(() {
      _editingMaterialNode = null;
      _codeCtrl.clear(); _nameCtrl.clear(); _rawCtrl.clear();
      _finCtrl.clear(); _purCtrl.clear(); _salesCtrl.clear();
      _unitsCtrl.text = "1";
      _localPickedImageFile = null;
      _webImageMemoryBytes = null;
      if (_uomsList.isNotEmpty) _selectedUomId = int.tryParse(_uomsList.first['id'].toString());
      if (_typesList.isNotEmpty) _selectedTypeId = int.tryParse(_typesList.first['id'].toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool useSplitView = screenWidth > 950;

    if (_isInitialPoolLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)));
    }

    return BlocProvider(
      create: (c) => MaterialMasterBloc(MaterialMasterRepository())..add(LoadMats()),
      child: Builder(
        builder: (newContext) {
          final bloc = newContext.read<MaterialMasterBloc>();

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useSplitView) _buildLeftDirectoryPane(bloc),

                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildTopActionBar(useSplitView, bloc),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!useSplitView) ...[
                                    _buildMobileDirectoryButton(bloc),
                                    const SizedBox(height: 12),
                                  ],
                                  _buildFormCard(bloc),
                                ],
                              ),
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
        },
      ),
    );
  }

  Widget _buildLeftDirectoryPane(MaterialMasterBloc bloc) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: const Color(0xFF1E293B),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent, size: 16),
                SizedBox(width: 10),
                Text("PRODUCT DIRECTORY POOL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade700, width: 0.5),
                borderRadius: BorderRadius.zero,
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                onChanged: (v) => bloc.add(LoadMats(query: v.trim())),
                decoration: const InputDecoration(
                  hintText: "Search items or tokens...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MaterialMasterBloc, MatState>(
              builder: (context, state) {
                if (state is MatLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent));
                }
                if (state is MatLoaded) {
                  if (state.items.isEmpty) {
                    return const Center(child: Text("Zero registries match", style: TextStyle(color: Colors.grey, fontSize: 11)));
                  }

                  final String serverBase = bloc.repo.apiClient.baseUrl;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: state.items.length,
                    itemBuilder: (context, idx) {
                      final item = state.items[idx];
                      bool isSelected = _editingMaterialNode?.id == item.id;

                      return Container(
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5))
                        ),
                        child: ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF1E293B),
                          onTap: () => _populateFormForEdit(item),
                          leading: Container(
                            width: 30, height: 32,
                            decoration: BoxDecoration(color: const Color(0xFF1E293B), border: Border.all(color: Colors.grey.shade800, width: 0.5)),
                            child: _renderInlineGridThumbnail(item.imagePath, serverBase),
                          ),
                          title: Text(item.materialCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.cyanAccent : Colors.cyanAccent.shade100)),
                          subtitle: Text(item.name, style: TextStyle(color: Colors.grey.shade300, fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.orangeAccent),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            onPressed: () => _populateFormForEdit(item),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text("Directory Sync Error", style: TextStyle(color: Colors.red)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionBar(bool splitView, MaterialMasterBloc bloc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                (_editingMaterialNode == null ? "NEW PRODUCT DATA MASTER" : "MODIFY MASTER REGISTRY").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
              ),
              if (_editingMaterialNode != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.orange.shade100,
                  child: Text("EDITING ID: ${_editingMaterialNode!.id}", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 9)),
                )
              ]
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.red),
                label: Text(_editingMaterialNode == null ? "RESET FIELDS" : "CANCEL EDIT", style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _onSave(bloc),
                icon: Icon(_editingMaterialNode == null ? Icons.save_outlined : Icons.done_all_rounded, size: 14),
                label: Text((_editingMaterialNode == null ? "SAVE MASTER" : "UPDATE SNAPS").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFormCard(MaterialMasterBloc bloc) {
    final String entryDateString = _editingMaterialNode?.entryDate ?? DateFormat('dd-MM-yyyy').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("1. SYSTEM IDENTIFICATION PARAMETERS"),
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("LOG COMPILATION SYSTEM DATE (DD-MM-YYYY):", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Text(entryDateString, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F4C81))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_codeCtrl, "MATERIAL CODE KEY (e.g. MAT001) *", mandatory: true, readOnly: _editingMaterialNode != null)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _sharpTextField(_nameCtrl, "PRODUCT NAME *", mandatory: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: (_uomsList.any((element) => int.tryParse(element['id'].toString()) == _selectedUomId)) ? _selectedUomId : null,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                decoration: _buildDropdownDecoration("UOM PARAMETER SPEC *"),
                items: _uomsList.map<DropdownMenuItem<int>>((u) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(u['id'].toString()),
                    child: Text(u['uom_name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedUomId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_unitsCtrl, "UNITS CONVERSION BOUND TOTAL *", isNum: true, mandatory: true)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: (_typesList.any((element) => int.tryParse(element['id'].toString()) == _selectedTypeId)) ? _selectedTypeId : null,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                decoration: _buildDropdownDecoration("MATERIAL MASTER TYPE *"),
                items: _typesList.map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(t['id'].toString()),
                    child: Text(t['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedTypeId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("2. PHYSICAL GEOMETRY DIMENSIONAL MATRIX"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_rawCtrl, "RAW MATERIAL SIZE (e.g. 100mm)")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_finCtrl, "FINISHING SIZE(e.g. 98mm)")),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("3. COMMERCIAL VALUATION METRICS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_purCtrl, "PURCHASE RATE (₹) *", isNum: true, mandatory: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_salesCtrl, "SALES RATE (₹) *", isNum: true, color: Colors.green, mandatory: true)),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("4. PRODUCT IMAGE CONTROL"),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
            if (image != null) {
              if (kIsWeb) {
                final bytes = await image.readAsBytes();
                setState(() { _webImageMemoryBytes = bytes; _localPickedImageFile = image.path; });
              } else {
                setState(() { _localPickedImageFile = image.path; });
              }
            }
          },
          child: Container(
            width: double.infinity, height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: (_localPickedImageFile != null || _webImageMemoryBytes != null) ? Colors.green.shade400 : Colors.grey.shade300),
            ),
            child: (_localPickedImageFile != null || _webImageMemoryBytes != null)
                ? Stack(
              children: [
                Positioned.fill(
                    child: kIsWeb
                        ? Image.memory(_webImageMemoryBytes!, fit: BoxFit.cover)
                        : Image.file(File(_localPickedImageFile!), fit: BoxFit.cover)
                ),
                Container(color: Colors.black38),
                const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_sharp, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text("ASSET ATTACHMENT SECURED (TAP TO OVERRIDE)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    )
                )
              ],
            )
                : (_editingMaterialNode?.imagePath != null)
                ? Stack(
              children: [
                Positioned.fill(child: _renderInlineGridThumbnail(_editingMaterialNode!.imagePath, bloc.repo.apiClient.baseUrl)),
                Container(color: Colors.black26),
                const Center(child: Text("CURRENT NETWORK ASSET IMAGE (TAP TO REPLACE)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.blueGrey),
                SizedBox(height: 6),
                Text("TAP TO MAP PRODUCT IMAGE BINARY THROUGH FILESTREAM POOL", style: TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sharpTextField(TextEditingController ctrl, String label, {
    bool isNum = false,
    bool readOnly = false,
    Color? color,
    int maxLines = 1,
    bool mandatory = false,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: readOnly ? Colors.grey.shade600 : (color ?? Colors.black87)),
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) && mandatory ? 'Required' : null,
    );
  }

  InputDecoration _buildDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      // 🟢 FIXED: Replaced BorderSide.none.color crash matrix with direct clear solid primary color
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }

  Widget _renderInlineGridThumbnail(String? partialPath, String serverUrl) {
    if (partialPath == null || partialPath.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, size: 14, color: Colors.grey);
    }
    final String completeTargetUrl = partialPath.startsWith('http') ? partialPath : '$serverUrl$partialPath';
    return Image.network(
      completeTargetUrl,
      fit: BoxFit.cover,
      errorBuilder: (c, o, s) => const Icon(Icons.broken_image_outlined, size: 14, color: Colors.redAccent),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1)));
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: const Color(0xFFF1F5F9),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
    );
  }

  Widget _buildMobileDirectoryButton(MaterialMasterBloc bloc) {
    return ElevatedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: _buildLeftDirectoryPane(bloc),
          ),
        );
      },
      icon: const Icon(Icons.list_alt_rounded, size: 14),
      label: const Text("VIEW PRODUCT REGISTRY DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}