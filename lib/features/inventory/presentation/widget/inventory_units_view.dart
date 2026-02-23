import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// --- Unit Model & Entity ---
class InventoryUnitEntity {
  final int? id;
  final String name;
  final String shortName;

  InventoryUnitEntity({this.id, required this.name, required this.shortName});

  factory InventoryUnitEntity.fromJson(Map<String, dynamic> json) =>
      InventoryUnitEntity(id: json['id'], name: json['name'], shortName: json['short_name']);

  Map<String, dynamic> toJson() => {"name": name, "short_name": shortName};
}

// --- Unit Repository ---
class InventoryUnitRepository {
  final ApiClient apiClient = sl<ApiClient>();
  Future<List<InventoryUnitEntity>> getUnits() async {
    final res = await apiClient.get('/api/inventory/units/');
    final List data = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data;
    return data.map((x) => InventoryUnitEntity.fromJson(x)).toList();
  }
  Future<void> createUnit(InventoryUnitEntity unit) async => await apiClient.post('/api/inventory/units/', data: unit.toJson());
  Future<void> updateUnit(int id, InventoryUnitEntity unit) async => await apiClient.put('/api/inventory/units/$id/', data: unit.toJson());
  Future<void> deleteUnit(int id) async => await apiClient.delete('/api/inventory/units/$id/');
}

// --- Unit Bloc ---
abstract class InvUnitEvent {}
class LoadInvUnits extends InvUnitEvent {}
class AddInvUnit extends InvUnitEvent { final InventoryUnitEntity unit; AddInvUnit(this.unit); }
class EditInvUnit extends InvUnitEvent { final int id; final InventoryUnitEntity unit; EditInvUnit(this.id, this.unit); }
class DeleteInvUnit extends InvUnitEvent { final int id; DeleteInvUnit(this.id); }

abstract class InvUnitState {}
class InvUnitLoading extends InvUnitState {}
class InvUnitLoaded extends InvUnitState { final List<InventoryUnitEntity> units; InvUnitLoaded(this.units); }
class InvUnitError extends InvUnitState { final String msg; InvUnitError(this.msg); }

class InventoryUnitBloc extends Bloc<InvUnitEvent, InvUnitState> {
  final InventoryUnitRepository repo;
  InventoryUnitBloc(this.repo) : super(InvUnitLoading()) {
    on<LoadInvUnits>((event, emit) async {
      emit(InvUnitLoading());
      try { emit(InvUnitLoaded(await repo.getUnits())); } catch (e) { emit(InvUnitError(e.toString())); }
    });
    on<AddInvUnit>((event, emit) async { try { await repo.createUnit(event.unit); add(LoadInvUnits()); } catch (e) {} });
    on<EditInvUnit>((event, emit) async { try { await repo.updateUnit(event.id, event.unit); add(LoadInvUnits()); } catch (e) {} });
    on<DeleteInvUnit>((event, emit) async { try { await repo.deleteUnit(event.id); add(LoadInvUnits()); } catch (e) {} });
  }
}

// --- Unit UI View ---
class UnitView extends StatefulWidget {
  const UnitView({super.key});
  @override
  State<UnitView> createState() => _UnitViewState();
}

class _UnitViewState extends State<UnitView> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryUnitBloc>().add(LoadInvUnits());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InventoryUnitBloc>();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Unit Measurement",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text("Define smallest and bulk units for your inventory",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUnitDialog(context, bloc),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("ADD NEW UNIT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C24), // 💡 Black Style Button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),

            // --- Grid of Units ---
            Expanded(
              child: BlocBuilder<InventoryUnitBloc, InvUnitState>(
                builder: (context, state) {
                  if (state is InvUnitLoading) return const Center(child: CircularProgressIndicator());
                  if (state is InvUnitLoaded) {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 items in a row
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: state.units.length,
                      itemBuilder: (context, i) => _buildUnitCard(state.units[i], bloc),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Advanced Unit Card ---
  Widget _buildUnitCard(InventoryUnitEntity unit, InventoryUnitBloc bloc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // 1. Icon Section (Fixed Width)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.scale, color: Color(0xFF00BCD4), size: 20),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // 💡 Lamba name hone par "..." dikhayega
                ),
                Text(
                  unit.shortName,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(Icons.edit_outlined, Colors.blue, () => _showUnitDialog(context, bloc, unit: unit)),
              _actionBtn(Icons.delete_outline, Colors.redAccent, () => bloc.add(DeleteInvUnit(unit.id!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
      ),
    );
  }
  void _showUnitDialog(BuildContext context, InventoryUnitBloc bloc, {InventoryUnitEntity? unit}) {
    final name = TextEditingController(text: unit?.name);
    final short = TextEditingController(text: unit?.shortName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(unit == null ? "Create New Unit" : "Update Unit", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Define units like Grams (g) for smallest use or Box for bulk.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: name,
              decoration: InputDecoration(
                  labelText: "Full Name",
                  hintText: "e.g. Kilogram",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: short,
              decoration: InputDecoration(
                  labelText: "Symbol / Short Name",
                  hintText: "e.g. kg",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1C24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () {
                final entity = InventoryUnitEntity(name: name.text, shortName: short.text);
                unit == null ? bloc.add(AddInvUnit(entity)) : bloc.add(EditInvUnit(unit.id!, entity));
                Navigator.pop(ctx);
              },
              child: const Text("SAVE UNIT")
          ),
        ],
      ),
    );
  }
}