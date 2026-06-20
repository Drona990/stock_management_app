import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../transaction/presentation/pages/credit_debit_note_terminal_view.dart';
import '../../../transaction/presentation/pages/financial_note_pdf_generator.dart';

class FinancialNoteReportScreen extends StatefulWidget {
  const FinancialNoteReportScreen({super.key});

  @override
  State<FinancialNoteReportScreen> createState() => _FinancialNoteReportScreenState();
}

class _FinancialNoteReportScreenState extends State<FinancialNoteReportScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedTypeFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _triggerFetch();
  }

  void _triggerFetch() {
    context.read<NoteTxBloc>().add(LoadNotesRegistryEvent(
      search: _searchCtrl.text.trim(),
      noteType: _selectedTypeFilter,
    ));
  }

  // ✅ INDUSTRIAL ON-DEMAND RE-PRINT ENGINE (CRASH REPAIRED)
  Future<void> _rePrintDocument(Map<String, dynamic> noteData) async {
    try {
      final ByteData rawLogo = await rootBundle.load('assets/images/ultra_logo.jpeg');
      final Uint8List u8list = rawLogo.buffer.asUint8List();
      final pw.ImageProvider logoProvider = pw.MemoryImage(u8list);

      String currentMode = noteData['note_type'] ?? "DEBIT_NOTE";
      List<String> headings = currentMode == "DEBIT_NOTE"
          ? ["DUPLICATE VENDOR RETURN COPY"]
          : ["DUPLICATE CLIENT REVERSAL COPY"];

      final pdfDoc = await FinancialNotePdfService.generate(
        logoImage: logoProvider,
        data: noteData,
        noteMode: currentMode,
        headings: headings,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfDoc.save(),
        name: 'REPRINT_${currentMode}_${noteData['note_no']}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF Engine Matrix Runtime Error: $e", style: const TextStyle(fontSize: 11)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color industrialSlate = Color(0xFF1E293B);

    // ✅ Dynamic Device Sensitivity Tracking Check
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
            const Text("FINANCIAL NOTE REGISTRY",
                style: TextStyle(color: industrialSlate, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            Text("DATE-WISE CREDIT / DEBIT REVERSALS AUDIT TRAIL DIRECTORY",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 7.5, fontWeight: FontWeight.bold))
          ],
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: Column(
        children: [
          _buildFilterActionBar(isMobile),
          Expanded(child: _buildRegistryTableGrid(isMobile)),
        ],
      ),
    );
  }

  Widget _buildFilterActionBar(bool isMobile) {
    void handleFilterChange(String? newFilter) {
      if (newFilter != null) {
        setState(() {
          _selectedTypeFilter = newFilter;
          _searchCtrl.clear();
        });

        context.read<NoteTxBloc>().add(LoadNotesRegistryEvent(
          search: "",
          noteType: newFilter,
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: isMobile
          ? Column(
        children: [
          // 📱 Mobile Search Component
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
              onChanged: (v) => _triggerFetch(),
              decoration: const InputDecoration(
                hintText: "SEARCH LOGS BY VOUCHER NO, INVOICE OR PARTY...",
                hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.blueGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 📱 Mobile Dropdown Full Width
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
                value: _selectedTypeFilter,
                isExpanded: true,
                style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: "ALL", child: Text("ALL NOTE VOUCHERS")),
                  DropdownMenuItem(value: "DEBIT_NOTE", child: Text("🔴 DEBIT NOTES (PURCHASE RETURN)")),
                  DropdownMenuItem(value: "CREDIT_NOTE", child: Text("🟢 CREDIT NOTES (SALES RETURN)")),
                ],
                onChanged: handleFilterChange,
              ),
            ),
          ),
        ],
      )
          : Row(
        children: [
          // 💻 Desktop Grid Search Layout
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
                onChanged: (v) => _triggerFetch(),
                decoration: const InputDecoration(
                  hintText: "SEARCH LOGS BY NOTE NO, ORIGINAL INVOICE REF, PARTY NAME...",
                  hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.blueGrey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 💻 Desktop Dropdown Layout
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
                value: _selectedTypeFilter,
                style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold, letterSpacing: 0.3),
                items: const [
                  DropdownMenuItem(value: "ALL", child: Text("ALL NOTE VOUCHERS")),
                  DropdownMenuItem(value: "DEBIT_NOTE", child: Text("🔴 DEBIT NOTES")),
                  DropdownMenuItem(value: "CREDIT_NOTE", child: Text("🟢 CREDIT NOTES")),
                ],
                onChanged: handleFilterChange,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRegistryTableGrid(bool isMobile) {
    return BlocBuilder<NoteTxBloc, NoteTxState>(
      builder: (context, state) {
        if (state is NoteTxLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
        }

        if (state is NoteRegistryLoadedState) {
          final notes = state.notesList;
          if (notes.isEmpty) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.layers_clear_outlined, size: 22, color: Colors.blueGrey),
                    SizedBox(height: 6),
                    Text("Zero commercial adjustment matrix records logged under selected filters.",
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                  ],
                )
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final note = notes[index];
              bool isDebit = note['note_type'] == "DEBIT_NOTE";
              Color tagColor = isDebit ? const Color(0xFF912B2B) : const Color(0xFF1E5631);

              String reason = (note['reason'] ?? '').toString().replaceAll('_', ' ').toUpperCase();

              // 📱 HIGH DENSITY MOBILE VS DESKTOP RESPONSIVE CARD LOOKUP
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: tagColor, width: 4.5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(color: tagColor.withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                          child: Text(isDebit ? "DEBIT" : "CREDIT",
                              style: TextStyle(color: tagColor, fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                        ),
                        Text("₹ ${double.tryParse(note['grand_total']?.toString() ?? '0')?.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(note['name']?.toString().toUpperCase() ?? '',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.1)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        _infoLabel("NOTE NO", note['note_no'] ?? 'N/A'),
                        _dividerDot(),
                        _infoLabel("DATE", note['note_date'] ?? 'N/A'),
                        _dividerDot(),
                        _infoLabel("LOGGED", "${double.tryParse(note['total_pcs']?.toString() ?? '0')?.toStringAsFixed(0)} PCS"),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("REASON: $reason",
                        style: TextStyle(fontSize: 7.5, color: Colors.blueGrey.shade600, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: note['original_invoice_no'] != null && note['original_invoice_no'].toString().isNotEmpty
                              ? _infoLabel("ORIG. INV", note['original_invoice_no'], highlight: true)
                              : const SizedBox(),
                        ),
                        InkWell(
                          onTap: () => _rePrintDocument(note),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.print_rounded, color: Color(0xFF334155), size: 11),
                                SizedBox(width: 4),
                                Text("REPRINT", style: TextStyle(fontSize: 8, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
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
                              Text(note['name']?.toString().toUpperCase() ?? '',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.1)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(color: tagColor.withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                                child: Text(isDebit ? "DEBIT" : "CREDIT",
                                    style: TextStyle(color: tagColor, fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _infoLabel("NOTE NO", note['note_no'] ?? 'N/A'),
                              _dividerDot(),
                              _infoLabel("DATE", note['note_date'] ?? 'N/A'),
                              _dividerDot(),
                              _infoLabel("ORIGINAL BILL REF", note['original_invoice_no'] ?? 'N/A', highlight: true),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text("REASON: $reason",
                              style: TextStyle(fontSize: 8, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("₹ ${double.tryParse(note['grand_total']?.toString() ?? '0')?.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text("${double.tryParse(note['total_pcs']?.toString() ?? '0')?.toStringAsFixed(0)} PCS LOGGED",
                            style: TextStyle(fontSize: 7.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.1)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () => _rePrintDocument(note),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: const Icon(Icons.print_rounded, color: Color(0xFF334155), size: 14),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }

        if (state is NoteTxError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Registry Interface Failure Boundary: ${state.message}",
                  style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _infoLabel(String label, String value, {bool highlight = false}) {
    return Text(
      "$label: ${value.toUpperCase()}",
      style: TextStyle(
          fontSize: 8.5,
          color: highlight ? const Color(0xFF0284C7) : Colors.grey.shade600,
          fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
          letterSpacing: 0.1
      ),
    );
  }

  Widget _dividerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text("•", style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
    );
  }
}