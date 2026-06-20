/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================
class MaterialTypeEntity {
  final int? id;
  final String name;
  final String description;

  MaterialTypeEntity({
    this.id,
    required this.name,
    required this.description,
  });

  factory MaterialTypeEntity.fromJson(Map<String, dynamic> json) => MaterialTypeEntity(
    id: json['id'],
    name: json['name'] ?? "",
    description: json['description'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "name": name.trim().toUpperCase(),
    "description": description.trim(),
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================
class MaterialTypeRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<MaterialTypeEntity>> getMaterialTypes({String? query}) async {
    // Django backend endpoint query router sequence map link
    final response = await apiClient.get(
      '/api/erp/material-types/',
      query: query != null ? {'search': query} : null,
    );

    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data is List ? response.data : [];

    return data.map((x) => MaterialTypeEntity.fromJson(x)).toList();
  }

  Future<void> createMaterialType(MaterialTypeEntity materialType) async {
    await apiClient.post('/api/erp/material-types/', data: materialType.toJson());
  }

  Future<void> updateMaterialType(int id, MaterialTypeEntity materialType) async {
    await apiClient.put('/api/erp/material-types/$id/', data: materialType.toJson());
  }

  Future<void> deleteMaterialType(int id) async {
    await apiClient.delete('/api/erp/material-types/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS, STATES & LOGIC LAYER
// ==========================================================================
abstract class MaterialTypeEvent {}
class LoadMaterialTypes extends MaterialTypeEvent { final String? query; LoadMaterialTypes({this.query}); }
class AddMaterialType extends MaterialTypeEvent { final MaterialTypeEntity materialType; AddMaterialType(this.materialType); }
class EditMaterialType extends MaterialTypeEvent { final int id; final MaterialTypeEntity materialType; EditMaterialType(this.id, this.materialType); }
class DeleteMaterialType extends MaterialTypeEvent { final int id; DeleteMaterialType(this.id); }

abstract class MaterialTypeState {}
class MaterialTypeInitial extends MaterialTypeState {}
class MaterialTypeLoading extends MaterialTypeState {}
class MaterialTypeLoaded extends MaterialTypeState { final List<MaterialTypeEntity> materialTypes; MaterialTypeLoaded(this.materialTypes); }
class MaterialTypeError extends MaterialTypeState { final String message; MaterialTypeError(this.message); }

class MaterialTypeBloc extends Bloc<MaterialTypeEvent, MaterialTypeState> {
  final MaterialTypeRepository repository;

  MaterialTypeBloc(this.repository) : super(MaterialTypeInitial()) {
    on<LoadMaterialTypes>((event, emit) async {
      emit(MaterialTypeLoading());
      try {
        final data = await repository.getMaterialTypes(query: event.query);
        emit(MaterialTypeLoaded(data));
      } catch (e) {
        emit(MaterialTypeError("Failed to synchronize Material Type registries: ${e.toString()}"));
      }
    });

    on<AddMaterialType>((event, emit) async {
      try {
        await repository.createMaterialType(event.materialType);
        add(LoadMaterialTypes());
      } catch (e) { emit(MaterialTypeError("Insertion constraint failure.")); }
    });

    on<EditMaterialType>((event, emit) async {
      try {
        await repository.updateMaterialType(event.id, event.materialType);
        add(LoadMaterialTypes());
      } catch (e) { emit(MaterialTypeError("Modification constraint failure.")); }
    });

    on<DeleteMaterialType>((event, emit) async {
      try {
        await repository.deleteMaterialType(event.id);
        add(LoadMaterialTypes());
      } catch (e) { emit(MaterialTypeError("Deletion reference restriction integrity error.")); }
    });
  }
}

// ==========================================================================
// 4. MAIN VIEW SURFACE: HIGH-DENSITY ERP CANVAS MATCHED WITH UOM DESIGN
// ==========================================================================
class MaterialTypeMasterPage extends StatefulWidget {
  const MaterialTypeMasterPage({super.key});

  @override
  State<MaterialTypeMasterPage> createState() => _MaterialTypeMasterPageState();
}

class _MaterialTypeMasterPageState extends State<MaterialTypeMasterPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;
    const Color industrialSlate = Color(0xFF1E293B);

    return BlocProvider(
      create: (context) => MaterialTypeBloc(MaterialTypeRepository())..add(LoadMaterialTypes()),
      child: Builder(
        builder: (newContext) {
          final bloc = newContext.read<MaterialTypeBloc>();

          return Container(
            color: const Color(0xFFF8FAFB),
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Header Panel Matched with UOM Title Setup
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MATERIAL TYPE MASTER",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: industrialSlate, letterSpacing: 0.3)),
                        const SizedBox(height: 2),
                        Text("Configure industrial processing material categories (COPPER, IRON, BRASS, SS, PNEUMATIC)",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // High Density Operations Control Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 11),
                          onChanged: (val) => bloc.add(LoadMaterialTypes(query: val.trim())),
                          decoration: const InputDecoration(
                            hintText: "Filter categories by key parameters (e.g. COPPER)...",
                            hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                            prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.blueGrey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showFormDialog(newContext, bloc),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text("NEW CATEGORY TYPE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Content Table
                Expanded(
                  child: BlocBuilder<MaterialTypeBloc, MaterialTypeState>(
                    builder: (context, state) {
                      if (state is MaterialTypeLoading) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
                      }
                      if (state is MaterialTypeLoaded) {
                        return _buildIndustrialTable(state.materialTypes, bloc, isMobile);
                      }
                      if (state is MaterialTypeError) {
                        return Center(child: Text(state.message, style: const TextStyle(color: Colors.red, fontSize: 11)));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndustrialTable(List<MaterialTypeEntity> list, MaterialTypeBloc bloc, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("MATERIAL TYPE CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey, letterSpacing: 0.3))),
                Expanded(flex: 4, child: Text("CATEGORY SPECIFICATIONS / REMARKS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey, letterSpacing: 0.3))),
                Expanded(flex: 1, child: Text("MANAGEMENT ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey, letterSpacing: 0.3))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("Zero material configuration categories found in system database.", style: TextStyle(fontSize: 11, color: Colors.grey)))
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) => _buildTypeRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRow(MaterialTypeEntity type, MaterialTypeBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(
                  type.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F4C81), letterSpacing: 0.2)
              )
          ),
          Expanded(
              flex: 4,
              child: Text(
                  type.description.isEmpty ? "—" : type.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155))
              )
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.orange),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showFormDialog(context, bloc, type: type),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeletePrompt(context, bloc, type),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeletePrompt(BuildContext context, MaterialTypeBloc bloc, MaterialTypeEntity type) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text("Confirm Parameter Deletion", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        content: Text("Are you verified to permanently wipe the Category token type: '${type.name}' from data records?", style: const TextStyle(fontSize: 11, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            onPressed: () {
              bloc.add(DeleteMaterialType(type.id!));
              Navigator.pop(ctx);
            },
            child: const Text("YES, EXECUTE WIPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, MaterialTypeBloc bloc, {MaterialTypeEntity? type}) {
    final nameController = TextEditingController(text: type?.name);
    final descController = TextEditingController(text: type?.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type == null ? "Initialize New Material Type" : "Modify Material Type Configuration",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),

                _buildField(
                    nameController,
                    "MATERIAL TYPE KEY (e.g. COPPER)",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Material type name parameter cannot be blank." : null
                ),
                const SizedBox(height: 12),
                _buildField(descController, "CATEGORY DESCRIPTION REGISTERED", maxLines: 2, isRequired: false),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final entity = MaterialTypeEntity(
                            name: nameController.text.trim().toUpperCase(),
                            description: descController.text.trim(),
                          );
                          if (type == null) {
                            bloc.add(AddMaterialType(entity));
                          } else {
                            bloc.add(EditMaterialType(type.id!, entity));
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("COMMIT REGISTRY UNIT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {int maxLines = 1, String? Function(String?)? validator, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        isDense: true,
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================
class MaterialTypeEntity {
  final int? id;
  final String name;
  final String description;

  MaterialTypeEntity({
    this.id,
    required this.name,
    required this.description,
  });

  factory MaterialTypeEntity.fromJson(Map<String, dynamic> json) => MaterialTypeEntity(
    id: json['id'],
    name: json['name'] ?? "",
    description: json['description'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "name": name.trim().toUpperCase(),
    "description": description.trim(),
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================
class MaterialTypeRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<MaterialTypeEntity>> getMaterialTypes({String? query}) async {
    final response = await apiClient.get(
      '/api/erp/material-types/',
      query: query != null ? {'search': query} : null,
    );

    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data is List ? response.data : [];

    return data.map((x) => MaterialTypeEntity.fromJson(x)).toList();
  }

  Future<void> createMaterialType(MaterialTypeEntity materialType) async {
    await apiClient.post('/api/erp/material-types/', data: materialType.toJson());
  }

  Future<void> updateMaterialType(int id, MaterialTypeEntity materialType) async {
    await apiClient.put('/api/erp/material-types/$id/', data: materialType.toJson());
  }

  Future<void> deleteMaterialType(int id) async {
    await apiClient.delete('/api/erp/material-types/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS, STATES & LOGIC LAYER
// ==========================================================================
abstract class MaterialTypeEvent {}
class LoadMaterialTypes extends MaterialTypeEvent { final String? query; LoadMaterialTypes({this.query}); }
class AddMaterialType extends MaterialTypeEvent { final MaterialTypeEntity materialType; AddMaterialType(this.materialType); }
class EditMaterialType extends MaterialTypeEvent { final int id; final MaterialTypeEntity materialType; EditMaterialType(this.id, this.materialType); }
class DeleteMaterialTypeEvent extends MaterialTypeEvent { final int id; DeleteMaterialTypeEvent(this.id); }

abstract class MaterialTypeState {}
class MaterialTypeInitial extends MaterialTypeState {}
class MaterialTypeLoading extends MaterialTypeState {}
class MaterialTypeLoaded extends MaterialTypeState { final List<MaterialTypeEntity> materialTypes; MaterialTypeLoaded(this.materialTypes); }
class MaterialTypeError extends MaterialTypeState { final String message; MaterialTypeError(this.message); }

class MaterialTypeBloc extends Bloc<MaterialTypeEvent, MaterialTypeState> {
  final MaterialTypeRepository repository;

  MaterialTypeBloc(this.repository) : super(MaterialTypeInitial()) {
    on<LoadMaterialTypes>((event, emit) async {
      emit(MaterialTypeLoading());
      try {
        final data = await repository.getMaterialTypes(query: event.query);
        emit(MaterialTypeLoaded(data));
      } catch (e) {
        emit(MaterialTypeError("Failed to synchronize Material Type registries: ${e.toString()}"));
      }
    });

    on<AddMaterialType>((event, emit) async {
      try {
        await repository.createMaterialType(event.materialType);
        add(LoadMaterialTypes());
      } catch (e) { emit(MaterialTypeError("Insertion constraint failure.")); }
    });

    on<EditMaterialType>((event, emit) async {
      try {
        await repository.updateMaterialType(event.id, event.materialType);
        add(LoadMaterialTypes());
      } catch (e) { emit(MaterialTypeError("Modification constraint failure.")); }
    });

    on<DeleteMaterialTypeEvent>((event, emit) async {
      try {
        await repository.deleteMaterialType(event.id);
        add(LoadMaterialTypes());
      } catch (e) { emit(MaterialTypeError("Deletion reference restriction integrity error.")); }
    });
  }
}

// ==========================================================================
// 4. MAIN VIEW SURFACE: SPLIT HIGH-DENSITY ERP CANVAS
// ==========================================================================
class MaterialTypeMasterPage extends StatefulWidget {
  const MaterialTypeMasterPage({super.key});

  @override
  State<MaterialTypeMasterPage> createState() => _MaterialTypeMasterPageState();
}

class _MaterialTypeMasterPageState extends State<MaterialTypeMasterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  MaterialTypeEntity? editingType;

  void _onSave(MaterialTypeBloc bloc) {
    if (_formKey.currentState!.validate()) {
      final entity = MaterialTypeEntity(
        name: _nameCtrl.text.trim().toUpperCase(),
        description: _descCtrl.text.trim(),
      );

      if (editingType == null) {
        bloc.add(AddMaterialType(entity));
      } else {
        bloc.add(EditMaterialType(editingType!.id!, entity));
      }
      _resetForm();
      _showSnackbar("Category parameters saved successfully!", Colors.green);
    }
  }

  void _populateForm(MaterialTypeEntity item) {
    setState(() {
      editingType = item;
      _nameCtrl.text = item.name;
      _descCtrl.text = item.description;
    });
  }

  void _resetForm() {
    setState(() {
      editingType = null;
      _nameCtrl.clear();
      _descCtrl.clear();
    });
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool useSplitView = screenWidth > 800;

    return BlocProvider(
      create: (context) => MaterialTypeBloc(MaterialTypeRepository())..add(LoadMaterialTypes()),
      child: Builder(
        builder: (newContext) {
          final bloc = newContext.read<MaterialTypeBloc>();

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ➡️ LEFT SIDE: PERSISTENT DIRECTORY BAR
                if (useSplitView) _buildLeftDirectoryPane(bloc),

                // ➡️ RIGHT SIDE: MAIN FORM DATA MATRIX WORKspace
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

  Widget _buildLeftDirectoryPane(MaterialTypeBloc bloc) {
    return Container(
      width: 320,
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
                Text("MATERIAL SYSTEM TYPES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
              ],
            ),
          ),
          // Clean Light Industrial Search Bar
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
                onChanged: (v) => bloc.add(LoadMaterialTypes(query: v.trim())),
                decoration: const InputDecoration(
                  hintText: "Filter categories (e.g. COPPER)...",
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
            child: BlocBuilder<MaterialTypeBloc, MaterialTypeState>(
              builder: (context, state) {
                if (state is MaterialTypeLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent));
                }
                if (state is MaterialTypeLoaded) {
                  if (state.materialTypes.isEmpty) {
                    return const Center(child: Text("Zero categories mapped", style: TextStyle(color: Colors.grey, fontSize: 11)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: state.materialTypes.length,
                    itemBuilder: (context, idx) {
                      final item = state.materialTypes[idx];
                      bool isSelected = editingType?.id == item.id;
                      return ListTile(
                        onTap: () => _populateForm(item),
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF1E293B),
                        title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.cyanAccent : Colors.white)),
                        subtitle: Text(item.description.isEmpty ? "No specification description" : item.description, style: TextStyle(color: Colors.grey.shade400, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                          onPressed: () => _showDeletePrompt(context, bloc, item),
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

  Widget _buildTopActionBar(bool splitView, MaterialTypeBloc bloc) {
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
                (editingType == null ? "NEW TYPE PARAMETER" : "MODIFY TYPE DETAILS").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          Row(
            children: [
              if (editingType != null)
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.red),
                  label: const Text("CANCEL", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _onSave(bloc),
                icon: Icon(editingType == null ? Icons.save_outlined : Icons.done_all_rounded, size: 14),
                label: Text((editingType == null ? "SAVE TYPE" : "UPDATE").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildFormCard(MaterialTypeBloc bloc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: const Color(0xFFF1F5F9),
          child: const Text("1. MATERIAL CLASSIFICATION TOKENS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _sharpTextField(
                _nameCtrl,
                "MATERIAL TYPE KEY CODE (e.g. COPPER, BRASS) *",
                validator: (v) => (v == null || v.trim().isEmpty) ? "Material type token name cannot be blank." : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: const Color(0xFFF1F5F9),
          child: const Text("2. CATEGORY SPECIFICATION SPEC SHEET REMARKS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
        ),
        const SizedBox(height: 12),
        _sharpTextField(_descCtrl, "CATEGORY DESCRIPTION REGISTERED", maxLines: 3),
      ],
    );
  }

  Widget _sharpTextField(TextEditingController ctrl, String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _showDeletePrompt(BuildContext context, MaterialTypeBloc bloc, MaterialTypeEntity type) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Confirm Parameter Deletion", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        content: Text("Are you verified to permanently remove the Material Type token sequence: '${type.name}' from database registries?", style: const TextStyle(fontSize: 11, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.blue))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: const RoundedRectangleBorder()),
            onPressed: () {
              bloc.add(DeleteMaterialTypeEvent(type.id!));
              Navigator.pop(ctx);
              _resetForm();
              _showSnackbar("Wipe operation complete.", Colors.redAccent);
            },
            child: const Text("YES, EXECUTE WIPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDirectoryButton(MaterialTypeBloc bloc) {
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
      label: const Text("VIEW MATERIAL TYPES DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}