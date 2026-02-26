import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/location_bloc.dart'; // Adjust path

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch locations on initialization
    context.read<LocationBloc>().add(LoadLocations());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LocationBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Location Management",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage your raw material and item locations",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => bloc.add(LoadLocations(query: val)),
                  decoration: InputDecoration(
                      hintText: "Search Location...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none
                      )
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context, bloc),
                icon: const Icon(Icons.add),
                label: const Text("New Location"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                if (state is LocationLoading) return const Center(child: CircularProgressIndicator());
                if (state is LocationLoaded) return _buildTable(state.locations, bloc);
                if (state is LocationError) return Center(child: Text(state.message));
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<LocationEntity> list, LocationBloc bloc) {
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
                Expanded(flex: 3, child: Text("LOCATION NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("No location found"))
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildLocationRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(LocationEntity location, LocationBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(location.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange),
                    onPressed: () => _showFormDialog(context, bloc, location: location)
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context, location.id!, bloc)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, LocationBloc bloc, {LocationEntity? location}) {
    final nameController = TextEditingController(text: location?.name);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(location == null ? "New Inventory Location" : "Edit Location",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildField(nameController, "Location Name"),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel")
                      )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final entity = LocationEntity(
                            name: nameController.text,
                          );
                          if (location == null) {
                            bloc.add(AddLocation(entity));
                          } else {
                            bloc.add(EditLocation(location.id!, entity));
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Save Location"),
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

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, LocationBloc bloc) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Location?"),
          content: const Text("Are you sure? Items currently assigned here will no longer have a valid location link."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  bloc.add(DeleteLocation(id));
                  Navigator.pop(ctx);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red))
            ),
          ],
        )
    );
  }
}