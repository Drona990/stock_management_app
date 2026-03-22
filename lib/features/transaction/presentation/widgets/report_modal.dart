
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReportModal {
  static void show(BuildContext context, String title, List data) {
    // Local Filter States
    String searchQuery = "";
    String activeStatus = "ALL"; // ALL, IN STOCK, SOLD

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog.fullscreen(
        child: StatefulBuilder( // ✅ Allows real-time filtering inside dialog
          builder: (context, setS) {
            // Filtering Logic
            List filteredData = data.where((item) {
              String barcode = (item['barcode_no'] ?? item['barcode'] ?? "").toString().toLowerCase();
              String status = (item['status_text'] ?? "SOLD").toString().toUpperCase();

              bool matchesSearch = barcode.contains(searchQuery.toLowerCase());
              bool matchesStatus = activeStatus == "ALL" || status == activeStatus;

              return matchesSearch && matchesStatus;
            }).toList();

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                elevation: 0.5,
                backgroundColor: const Color(0xFF0F172A),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${title.toUpperCase()} MASTER LOG",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text("ERP System Audit Terminal",
                        style: TextStyle(fontSize: 10, color: Colors.blueAccent)),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.exit_to_app, size: 18),
                      label: const Text("EXIT"),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // --- 🔍 FILTER & SEARCH BAR SECTION ---
                  /*Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _headerKpi("TOTAL", "${data.length}", Icons.analytics, Colors.indigo),
                            const SizedBox(width: 20),
                            _headerKpi("FILTERED", "${filteredData.length}", Icons.filter_alt, Colors.orange),
                            const Spacer(),
                            // Barcode Search Field
                            SizedBox(
                              width: 300,
                              height: 40,
                              child: TextField(
                                onChanged: (v) => setS(() => searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: "Search Barcode...",
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick Status Chips
                        Row(
                          children: [
                            const Text("Status: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(width: 8),
                            _filterChip(setS, "ALL", activeStatus == "ALL", () => activeStatus = "ALL"),
                            const SizedBox(width: 8),
                            _filterChip(setS, "IN STOCK", activeStatus == "IN STOCK", () => activeStatus = "IN STOCK"),
                            const SizedBox(width: 8),
                            _filterChip(setS, "SOLD", activeStatus == "SOLD", () => activeStatus = "SOLD"),
                          ],
                        )
                      ],
                    ),
                  ),*/

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to start for mobile
                      children: [
                        // --- Row 1: KPI and Search Bar ---
                        LayoutBuilder(builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 600;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // KPI Section
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _headerKpi("TOTAL", "${data.length}", Icons.analytics, Colors.indigo),
                                  const SizedBox(width: 16),
                                  _headerKpi("FILTERED", "${filteredData.length}", Icons.filter_alt, Colors.orange),
                                ],
                              ),

                              // Search Bar (Full width on mobile, 300px on Desktop)
                              SizedBox(
                                width: isMobile ? double.infinity : 300,
                                height: 40,
                                child: TextField(
                                  onChanged: (v) => setS(() => searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: "Search Barcode...",
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF1F5F9),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 16),

                        // --- Row 2: Quick Status Chips (Scrollable for Mobile) ---
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text("Status: ",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)
                              ),
                              const SizedBox(width: 8),
                              _filterChip(setS, "ALL", activeStatus == "ALL", () => activeStatus = "ALL"),
                              const SizedBox(width: 8),
                              _filterChip(setS, "IN STOCK", activeStatus == "IN STOCK", () => activeStatus = "IN STOCK"),
                              const SizedBox(width: 8),
                              _filterChip(setS, "SOLD", activeStatus == "SOLD", () => activeStatus = "SOLD"),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- DATA TABLE WINDOW ---
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 1250,
                              child: PaginatedDataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                headingRowHeight: 45,
                                horizontalMargin: 20,
                                columnSpacing: 30,
                                showCheckboxColumn: false,
                                columns: [
                                  _col("BARCODE / SKU"),
                                  _col("REF/INVOICE"),
                                  _col("DATE"),
                                  _col("ITEM/CLIENT"),
                                  _col("AGENT"),
                                  _col("STATUS"),
                                  _col("TOTAL VALUE"),
                                ],
                                source: AdvanceReportDataSource(filteredData, context),
                                rowsPerPage: filteredData.length < 10 ? (filteredData.isEmpty ? 1 : filteredData.length) : 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ Helper for Filter Chips
  static Widget _filterChip(StateSetter setS, String label, bool isSelected, VoidCallback onSelect) {
    return ActionChip(
      onPressed: () => setS(onSelect),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  static DataColumn _col(String label) => DataColumn(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF334155)))
  );

  static Widget _headerKpi(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ],
        )
      ],
    );
  }
}

class AdvanceReportDataSource extends DataTableSource {
  final List data;
  final BuildContext context;
  AdvanceReportDataSource(this.data, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final r = data[index];
    String barcode = r['barcode_no'] ?? r['barcode'] ?? "N/A";

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) => index.isEven ? Colors.transparent : const Color(0xFFF8FAFC)),
      cells: [
        DataCell(
          InkWell(
            onLongPress: () => _copyToClipboard(barcode),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(barcode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.blueAccent),
                  onPressed: () => _copyToClipboard(barcode),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(r['bill_no'] ?? r['status_text'] ?? "-", style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
        DataCell(Text(r['date']?.toString().split('T')[0] ?? "-")),
        DataCell(Text(r['customer_name'] ?? r['item_name'] ?? "N/A")),
        DataCell(Text(r['sold_by'] ?? "System")),
        DataCell(_buildStatusBadge(r['status_text'] ?? "SOLD")),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text("₹${r['invoice_total'] ?? r['price'] ?? 0}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900)),
        )),
      ],
    );
  }

  void _copyToClipboard(String text) {
    if (text == "N/A") return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Barcode $text copied"), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
  }

  Widget _buildStatusBadge(String text) {
    bool isStock = text == "IN STOCK";
    Color color = isStock ? Colors.orange : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 0.5)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  @override bool get isRowCountApproximate => false;
  @override int get rowCount => data.length;
  @override int get selectedRowCount => 0;
}