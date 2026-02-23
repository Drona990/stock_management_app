import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/salse_bloc.dart';

class SalesHistorySidebar extends StatefulWidget {
  const SalesHistorySidebar({super.key});
  @override
  State<SalesHistorySidebar> createState() => _SalesHistorySidebarState();
}

class _SalesHistorySidebarState extends State<SalesHistorySidebar> {
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.55,
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
      child: Row(children: [
        const Icon(Icons.analytics_outlined, color: Color(0xFF00BCD4), size: 30),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sales Audit Ledger / बिक्री इतिहास", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Detailed transaction logs and SKU tracking", style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
      ]),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search Invoice, Product, or Barcode...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _filterButton(
            label: _selectedDateRange == null
                ? "Filter Date"
                : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
            icon: Icons.calendar_month,
            onTap: _showCustomDatePicker,
            isActive: _selectedDateRange != null,
          ),
          if (_selectedDateRange != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.redAccent),
              onPressed: () => setState(() { _searchQuery = ""; _selectedDateRange = null; }),
            )
        ],
      ),
    );
  }

  Widget _buildDataTableSection() {
    return BlocBuilder<SaleBloc, SaleState>(
      builder: (context, state) {
        if (state is SaleLoading) return const Center(child: CircularProgressIndicator());
        if (state is SaleHistoryLoaded) {
          // 💡 MULTI-FIELD FILTER LOGIC
          final filtered = state.history.where((sale) {
            bool matchesText = sale.invoiceNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                sale.items.any((it) => it.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    it.productBarcode.toLowerCase().contains(_searchQuery.toLowerCase()));

            bool matchesDate = true;
            if (_selectedDateRange != null) {
              matchesDate = sale.saleDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                  sale.saleDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            }
            return matchesText && matchesDate;
          }).toList();

          return SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMaxHeight: 95,
              columns: const [
                DataColumn(label: Text("DATE & INV")),
                DataColumn(label: Text("SOLD ITEMS & SKU")),
                DataColumn(label: Text("TOTAL AMT")),
                DataColumn(label: Text("STATUS")),
              ],
              rows: filtered.map((sale) => DataRow(cells: [
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd-MM-yy').format(sale.saleDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(sale.invoiceNo, style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                  ],
                )),
                DataCell(SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sale.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productBarcode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          Text("${it.productName} (x${it.quantity.toInt()})", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        ],
                      ),
                    )).toList(),
                  ),
                )),
                DataCell(Text("₹${sale.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text("PAID", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                )),
              ])).toList(),
            ),
          );
        }
        return const Center(child: Text("No records found"));
      },
    );
  }

  void _showCustomDatePicker() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Sale Period", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Theme(
            data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF00BCD4))),
            child: DateRangePickerDialog(firstDate: DateTime(2024), lastDate: DateTime.now()),
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Widget _filterButton({required String label, required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? const Color(0xFF00BCD4) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: isActive ? const Color(0xFF00BCD4).withOpacity(0.05) : Colors.white,
        ),
        child: Row(children: [Icon(icon, size: 18, color: isActive ? const Color(0xFF00BCD4) : Colors.black), const SizedBox(width: 8), Text(label, style: TextStyle(color: isActive ? const Color(0xFF00BCD4) : Colors.black, fontSize: 13))]),
      ),
    );
  }
}