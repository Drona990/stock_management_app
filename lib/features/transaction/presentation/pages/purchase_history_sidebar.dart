import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/purchase_bloc.dart';
import '../../domain/entity/purchase_entity.dart';

class PurchaseHistorySidebar extends StatefulWidget {
  const PurchaseHistorySidebar({super.key});

  @override
  State<PurchaseHistorySidebar> createState() => _PurchaseHistorySidebarState();
}

class _PurchaseHistorySidebarState extends State<PurchaseHistorySidebar> {
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  String _statusFilter = "ALL";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.60, // 💡 Professional width
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(context),
          _buildFilterSection(),
          Expanded(child: _buildDataTableSection()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          const Icon(Icons.analytics_rounded, color: Color(0xFF00BCD4), size: 30),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Audit Logs / खरीद विवरण", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Track stock inward & barcodes", style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
          const Spacer(),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white)
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search Supplier, Bill, or Scan Barcode...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.qr_code_scanner, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _filterButton(
            label: _selectedDateRange == null
                ? "Select Date"
                : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
            icon: Icons.calendar_month,
            onTap: _showCustomDateRangePicker, // 💡 Professional Picker
            isActive: _selectedDateRange != null,
          ),
          const SizedBox(width: 12),
          _buildStatusDropdown(),
          if (_selectedDateRange != null || _searchQuery.isNotEmpty || _statusFilter != "ALL")
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.redAccent),
              onPressed: () => setState(() {
                _searchQuery = ""; _selectedDateRange = null; _statusFilter = "ALL";
              }),
            )
        ],
      ),
    );
  }

  Widget _buildDataTableSection() {
    return BlocBuilder<PurchaseBloc, PurchaseState>(
      builder: (context, state) {
        if (state is PurchaseLoading) return const Center(child: CircularProgressIndicator());
        if (state is PurchaseLoaded) {
          // 💡 FILTER LOGIC
          List<PurchaseHistoryEntity> filtered = state.history.where((bill) {
            bool matchesText = bill.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                bill.billNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                bill.items.any((it) => it.productBarcode.contains(_searchQuery));

            bool matchesStatus = _statusFilter == "ALL" || bill.paymentMode == _statusFilter;

            bool matchesDate = true;
            if (_selectedDateRange != null) {
              DateTime bDate = DateTime.tryParse(bill.purchaseDate) ?? DateTime.now();
              matchesDate = bDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                  bDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            }
            return matchesText && matchesStatus && matchesDate;
          }).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMaxHeight: 90,
              columns: const [
                DataColumn(label: Text("DATE")),
                DataColumn(label: Text("SUPPLIER / INV")),
                DataColumn(label: Text("ITEM & BARCODE")), // 💡 Combined Barcode & Item
                DataColumn(label: Text("TOTAL AMT")),
                DataColumn(label: Text("MODE")),
              ],
              rows: filtered.map((bill) {
                DateTime dt = DateTime.tryParse(bill.purchaseDate) ?? DateTime.now();
                return DataRow(cells: [
                  DataCell(Text("${DateFormat('dd-MM-yy').format(dt)}\n${DateFormat('hh:mm a').format(dt)}", style: const TextStyle(fontSize: 12))),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("#${bill.billNumber}", style: const TextStyle(fontSize: 11, color: Colors.blueAccent)),
                    ],
                  )),
                  DataCell(SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: bill.items.map((it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text("• ${it.productBarcode}\n  ${it.productName} (x${it.quantity.toInt()})",
                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  )),
                  DataCell(Text("₹${bill.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green))),
                  DataCell(_statusChip(bill.paymentMode)),
                ]);
              }).toList(),
            ),
          );
        }
        return const Center(child: Text("No records found"));
      },
    );
  }

  // 💡 Professional Date Picker (No Full Screen)
  void _showCustomDateRangePicker() async {
    DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Date Range", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Column(
            children: [
              Expanded(
                child: Theme(
                  data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF00BCD4))),
                  child: DateRangePickerDialog(
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    initialDateRange: _selectedDateRange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold),
          items: ["ALL", "CASH", "ONLINE", "CREDIT"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _statusFilter = v!),
        ),
      ),
    );
  }

  Widget _filterButton({required String label, required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            border: Border.all(color: isActive ? const Color(0xFF00BCD4) : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: isActive ? const Color(0xFF00BCD4).withOpacity(0.05) : Colors.white
        ),
        child: Row(children: [Icon(icon, size: 18, color: isActive ? const Color(0xFF00BCD4) : Colors.black), const SizedBox(width: 8), Text(label, style: TextStyle(color: isActive ? const Color(0xFF00BCD4) : Colors.black, fontSize: 13))]),
      ),
    );
  }

  Widget _statusChip(String mode) {
    Color c = mode == "CREDIT" ? Colors.orange : (mode == "ONLINE" ? Colors.blue : Colors.green);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(mode, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold))
    );
  }
}