import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_management/features/transaction/presentation/pages/dc_invoice_pdf_generator.dart';

import '../../../transaction/presentation/pages/dc_terminal_view.dart';

class DcChallanHistory extends StatefulWidget {
  const DcChallanHistory({super.key});

  @override
  State<DcChallanHistory> createState() => _DcChallanHistoryState();
}

class _DcChallanHistoryState extends State<DcChallanHistory> {
  final _searchCtrl = TextEditingController();
  String _activeTabMode = "INWARD";

  @override
  void initState() {
    super.initState();
    _triggerHistoryFetch();
  }

  void _triggerHistoryFetch() {
    context.read<UnifiedTxBloc>().add(LoadUnifiedHistoryEvent(
      terminalMode: _activeTabMode,
      search: _searchCtrl.text.trim(),
    ));
  }

  Future<void> _executeOnDemandReprint(Map<String, dynamic> recordData) async {
    try {
      final ByteData rawLogo = await rootBundle.load('assets/images/ultra_logo.jpeg');
      final Uint8List u8list = rawLogo.buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(u8list);

      List<String> printHeadings = [];
      if (_activeTabMode == 'PROFORMA') {
        printHeadings = ["DUPLICATE PROFORMA COPY"];
      } else if (_activeTabMode == 'INWARD') {
        printHeadings = ["DUPLICATE DC INWARD LABELS"];
      } else {
        printHeadings = ["DUPLICATE DC OUTWARD LABELS"];
      }

      final pdfDoc = await InvoiceDCPdfService.generate(
        logoImage: logoImage,
        data: recordData,
        terminalMode: _activeTabMode,
        headings: printHeadings,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfDoc.save(),
        name: 'DUPLICATE_${_activeTabMode}_${recordData['billno'] ?? 'DOC'}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Layout Generator Crash: $e", style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color industrialSlate = Color(0xFF1E293B);
    // Dynamic media tracking system layout check
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 52,
        iconTheme: const IconThemeData(color: industrialSlate, size: 18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("INVENTORY VOUCHERS DIRECTORY",
                style: TextStyle(color: industrialSlate, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            Text("LOGISTICS DISPATCH MATERIAL MOVEMENT RUNNING AUDIT TRAILS",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 7.5, fontWeight: FontWeight.bold))
          ],
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: Column(
        children: [
          _buildTopFilteringBar(isMobile),
          Expanded(child: _buildRegistryContentGrid(isMobile)),
        ],
      ),
    );
  }

  Widget _buildTopFilteringBar(bool isMobile) {
    // Common operational callback to prevent code duplication
    void handleTabChange(String? newMode) {
      if (newMode != null) {
        setState(() {
          _activeTabMode = newMode;
          _searchCtrl.clear(); // Safe UI cleanup
        });
        // Explicitly passing empty string for search to break any controller timing delays
        context.read<UnifiedTxBloc>().add(LoadUnifiedHistoryEvent(
          terminalMode: newMode,
          search: "",
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: isMobile
          ? Column(
        children: [
          // 📱 Mobile Search Box
          Container(
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              onChanged: (v) => _triggerHistoryFetch(),
              decoration: const InputDecoration(
                hintText: "SEARCH LOGS BY DC, PO OR PARTY NAME...",
                hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                prefixIcon: Icon(Icons.saved_search_rounded, size: 14, color: Colors.blueGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 📱 Mobile Full Width Dropdown
          Container(
            height: 35,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _activeTabMode,
                isExpanded: true,
                style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: "INWARD", child: Text("📥 DC INWARD REGISTER")),
                  DropdownMenuItem(value: "OUTWARD", child: Text("📤 DC OUTWARD REGISTER")),
                  DropdownMenuItem(value: "PROFORMA", child: Text("📄 PROFORMA ESTIMATES")),
                ],
                onChanged: handleTabChange, // ✅ Pointed to optimized central routine
              ),
            ),
          ),
        ],
      )
          : Row(
        children: [
          // 💻 Desktop Wide Search Box
          Expanded(
            flex: 3,
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                onChanged: (v) => _triggerHistoryFetch(),
                decoration: const InputDecoration(
                  hintText: "SEARCH ENTRIES BY DC NO, PO REF, CONSUMER / SUPPLIER NAME...",
                  hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  prefixIcon: Icon(Icons.saved_search_rounded, size: 14, color: Colors.blueGrey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 💻 Desktop Dropdown Box
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _activeTabMode,
                style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold, letterSpacing: 0.3),
                items: const [
                  DropdownMenuItem(value: "INWARD", child: Text("📥 DC INWARD REGISTER")),
                  DropdownMenuItem(value: "OUTWARD", child: Text("📤 DC OUTWARD REGISTER")),
                  DropdownMenuItem(value: "PROFORMA", child: Text("📄 PROFORMA ESTIMATES")),
                ],
                onChanged: handleTabChange, // ✅ Added missing fix for desktop mode too!
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRegistryContentGrid(bool isMobile) {
    return BlocBuilder<UnifiedTxBloc, UnifiedTxState>(
      builder: (context, state) {
        if (state is UnifiedTxLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
        }

        if (state is UnifiedHistoryLoadedState) {
          final itemsList = state.recordsList;
          if (itemsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 22, color: Colors.grey),
                  SizedBox(height: 6),
                  Text("No historical materials movement logged under current metrics rules.",
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: itemsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final rowItem = itemsList[index];

              Color statusColor = const Color(0xFF2C3E50);
              if (_activeTabMode == "OUTWARD") statusColor = const Color(0xFFD97706);
              if (_activeTabMode == "PROFORMA") statusColor = const Color(0xFF0F4C81);

              // 📱 HIGH DENSITY MOBILE VS DESKTOP RESPONSIVE CONTAINER CARD
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: statusColor, width: 4.5),
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    right: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                          child: Text(_activeTabMode, style: TextStyle(color: statusColor, fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                        ),
                        Text("₹ ${double.tryParse(rowItem['grand_totamt']?.toString() ?? '0')?.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(rowItem['name']?.toString().toUpperCase() ?? '',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        _metaLabel("DOC NO", rowItem['billno'] ?? rowItem['dc_no'] ?? 'N/A'),
                        _bullet(),
                        _metaLabel("DATE", rowItem['billdate'] ?? 'N/A'),
                        _bullet(),
                        _metaLabel("QTY", "${double.tryParse(rowItem['total_pcs']?.toString() ?? '0')?.toStringAsFixed(0)} PCS"),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: rowItem['dispatch'] != null && rowItem['dispatch'].toString().isNotEmpty
                              ? Text("VEHICLE: ${rowItem['dispatch']}".toUpperCase(),
                              style: TextStyle(fontSize: 7.5, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold, letterSpacing: 0.1))
                              : const SizedBox(),
                        ),
                        InkWell(
                          onTap: () => _executeOnDemandReprint(rowItem),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.print_rounded, color: Color(0xFF475569), size: 11),
                                SizedBox(width: 4),
                                Text("REPRINT", style: TextStyle(fontSize: 8, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                )
                    : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(rowItem['name']?.toString().toUpperCase() ?? '',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                                child: Text(_activeTabMode,
                                    style: TextStyle(color: statusColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _metaLabel("DOC NO", rowItem['billno'] ?? rowItem['dc_no'] ?? 'N/A'),
                              _bullet(),
                              _metaLabel("DATE", rowItem['billdate'] ?? 'N/A'),
                              _bullet(),
                              _metaLabel("PO REF", rowItem['purchase_order_no'] ?? 'N/A', active: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (rowItem['dispatch'] != null && rowItem['dispatch'].toString().isNotEmpty)
                            Text("DISPATCH LOGISTICS VEHICLE: ${rowItem['dispatch']}".toUpperCase(),
                                style: TextStyle(fontSize: 7.5, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, letterSpacing: 0.1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("₹ ${double.tryParse(rowItem['grand_totamt']?.toString() ?? '0')?.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text("${double.tryParse(rowItem['total_pcs']?.toString() ?? '0')?.toStringAsFixed(0)} PCS TOTAL",
                            style: TextStyle(fontSize: 7.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () => _executeOnDemandReprint(rowItem),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: const Icon(Icons.print_rounded, color: Color(0xFF475569), size: 13),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }

        if (state is UnifiedTxError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("History Pipeline Exception Intercepted: ${state.message}",
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _metaLabel(String label, String value, {bool active = false}) {
    return Text(
      "$label: ${value.toUpperCase()}",
      style: TextStyle(
          fontSize: 8.5,
          color: active ? const Color(0xFF0284C7) : Colors.grey.shade600,
          fontWeight: active ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: 0.1
      ),
    );
  }

  Widget _bullet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text("•", style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
    );
  }
}