import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entity/supplier_entity.dart';
import '../bloc/suppier_bloc.dart';

class SupplierManagementView extends StatefulWidget {
  const SupplierManagementView({super.key});

  @override
  State<SupplierManagementView> createState() => _SupplierManagementViewState();
}

class _SupplierManagementViewState extends State<SupplierManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(LoadSuppliers());
    _searchController.addListener(() {
      setState(() { _searchQuery = _searchController.text.toLowerCase(); });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildSearchBar(),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<SupplierBloc, SupplierState>(
                builder: (context, state) {
                  if (state is SupplierLoading) return const Center(child: CircularProgressIndicator());
                  if (state is SupplierLoaded) {
                    final filteredList = state.suppliers.where((s) =>
                    s.name.toLowerCase().contains(_searchQuery) ||
                        s.phone.contains(_searchQuery)).toList();

                    return _buildSupplierTable(filteredList);
                  }
                  return const Center(child: Text("Error loading suppliers"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Supplier Directory", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          Text("Manage your vendor relationships and GST compliance", style: TextStyle(color: Color(0xFF64748B))),
        ]),
        ElevatedButton.icon(
          onPressed: () => _showSupplierForm(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text("REGISTER VENDOR", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1C24),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "Search by Name or Phone Number...",
          icon: Icon(Icons.search, color: Color(0xFF00BCD4)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSupplierTable(List<SupplierEntity> suppliers) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('VENDOR NAME', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('PHONE')),
              DataColumn(label: Text('GSTIN')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: suppliers.map((s) => DataRow(cells: [
              DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(s.phone)),
              DataCell(Text(s.gstNumber ?? "Unregistered")),
              DataCell(_statusBadge(s.isActive)),
              DataCell(IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => context.read<SupplierBloc>().add(DeleteSupplier(s.id!)))),
            ])).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: active ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
    child: Text(active ? "ACTIVE" : "INACTIVE", style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
  );





  // --- Enhanced Professional Supplier Form Modal ---
  void _showSupplierForm(BuildContext context) {
    final supplierBloc = context.read<SupplierBloc>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final gst = TextEditingController();
    final address = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.7,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // 🔹 Modal Header
                _buildModalHeader(ctx, "Register New Vendor"),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel("Basic Identity"),
                        const SizedBox(height: 16),
                        _modernField(
                          ctrl: name,
                          label: "Legal Vendor Name",
                          hint: "e.g. Amul Dairy Pvt Ltd",
                          icon: Icons.business_center_outlined,
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel("Communication Details"),
                        const SizedBox(height: 16),
                        _modernField(
                          ctrl: phone,
                          label: "Contact Phone Number",
                          hint: "+91 XXXXX XXXXX",
                          icon: Icons.phone_android_outlined,
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel("Compliance (Optional)"),
                        const SizedBox(height: 16),
                        _modernField(
                          ctrl: gst,
                          label: "GSTIN Number",
                          hint: "22AAAAA0000A1Z5",
                          icon: Icons.verified_user_outlined,
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel("Registered Office Address"),
                        const SizedBox(height: 16),
                        _modernField(
                          ctrl: address,
                          label: "Physical Address",
                          hint: "Enter street, city and zip code...",
                          icon: Icons.map_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Modal Footer
                _buildModalFooter(ctx, () {
                  if (name.text.isNotEmpty && phone.text.isNotEmpty) {
                    supplierBloc.add(AddSupplier(SupplierEntity(
                      name: name.text,
                      phone: phone.text,
                      gstNumber: gst.text,
                      address: address.text,
                    )));
                    Navigator.pop(ctx);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Component Helpers ---

  Widget _buildModalHeader(BuildContext ctx, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add_outlined, color: Color(0xFF00BCD4)),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildModalFooter(BuildContext ctx, VoidCallback onSave) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("DISCARD", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1C24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("SAVE VENDOR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF00BCD4), letterSpacing: 1.2),
    );
  }

  Widget _modernField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}