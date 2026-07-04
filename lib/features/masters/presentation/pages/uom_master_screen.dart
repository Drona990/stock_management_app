/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. ENTITY & MODEL LAYER
// ==========================================================================
class UomEntity {
  final int? id;
  final String uomName;
  final String description;

  UomEntity({
    this.id,
    required this.uomName,
    required this.description,
  });

  factory UomEntity.fromJson(Map<String, dynamic> json) => UomEntity(
    id: json['id'],
    uomName: json['uom_name'] ?? "",
    description: json['description'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "uom_name": uomName.trim().toUpperCase(),
    "description": description.trim(),
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================
class UomRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<UomEntity>> getUoms({String? query}) async {
    final response = await apiClient.get(
      '/api/master/uom/',
      query: query != null ? {'search': query} : null,
    );

    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data is List ? response.data : [];

    return data.map((x) => UomEntity.fromJson(x)).toList();
  }

  Future<void> createUom(UomEntity uom) async {
    await apiClient.post('/api/master/uom/', data: uom.toJson());
  }

  Future<void> updateUom(int id, UomEntity uom) async {
    await apiClient.put('/api/master/uom/$id/', data: uom.toJson());
  }

  Future<void> deleteUom(int id) async {
    await apiClient.delete('/api/master/uom/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS, STATES & LOGIC LAYER
// ==========================================================================
abstract class UomEvent {}
class LoadUoms extends UomEvent { final String? query; LoadUoms({this.query}); }
class AddUom extends UomEvent { final UomEntity uom; AddUom(this.uom); }
class EditUom extends UomEvent { final int id; final UomEntity uom; EditUom(this.id, this.uom); }
class DeleteUom extends UomEvent { final int id; DeleteUom(this.id); }

abstract class UomState {}
class UomInitial extends UomState {}
class UomLoading extends UomState {}
class UomLoaded extends UomState { final List<UomEntity> uoms; UomLoaded(this.uoms); }
class UomError extends UomState { final String message; UomError(this.message); }

class UomBloc extends Bloc<UomEvent, UomState> {
  final UomRepository repository;

  UomBloc(this.repository) : super(UomInitial()) {
    on<LoadUoms>((event, emit) async {
      emit(UomLoading());
      try {
        final data = await repository.getUoms(query: event.query);
        emit(UomLoaded(data));
      } catch (e) {
        emit(UomError("Failed to synchronize UOM registries: ${e.toString()}"));
      }
    });

    on<AddUom>((event, emit) async {
      try {
        await repository.createUom(event.uom);
        add(LoadUoms());
      } catch (e) { emit(UomError("Insertion constraint failure.")); }
    });

    on<EditUom>((event, emit) async {
      try {
        await repository.updateUom(event.id, event.uom);
        add(LoadUoms());
      } catch (e) { emit(UomError("Modification constraint failure.")); }
    });

    on<DeleteUom>((event, emit) async {
      try {
        await repository.deleteUom(event.id);
        add(LoadUoms());
      } catch (e) { emit(UomError("Deletion reference restriction integrity error.")); }
    });
  }
}

// ==========================================================================
// 4. MAIN VIEW SURFACE: HIGH-DENSITY ERP CANVAS
// ==========================================================================
class UomView extends StatefulWidget {
  const UomView({super.key});

  @override
  State<UomView> createState() => _UomViewState();
}

class _UomViewState extends State<UomView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;
    const Color industrialSlate = Color(0xFF1E293B);

    return BlocProvider(
      create: (context) => UomBloc(UomRepository())..add(LoadUoms()),
      child: Builder(
        builder: (newContext) {
          final bloc = newContext.read<UomBloc>();

          return Container(
            color: const Color(0xFFF8FAFB),
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Header Panel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("UNIT OF MEASUREMENT MASTER",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: industrialSlate, letterSpacing: 0.3)),
                        const SizedBox(height: 2),
                        Text("Manage system parameters units allocation matrix (PCS, KGS, ROLL, BAG)",
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
                          onChanged: (val) => bloc.add(LoadUoms(query: val.trim())),
                          decoration: const InputDecoration(
                            hintText: "Filter units by key parameters (e.g. KGS)...",
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
                      label: const Text("NEW REGISTRY UNIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

                // Main Content Records Tree Grid
                Expanded(
                  child: BlocBuilder<UomBloc, UomState>(
                    builder: (context, state) {
                      if (state is UomLoading) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
                      }
                      if (state is UomLoaded) {
                        return _buildIndustrialTable(state.uoms, bloc, isMobile);
                      }
                      if (state is UomError) {
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

  Widget _buildIndustrialTable(List<UomEntity> list, UomBloc bloc, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // High Density Header Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("UOM TOKENS CODE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey, letterSpacing: 0.3))),
                Expanded(flex: 4, child: Text("UNIT DESCRIPTION DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey, letterSpacing: 0.3))),
                Expanded(flex: 1, child: Text("MANAGEMENT ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey, letterSpacing: 0.3))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("Zero operational metrics mapped in system records.", style: TextStyle(fontSize: 11, color: Colors.grey)))
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) => _buildUomRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUomRow(UomEntity uom, UomBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(
                  uom.uomName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F4C81), letterSpacing: 0.2)
              )
          ),
          Expanded(
              flex: 4,
              child: Text(
                  uom.description.isEmpty ? "—" : uom.description,
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
                  onPressed: () => _showFormDialog(context, bloc, uom: uom),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeletePrompt(context, bloc, uom),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ACCIDENT-PROOF INDUSTRIAL DELETE DIALOG MATRIX ---
  Future<void> _showDeletePrompt(BuildContext context, UomBloc bloc, UomEntity uom) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text("Confirm Parameter Deletion", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        content: Text("Are you verified to permanently remove the UOM token sequence: '${uom.uomName}' from database registries?", style: const TextStyle(fontSize: 11, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            onPressed: () {
              bloc.add(DeleteUom(uom.id!));
              Navigator.pop(ctx);
            },
            child: const Text("YES, EXECUTE WIPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, UomBloc bloc, {UomEntity? uom}) {
    final nameController = TextEditingController(text: uom?.uomName);
    final descController = TextEditingController(text: uom?.description);
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
                Text(uom == null ? "Initialize New UOM Token" : "Modify Registry UOM Specifications",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),

                _buildField(
                    nameController,
                    "UOM TOKEN CODE (e.g. PCS)",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "UOM parameter code cannot be blank." : null
                ),
                const SizedBox(height: 12),
                _buildField(descController, "UNIT DESCRIPTION REGISTERED", maxLines: 2, isRequired: false),
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
                          final entity = UomEntity(
                            uomName: nameController.text.trim().toUpperCase(),
                            description: descController.text.trim(),
                          );
                          if (uom == null) {
                            bloc.add(AddUom(entity));
                          } else {
                            bloc.add(EditUom(uom.id!, entity));
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
class UomEntity {
  final int? id;
  final String uomName;
  final String description;

  UomEntity({
    this.id,
    required this.uomName,
    required this.description,
  });

  factory UomEntity.fromJson(Map<String, dynamic> json) => UomEntity(
    id: json['id'],
    uomName: json['uom_name'] ?? "",
    description: json['description'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "uom_name": uomName.trim().toUpperCase(),
    "description": description.trim(),
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================
class UomRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<UomEntity>> getUoms({String? query}) async {
    final response = await apiClient.get(
      '/api/master/uom/',
      query: query != null ? {'search': query} : null,
    );

    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data is List ? response.data : [];

    return data.map((x) => UomEntity.fromJson(x)).toList();
  }

  Future<void> createUom(UomEntity uom) async {
    await apiClient.post('/api/master/uom/', data: uom.toJson());
  }

  Future<void> updateUom(int id, UomEntity uom) async {
    await apiClient.put('/api/master/uom/$id/', data: uom.toJson());
  }

  Future<void> deleteUom(int id) async {
    await apiClient.delete('/api/master/uom/$id/');
  }
}

// ==========================================================================
// 3. BLOC EVENTS, STATES & LOGIC LAYER
// ==========================================================================
abstract class UomEvent {}
class LoadUoms extends UomEvent { final String? query; LoadUoms({this.query}); }
class AddUom extends UomEvent { final UomEntity uom; AddUom(this.uom); }
class EditUom extends UomEvent { final int id; final UomEntity uom; EditUom(this.id, this.uom); }
class DeleteUomEvent extends UomEvent { final int id; DeleteUomEvent(this.id); }

abstract class UomState {}
class UomInitial extends UomState {}
class UomLoading extends UomState {}
class UomLoaded extends UomState { final List<UomEntity> uoms; UomLoaded(this.uoms); }
class UomError extends UomState { final String message; UomError(this.message); }

class UomBloc extends Bloc<UomEvent, UomState> {
  final UomRepository repository;

  UomBloc(this.repository) : super(UomInitial()) {
    on<LoadUoms>((event, emit) async {
      emit(UomLoading());
      try {
        final data = await repository.getUoms(query: event.query);
        emit(UomLoaded(data));
      } catch (e) {
        emit(UomError("Failed to synchronize UOM registries: ${e.toString()}"));
      }
    });

    on<AddUom>((event, emit) async {
      try {
        await repository.createUom(event.uom);
        add(LoadUoms());
      } catch (e) { emit(UomError("Insertion constraint failure.")); }
    });

    on<EditUom>((event, emit) async {
      try {
        await repository.updateUom(event.id, event.uom);
        add(LoadUoms());
      } catch (e) { emit(UomError("Modification constraint failure.")); }
    });

    on<DeleteUomEvent>((event, emit) async {
      try {
        await repository.deleteUom(event.id);
        add(LoadUoms());
      } catch (e) { emit(UomError("Deletion reference restriction integrity error.")); }
    });
  }
}

// ==========================================================================
// 4. MAIN VIEW SURFACE: SPLIT HIGH-DENSITY ERP CANVAS
// ==========================================================================
class UomView extends StatefulWidget {
  const UomView({super.key});

  @override
  State<UomView> createState() => _UomViewState();
}

class _UomViewState extends State<UomView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  UomEntity? editingUom;

  void _onSave(UomBloc bloc) {
    if (_formKey.currentState!.validate()) {
      final entity = UomEntity(
        uomName: _nameCtrl.text.trim().toUpperCase(),
        description: _descCtrl.text.trim(),
      );

      if (editingUom == null) {
        bloc.add(AddUom(entity));
      } else {
        bloc.add(EditUom(editingUom!.id!, entity));
      }
      _resetForm();
      _showSnackbar("Transaction committed successfully!", Colors.green);
    }
  }

  void _populateForm(UomEntity item) {
    setState(() {
      editingUom = item;
      _nameCtrl.text = item.uomName;
      _descCtrl.text = item.description;
    });
  }

  void _resetForm() {
    setState(() {
      editingUom = null;
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
      create: (context) => UomBloc(UomRepository())..add(LoadUoms()),
      child: Builder(
        builder: (newContext) {
          final bloc = newContext.read<UomBloc>();

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ➡️ LEFT SIDE: PERSISTENT DIRECTORY PANE
                if (useSplitView) _buildLeftDirectoryPane(bloc),

                // ➡️ RIGHT SIDE: MAIN OPERATIONS PANEL
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

  Widget _buildLeftDirectoryPane(UomBloc bloc) {
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
                Text("UOM REGISTRY TOKENS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
              ],
            ),
          ),
          // Industrial Light Background Search Frame
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
                onChanged: (v) => bloc.add(LoadUoms(query: v.trim())),
                decoration: const InputDecoration(
                  hintText: "Filter units (e.g. KGS)...",
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
            child: BlocBuilder<UomBloc, UomState>(
              builder: (context, state) {
                if (state is UomLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent));
                }
                if (state is UomLoaded) {
                  if (state.uoms.isEmpty) {
                    return const Center(child: Text("Zero metrics found", style: TextStyle(color: Colors.grey, fontSize: 11)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: state.uoms.length,
                    itemBuilder: (context, idx) {
                      final item = state.uoms[idx];
                      bool isSelected = editingUom?.id == item.id;

                      // Wrap the ListTile in a Material widget to resolve the painting assertion
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => _populateForm(item),
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF1E293B),
                          title: Text(
                              item.uomName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isSelected ? Colors.cyanAccent : Colors.white
                              )
                          ),
                          subtitle: Text(
                              item.description.isEmpty ? "No description mapped" : item.description,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                            onPressed: () => _showDeletePrompt(context, bloc, item),
                          ),
                        ),
                      );
                    },
                  );                }
                return const Center(child: Text("Directory Sync Error", style: TextStyle(color: Colors.red)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionBar(bool splitView, UomBloc bloc) {
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
                (editingUom == null ? "NEW UNIT PARAMETER" : "MODIFY UOM DETAILS").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
              ),
            ],
          ),
          Row(
            children: [
              if (editingUom != null)
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.red),
                  label: const Text("CANCEL", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _onSave(bloc),
                icon: Icon(editingUom == null ? Icons.save_outlined : Icons.done_all_rounded, size: 14),
                label: Text((editingUom == null ? "SAVE UOM" : "UPDATE").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildFormCard(UomBloc bloc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: const Color(0xFFF1F5F9),
          child: const Text("1. METRIC CODE MAPPING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _sharpTextField(
                _nameCtrl,
                "UOM TOKEN CODE (e.g. PCS, KGS) *",
                validator: (v) => (v == null || v.trim().isEmpty) ? "UOM parameter code cannot be blank." : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: const Color(0xFFF1F5F9),
          child: const Text("2. DATA DEFINITION SPECIFICATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
        ),
        const SizedBox(height: 12),
        _sharpTextField(_descCtrl, "UNIT DESCRIPTION REGISTERED", maxLines: 3),
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

  Future<void> _showDeletePrompt(BuildContext context, UomBloc bloc, UomEntity uom) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Confirm Parameter Deletion", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        content: Text("Are you verified to permanently remove the UOM token sequence: '${uom.uomName}' from database registries?", style: const TextStyle(fontSize: 11, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.blue))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: const RoundedRectangleBorder()),
            onPressed: () {
              bloc.add(DeleteUomEvent(uom.id!));
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

  Widget _buildMobileDirectoryButton(UomBloc bloc) {
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
      label: const Text("VIEW UOM TOKENS DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}