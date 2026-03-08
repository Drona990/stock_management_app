

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/inventory_category.dart';
import '../bloc/inventory_group_subgroup_bloc.dart';

class InventoryGroupSubgroupView extends StatefulWidget {
  const InventoryGroupSubgroupView({super.key});

  @override
  State<InventoryGroupSubgroupView> createState() => _InventoryGroupSubgroupViewState();
}

class _InventoryGroupSubgroupViewState extends State<InventoryGroupSubgroupView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initial data load for all required blocs
    context.read<ProductGroupBloc>().add(LoadGroups());
    context.read<ProductSubGroupBloc>().add(LoadSubGroups());
    context.read<InventoryCategoryBloc>().add(LoadInvCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupTab(),
                _buildSubMasterTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF00BCD4),
        labelColor: const Color(0xFF1A1C24),
        unselectedLabelColor: Colors.grey,
        tabs: const [Tab(text: "Group Master"), Tab(text: "Sub Master")],
      ),
    );
  }

  // ==========================================================================
  // GROUP MASTER TAB
  // ==========================================================================
  Widget _buildGroupTab() {
    final bloc = context.read<ProductGroupBloc>();
    return Column(
      children: [
        _buildTopActions(
          hint: "Search groups or HSN...",
          onSearch: (val) => bloc.add(LoadGroups(query: val)),
          onAdd: () => _showGroupForm(context, bloc),
          buttonLabel: "New Group",
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BlocBuilder<ProductGroupBloc, ProductGroupState>(
            builder: (context, state) {
              if (state is GroupLoading) return const Center(child: CircularProgressIndicator());
              if (state is GroupLoaded) return _buildGroupTable(state.groups, bloc);
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTable(List<ProductGroupEntity> list, ProductGroupBloc bloc) {
    return _customTableContainer(
      header: const Row(
        children: [
          Expanded(flex: 2, child: Text("GROUP & HSN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text("TAX (%)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = list[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("HSN: ${item.hsnCode ?? '-'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
                Expanded(flex: 1, child: Text("S: ${item.sgst}% | C: ${item.cgst}% | I: ${item.igst}%")),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SUB MASTER TAB
  // ==========================================================================
  Widget _buildSubMasterTab() {
    final subBloc = context.read<ProductSubGroupBloc>();
    return Column(
      children: [
        _buildTopActions(
          hint: "Search sub-names...",
          onSearch: (val) => subBloc.add(LoadSubGroups(query: val)),
          onAdd: () => _showSubForm(context, subBloc),
          buttonLabel: "New Sub Item",
        ),
        const SizedBox(height: 24),
        Expanded(
          child: BlocBuilder<ProductSubGroupBloc, SubGroupState>(
            builder: (context, state) {
              if (state is SubGroupLoading) return const Center(child: CircularProgressIndicator());
              if (state is SubGroupLoaded) return _buildSubTable(state.subGroups, subBloc);
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubTable(List<ProductSubGroupEntity> list, ProductSubGroupBloc bloc) {
    return _customTableContainer(
      header: const Row(
        children: [
          Expanded(flex: 2, child: Text("SUB NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("PARENT GROUP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text("ACTIONS", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = list[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text(item.groupName ?? "N/A", style: const TextStyle(color: Colors.blueGrey))),
                Expanded(flex: 1, child: _buildRowActions(
                  onEdit: () => _showSubForm(context, bloc, subGroup: item),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // DIALOGS & FORMS
  // ==========================================================================

  void _showGroupForm(BuildContext context, ProductGroupBloc bloc, {ProductGroupEntity? group}) {
    final categoryBloc = context.read<InventoryCategoryBloc>();

    int? selectedCatId;
    final hsnCtrl = TextEditingController(text: group?.hsnCode);
    final sgstCtrl = TextEditingController(text: group?.sgst.toString() ?? "0.0");
    final cgstCtrl = TextEditingController(text: group?.cgst.toString() ?? "0.0");
    final igstCtrl = TextEditingController(text: group?.igst.toString() ?? "0.0");

    void updateIGST() {
      double s = double.tryParse(sgstCtrl.text) ?? 0;
      double c = double.tryParse(cgstCtrl.text) ?? 0;
      igstCtrl.text = (s + c).toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group == null ? "New Group Master" : "Edit Group Master",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  BlocBuilder<InventoryCategoryBloc, InventoryCategoryState>(
                    builder: (context, state) {
                      List<InventoryCategoryEntity> categories = state is InvCategoryLoaded ? state.categories : [];
                      return DropdownButtonFormField<int>(
                        value: selectedCatId,
                        decoration: _inputDecoration("Select Category", label: "Group Name"),
                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => selectedCatId = val,
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // ✅ HSN Code: Only digits keyboard
                  _buildField(hsnCtrl, "e.g. 5208", label: "HSN Code", isOnlyDigits: true),
                  const SizedBox(height: 12),

                  // ✅ TAX FIELDS: Decimal keyboard
                  Row(children: [
                    Expanded(child: _buildField(sgstCtrl, "0.0", label: "SGST %", onChanged: (_) => updateIGST(), isDecimal: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildField(cgstCtrl, "0.0", label: "CGST %", onChanged: (_) => updateIGST(), isDecimal: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildField(igstCtrl, "0.0", label: "IGST %", readOnly: true, isDecimal: true)),
                  ]),
                  const SizedBox(height: 24),

                  Row(children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL"))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: () {
                          final sVal = double.tryParse(sgstCtrl.text);
                          final cVal = double.tryParse(cgstCtrl.text);

                          if (selectedCatId == null) {
                            _showTopError(context, "Please select a Group Name");
                            return;
                          }

                          if (sVal == null || sVal < 0 || sVal > 100) {
                            _showTopError(context, "Invalid SGST. Must be 0-100");
                            return;
                          }

                          if (cVal == null || cVal < 0 || cVal > 100) {
                            _showTopError(context, "Invalid CGST. Must be 0-100");
                            return;
                          }

                          final catState = categoryBloc.state as InvCategoryLoaded;
                          final catName = catState.categories.firstWhere((e) => e.id == selectedCatId).name;

                          final entity = ProductGroupEntity(
                            name: catName,
                            hsnCode: hsnCtrl.text,
                            sgst: sVal,
                            cgst: cVal,
                            igst: sVal + cVal,
                          );

                          group == null ? bloc.add(AddGroup(entity)) : bloc.add(EditGroup(group.id!, entity));
                          Navigator.pop(ctx);
                        },
                        child: const Text("SAVE DATA")
                    )),
                  ]),
                ]
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Updated Helper with Keyboard & Formatter logic
  Widget _buildField(TextEditingController ctrl, String hint, {
    String? label,
    Function(String)? onChanged,
    bool readOnly = false,
    bool isDecimal = false,
    bool isOnlyDigits = false,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      readOnly: readOnly,
      // ⌨️ Keyboard selection
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : (isOnlyDigits ? TextInputType.number : TextInputType.text),
      // 🚫 Input Formatters to block invalid characters
      inputFormatters: [
        if (isOnlyDigits) FilteringTextInputFormatter.digitsOnly,
        if (isDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: _inputDecoration(hint, label: label),
    );
  }
  // Helper method to show error
  void _showTopError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showSubForm(BuildContext context, ProductSubGroupBloc subBloc, {ProductSubGroupEntity? subGroup}) {
    // Current blocs ka reference lein
    final groupBloc = context.read<ProductGroupBloc>();

    final nameCtrl = TextEditingController(text: subGroup?.name);
    int? selectedGroupId = subGroup?.groupId;

    showDialog(
      context: context,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          // Yeh dono line providers ko naye dialog route mein pass karengi
          BlocProvider.value(value: subBloc),
          BlocProvider.value(value: groupBloc),
        ],
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sub Master Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Group Selection Dropdown (Using GroupBloc data)
                BlocBuilder<ProductGroupBloc, ProductGroupState>(
                  builder: (context, state) {
                    List<ProductGroupEntity> groups = state is GroupLoaded ? state.groups : [];
                    return DropdownButtonFormField<int>(
                      value: selectedGroupId,
                      decoration: _inputDecoration("Select Parent Group", label: "Parent Group"),
                      items: groups.map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.name)
                      )).toList(),
                      onChanged: (val) => selectedGroupId = val,
                    );
                  },
                ),

                const SizedBox(height: 16),
                _buildField(nameCtrl, "e.g. Cotton Towel", label: "Sub Name"),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                        child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("CANCEL")
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
                          if (selectedGroupId != null && nameCtrl.text.isNotEmpty) {
                            final entity = ProductSubGroupEntity(
                                groupId: selectedGroupId!,
                                name: nameCtrl.text
                            );
                            subGroup == null
                                ? subBloc.add(AddSubGroup(entity))
                                : subBloc.add(EditSubGroup(subGroup.id!, entity));
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text("SAVE DATA"),
                      ),
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
  // ==========================================================================
  // HELPERS & STYLING
  // ==========================================================================

  Widget _buildTopActions({required String hint, required Function(String) onSearch, required VoidCallback onAdd, required String buttonLabel}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: hint, prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onAdd, icon: const Icon(Icons.add), label: Text(buttonLabel),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _customTableContainer({required Widget header, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: const BoxDecoration(color: Color(0xFFF8F9FB), borderRadius: BorderRadius.vertical(top: Radius.circular(16))), child: header),
        Expanded(child: child),
      ]),
    );
  }

  Widget _buildRowActions({required VoidCallback onEdit}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange), onPressed: onEdit),
    ]);
  }

  void _showStyledDialog(BuildContext context, {required String title, required List<Widget> fields, required VoidCallback onSave}) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 480, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ...fields,
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL"))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: onSave, child: const Text("SAVE DATA"))),
        ]),
      ])),
    ));
  }


  InputDecoration _inputDecoration(String hint, {String? label}) {
    return InputDecoration(
      hintText: hint, labelText: label, floatingLabelBehavior: FloatingLabelBehavior.always, filled: true, fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00BCD4))),
    );
  }
}