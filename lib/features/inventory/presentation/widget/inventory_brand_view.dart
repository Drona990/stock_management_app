import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_brand_block.dart';

class BrandView extends StatefulWidget {
  const BrandView({super.key});

  @override
  State<BrandView> createState() => _BrandViewState();
}

class _BrandViewState extends State<BrandView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Correct Bloc Call
    context.read<InventoryBrandBloc>().add(LoadInvBrands());
  }

  @override
  Widget build(BuildContext context) {
    // Fixed: Pointing to Brand Bloc
    final bloc = context.read<InventoryBrandBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Brand Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage your raw material brands (e.g. Amul, Nestle)", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => bloc.add(LoadInvBrands(query: val)),
                  decoration: InputDecoration(
                      hintText: "Search brands...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context, bloc),
                icon: const Icon(Icons.add),
                label: const Text("New Brand"),
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
            child: BlocBuilder<InventoryBrandBloc, InventoryBrandState>(
              builder: (context, state) {
                if (state is InvBrandLoading) return const Center(child: CircularProgressIndicator());
                if (state is InvBrandLoaded) return _buildTable(state.brands, bloc);
                if (state is InvBrandError) return Center(child: Text(state.message));
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<InventoryBrandEntity> list, InventoryBrandBloc bloc) {
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
                Expanded(flex: 3, child: Text("BRAND NAME & ORIGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("No brands found"))
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildBrandRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow(InventoryBrandEntity brand, InventoryBrandBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brand.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (brand.origin != null && brand.origin!.isNotEmpty)
                  Text("Origin: ${brand.origin}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange),
                    onPressed: () => _showFormDialog(context, bloc, brand: brand)
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context, brand.id!, bloc)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, InventoryBrandBloc bloc, {InventoryBrandEntity? brand}) {
    final nameController = TextEditingController(text: brand?.name);
    final originController = TextEditingController(text: brand?.origin);

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
              Text(brand == null ? "New Brand" : "Edit Brand",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildField(nameController, "Brand Name (e.g. Amul)"),
              const SizedBox(height: 16),
              _buildField(originController, "Origin (e.g. India)"),
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
                          final entity = InventoryBrandEntity(
                            name: nameController.text,
                            origin: originController.text,
                          );
                          if (brand == null) {
                            bloc.add(AddInvBrand(entity));
                          } else {
                            bloc.add(EditInvBrand(brand.id!, entity));
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Save Brand"),
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

  void _confirmDelete(BuildContext context, int id, InventoryBrandBloc bloc) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Brand?"),
          content: const Text("Are you sure? This will remove the brand from your system."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  bloc.add(DeleteInvBrand(id));
                  Navigator.pop(ctx);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red))
            ),
          ],
        )
    );
  }
}