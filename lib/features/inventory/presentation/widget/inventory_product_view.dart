
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/inventory/presentation/widget/product_entry_form.dart';
import 'package:stock_management/features/inventory/presentation/widget/tax_profile_view.dart';
import '../bloc/inventory_category.dart';
import '../bloc/inventory_product_management_bloc.dart';
import 'inventory_units_view.dart';

class ProductManagementView extends StatefulWidget {
  const ProductManagementView({super.key});

  @override
  State<ProductManagementView> createState() => _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 💡 Scroll Controllers to fix the "no ScrollPosition attached" error
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refresh();
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<InventoryProductBloc>().add(LoadProducts());
    context.read<InventoryCategoryBloc>().add(LoadInvCategories());
    context.read<InventoryUnitBloc>().add(LoadInvUnits());
    context.read<TaxProfileBloc>().add(LoadTaxes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFilter(),
            const SizedBox(height: 24),
            Expanded(child: _buildFullWidthTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Product Master", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        Text("Manage and blueprint your kitchen inventory", style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
      ]),
      ElevatedButton.icon(
        onPressed: () => _openPanel(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text("NEW PRODUCT"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1C24),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );

  Widget _buildFilter() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: TextField(
      controller: _searchController,
      decoration: const InputDecoration(hintText: "Search Product Name, SKU or Category...", border: InputBorder.none, prefixIcon: Icon(Icons.search, color: Color(0xFF00BCD4))),
    ),
  );

  Widget _buildFullWidthTable() {
    return BlocBuilder<InventoryProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
        if (state is ProductLoaded) {
          final list = state.products.where((p) => p.name.toLowerCase().contains(_searchQuery) || p.sku.toLowerCase().contains(_searchQuery)).toList();
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  notificationPredicate: (n) => n.depth == 1,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columnSpacing: 40,
                        columns: const [
                          DataColumn(label: Text('IMG')),
                          DataColumn(label: Text('PRODUCT INFO')),
                          DataColumn(label: Text('CATEGORY')),
                          DataColumn(label: Text('STOCK STATUS')),
                          DataColumn(label: Text('BUY RATE')),
                          DataColumn(label: Text('SELL RATE')),
                          DataColumn(label: Text('LOCATION')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: list.map((p) => DataRow(cells: [
                          DataCell(p.image != null ? CircleAvatar(backgroundImage: NetworkImage(p.image!)) : const CircleAvatar(child: Icon(Icons.image))),
                          DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(p.sku, style: const TextStyle(fontSize: 10, color: Colors.grey))
                          ])),
                          DataCell(Text(p.categoryName ?? 'N/A')),
                          DataCell(Text("${p.currentStock} ${p.unitName ?? ''}", style: TextStyle(color: p.currentStock <= p.minStockLevel ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
                          DataCell(Text("₹${p.purchasePrice}")),
                          DataCell(Text("₹${p.sellingPrice}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(p.location ?? '-')),
                          DataCell(IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _openPanel(context, p: p))),
                        ])).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _openPanel(BuildContext context, {InventoryProductEntity? p}) {
    // 💡 Provider Fix: Passing Blocs to the dialog
    final catBloc = context.read<InventoryCategoryBloc>();
    final unitBloc = context.read<InventoryUnitBloc>();
    final taxBloc = context.read<TaxProfileBloc>();
    final prodBloc = context.read<InventoryProductBloc>();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, a1, a2) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 20,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.4,
            height: double.infinity,
            color: Colors.white,
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: catBloc),
                BlocProvider.value(value: unitBloc),
                BlocProvider.value(value: taxBloc),
                BlocProvider.value(value: prodBloc),
              ],
              child: ProductEntryForm(existingProduct: p),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, a1, a2, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(a1),
        child: child,
      ),
    );
  }
}
