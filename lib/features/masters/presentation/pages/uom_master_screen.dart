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

  factory UomEntity.fromJson(Map<String, dynamic> json) =>
      UomEntity(
        id: json['id'],
        uomName: json['uom_name'] ?? "",
        description: json['description'] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "uom_name": uomName,
    "description": description,
  };
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================

class UomRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<UomEntity>> getUoms({String? query}) async {
    final response = await apiClient.get(
      '/api/master/uom/', // Adjust endpoint as per your urls.py
      query: query != null ? {'search': query} : null,
    );

    // Handling Django Pagination 'results' key
    final List data = (response.data is Map && response.data.containsKey('results'))
        ? response.data['results']
        : response.data;

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
// 3. BLOC EVENTS, STATES & LOGIC
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
      } catch (e) { emit(UomError(e.toString())); }
    });

    on<AddUom>((event, emit) async {
      try {
        await repository.createUom(event.uom);
        add(LoadUoms());
      } catch (e) { emit(UomError("Failed to add UOM")); }
    });

    on<EditUom>((event, emit) async {
      try {
        await repository.updateUom(event.id, event.uom);
        add(LoadUoms());
      } catch (e) { emit(UomError("Failed to update UOM")); }
    });

    on<DeleteUom>((event, emit) async {
      try {
        await repository.deleteUom(event.id);
        add(LoadUoms());
      } catch (e) { emit(UomError("Failed to delete UOM")); }
    });
  }
}


class UomView extends StatefulWidget {
  const UomView({super.key});

  @override
  State<UomView> createState() => _UomViewState();
}

class _UomViewState extends State<UomView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UomBloc>().add(LoadUoms());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UomBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Unit of Measurement (UOM)",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage units like PCS, KGS, ROLL, etc.",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => bloc.add(LoadUoms(query: val)),
                  decoration: InputDecoration(
                      hintText: "Search UOM (e.g. KGS)...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context, bloc),
                icon: const Icon(Icons.add),
                label: const Text("New UOM"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<UomBloc, UomState>(
              builder: (context, state) {
                if (state is UomLoading) return const Center(child: CircularProgressIndicator());
                if (state is UomLoaded) return _buildTable(state.uoms, bloc);
                if (state is UomError) return Center(child: Text(state.message));
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<UomEntity> list, UomBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("UOM NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 4, child: Text("DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("No UOM found"))
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildUomRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUomRow(UomEntity uom, UomBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(uom.uomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent))),
          Expanded(flex: 4, child: Text(uom.description, style: const TextStyle(fontSize: 14, color: Colors.black87))),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange),
                    onPressed: () => _showFormDialog(context, bloc, uom: uom)),
                IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => bloc.add(DeleteUom(uom.id!))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, UomBloc bloc, {UomEntity? uom}) {
    final nameController = TextEditingController(text: uom?.uomName);
    final descController = TextEditingController(text: uom?.description);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(uom == null ? "Create New UOM" : "Edit UOM Details",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildField(nameController, "UOM Name (e.g. PCS)"),
              const SizedBox(height: 16),
              _buildField(descController, "Short Description", maxLines: 2),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final entity = UomEntity(
                            uomName: nameController.text.toUpperCase(),
                            description: descController.text,
                          );
                          if (uom == null) {
                            bloc.add(AddUom(entity));
                          } else {
                            bloc.add(EditUom(uom.id!, entity));
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Save UOM"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
    );
  }
}