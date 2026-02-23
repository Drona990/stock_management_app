import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_category.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Corrected Bloc call to match your file naming
    context.read<InventoryCategoryBloc>().add(LoadInvCategories());
  }

  @override
  Widget build(BuildContext context) {
    // Consistent naming across the file
    final bloc = context.read<InventoryCategoryBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Category Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage your raw material and item categories", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => bloc.add(LoadInvCategories(query: val)),
                  decoration: InputDecoration(
                      hintText: "Search categories...",
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
                label: const Text("New Category"),
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
            child: BlocBuilder<InventoryCategoryBloc, InventoryCategoryState>(
              builder: (context, state) {
                if (state is InvCategoryLoading) return const Center(child: CircularProgressIndicator());
                if (state is InvCategoryLoaded) return _buildTable(state.categories, bloc);
                if (state is InvCategoryError) return Center(child: Text(state.message));
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<InventoryCategoryEntity> list, InventoryCategoryBloc bloc) {
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
                Expanded(flex: 3, child: Text("NAME & DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("No categories found"))
                : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildCategoryRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(InventoryCategoryEntity cat, InventoryCategoryBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (cat.description != null && cat.description!.isNotEmpty)
                  Text(cat.description!, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1),
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
                    onPressed: () => _showFormDialog(context, bloc, category: cat)
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context, cat.id!, bloc)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, InventoryCategoryBloc bloc, {InventoryCategoryEntity? category}) {
    final nameController = TextEditingController(text: category?.name);
    final descController = TextEditingController(text: category?.description);

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
              Text(category == null ? "New Inventory Category" : "Edit Category",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildField(nameController, "Category Name"),
              const SizedBox(height: 16),
              _buildField(descController, "Description (Optional)", maxLines: 3),
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
                          final entity = InventoryCategoryEntity(
                            name: nameController.text,
                            description: descController.text,
                          );
                          if (category == null) {
                            bloc.add(AddInvCategory(entity));
                          } else {
                            bloc.add(EditInvCategory(category.id!, entity));
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Save Category"),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, InventoryCategoryBloc bloc) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Category?"),
          content: const Text("Are you sure? Products in this category will not be deleted but they will lose their category link."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  bloc.add(DeleteInvCategory(id));
                  Navigator.pop(ctx);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red))
            ),
          ],
        )
    );
  }
}