import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/salse_purchase_legder_report_bloc.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_management/features/transaction/presentation/pages/salse_invoice_pdf_generation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class PurchaseLedgerReportPage extends StatefulWidget {
  const PurchaseLedgerReportPage({super.key});
  @override
  State<PurchaseLedgerReportPage> createState() => _PurchaseLedgerReportPageState();
}

class _PurchaseLedgerReportPageState extends State<PurchaseLedgerReportPage> {
  DateTimeRange? _dateRange;
  int? _hoveredRowIndex;
  String _searchQuery = "";
  bool _isAuditMode = false;
  List<dynamic> _cachedAuditData = [];
  bool _isAuditLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAuditData();
  }

  Future<void> _fetchAuditData() async {
    setState(() => _isAuditLoading = true);
    try {
      final response = await sl<ApiClient>().get('/api/transactions/salse-purchase-audit-report/');
      if (response.data != null && response.data['data'] != null) {
        setState(() {
          // Strict filtering out any non-purchase entries directly at ingestion boundaries
          _cachedAuditData = (response.data['data'] as List)
              .where((txn) => txn['txn_type']?.toString().toUpperCase() == "PURCHASE")
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching audit reports: $e");
    } finally {
      setState(() => _isAuditLoading = false);
    }
  }

  Future<void> _generatePdf(dynamic ledgerItem) async {
    bool isLoaderVisible = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          isLoaderVisible = true;
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD97706), strokeWidth: 1.5));
        },
      );

      final response = await sl<ApiClient>().get(
          '/api/transactions/invoice-print-data/',
          query: {'inv_no': ledgerItem['invno'], 'type': 'PURCHASE'}
      );

      if (isLoaderVisible) {
        Navigator.of(context, rootNavigator: true).pop();
        isLoaderVisible = false;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (response.data != null && response.data['status'] == 'success') {
        final Map<String, dynamic> savedData = response.data['data'];
        final Uint8List logoBytes = (await rootBundle.load('assets/images/ultra_logo.jpeg')).buffer.asUint8List();
        final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

        final pdf = await InvoicePdfService.generate(
          logoImage: logoImage,
          data: savedData,
          isSales: false,
          headings: ["ORIGINAL FOR RECIPIENT", "DUPLICATE FOR TRANSPORTER", "TRIPLICATE FOR SUPPLIER", "COPY FOR ACCOUNTS", "EXTRA COPY"],
        );

        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'Purchase_${savedData['billno']}.pdf',
        );
      }
    } catch (e) {
      if (isLoaderVisible) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- 3. PRINT LANDSCAPE PDF INCORPORATING INTERSTATE/STATE ZONES AND BOTTOM CALCULATED GRAND TOTALS ---
  Future<void> _generateAuditReportPdf(Map<String, List<dynamic>> groupedData, double grandTaxable, double grandCgst, double grandSgst, double grandIgst, double grandTotalVal) async {
    final pdf = pw.Document();

    pdf.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context context) {
              return [
                pw.Header(
                    level: 0,
                    child: pw.Row(
                        mainAxisAlignment:  pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                              crossAxisAlignment:  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text("PURCHASE AUDIT REPORT SYSTEM", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 2),
                                pw.Text("REAL-TIME PROCUREMENT MONITORING & SUPPLIER LEDGER ENTRIES DIRECTORY", style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                              ]
                          ),
                          pw.Text("Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600))
                        ]
                    )
                ),
                pw.SizedBox(height: 14),

                ...groupedData.entries.map((entry) {
                  String date = entry.key;
                  List txns = entry.value;

                  double totalTaxable = txns.fold(0.0, (sum, i) => sum + parseNum(i['total_taxable']));
                  double totalCgst = txns.fold(0.0, (sum, i) => sum + (_isState(i) ? parseNum(i['cgst']) : 0.0));
                  double totalSgst = txns.fold(0.0, (sum, i) => sum + (_isState(i) ? parseNum(i['sgst']) : 0.0));
                  double totalIgst = txns.fold(0.0, (sum, i) => sum + (!_isState(i) ? parseNum(i['igst']) : 0.0));
                  double subTotal = txns.fold(0.0, (sum, i) => sum + parseNum(i['grand_total']));

                  return pw.Column(
                      crossAxisAlignment:  pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(date, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                        pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(3),
                              1: const pw.FlexColumnWidth(1),
                              2: const pw.FlexColumnWidth(1),
                              3: const pw.FlexColumnWidth(1),
                              4: const pw.FlexColumnWidth(1),
                              5: const pw.FlexColumnWidth(1),
                            },
                            children: [
                              // Header
                              pw.TableRow(
                                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("PARTY NAME", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("TAXABLE", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("CGST", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("SGST", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("IGST", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("TOTAL", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                  ]
                              ),
                              // Rows
                              ...txns.map((txn) {
                                bool localState = _isState(txn);
                                return pw.TableRow(
                                    children: [
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(txn['party_name']?.toString().toUpperCase() ?? '', style: const pw.TextStyle(fontSize: 7))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(parseNum(txn['total_taxable']).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(localState ? parseNum(txn['cgst']).toStringAsFixed(2) : "0.00", style: const pw.TextStyle(fontSize: 7))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(localState ? parseNum(txn['sgst']).toStringAsFixed(2) : "0.00", style: const pw.TextStyle(fontSize: 7))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(!localState ? parseNum(txn['igst']).toStringAsFixed(2) : "0.00", style: const pw.TextStyle(fontSize: 7))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(parseNum(txn['grand_total']).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 7))),
                                    ]
                                );
                              }),
                              // Subtotal
                              pw.TableRow(
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalTaxable.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalCgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalSgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalIgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(subTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                                  ]
                              )
                            ]
                        ),
                        pw.SizedBox(height: 8),
                      ]
                  );
                }).toList(),

                pw.SizedBox(height: 10),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                ),
                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(1),
                      5: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(grandTaxable.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(grandCgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(grandSgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(grandIgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(grandTotalVal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800))),
                          ]
                      )
                    ]
                )
              ];
            }
        )
    );

    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Purchase_Audit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        format: PdfPageFormat.a4.landscape
    );
  }

  static bool _isState(dynamic txn) {
    final zone = txn['tax_zone']?.toString().toUpperCase() ?? 'STATE';
    return zone == 'STATE';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 950;

    final filteredAuditList = _cachedAuditData.where((txn) {
      final pName = txn['party_name']?.toString().toLowerCase() ?? "";
      final dateStr = txn['txn_date']?.toString().toLowerCase() ?? "";
      return pName.contains(_searchQuery) || dateStr.contains(_searchQuery);
    }).toList();

    final Map<String, List<dynamic>> groupedMap = {};
    double grandTaxable = 0.0;
    double grandCgst = 0.0;
    double grandSgst = 0.0;
    double grandIgst = 0.0;
    double grandTotalVal = 0.0;

    for (var txn in filteredAuditList) {
      String dateKey = txn['txn_date']?.toString() ?? 'N/A';
      groupedMap.putIfAbsent(dateKey, () => []).add(txn);

      grandTaxable += parseNum(txn['total_taxable']);
      if (_isState(txn)) {
        grandCgst += parseNum(txn['cgst']);
        grandSgst += parseNum(txn['sgst']);
      } else {
        grandIgst += parseNum(txn['igst']);
      }
      grandTotalVal += parseNum(txn['grand_total']);
    }

    return BlocProvider(
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Purchase")),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          toolbarHeight: 52,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B), size: 18),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PURCHASE LEDGER AUDIT REPORT",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3)),
              Text("REAL-TIME PROCUREMENT MONITORING & SUPPLIER LEDGER ENTRIES DIRECTORY",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold))
            ],
          ),
          shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toggleNavButton(label: "LEDGER VIEW", active: !_isAuditMode, onTap: () => setState(() => _isAuditMode = false)),
                    Container(width: 1, color: Colors.grey.shade300),
                    _toggleNavButton(label: "AUDIT REPORT", active: _isAuditMode, onTap: () => setState(() => _isAuditMode = true)),
                  ],
                ),
              ),
            ),
            if (_isAuditMode)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0F172A), size: 18),
                tooltip: "Print Landscape Report Layout",
                onPressed: () => _generateAuditReportPdf(groupedMap, grandTaxable, grandCgst, grandSgst, grandIgst, grandTotalVal),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            _buildTopStats(isMobile),
            _buildFilterSection(isMobile),
            const Divider(height: 1),
            Expanded(
              child: _isAuditMode
                  ? _buildAuditReportList(filteredAuditList, groupedMap, grandTaxable, grandCgst, grandSgst, grandIgst, grandTotalVal)
                  : _buildTransactionList(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleNavButton({required String label, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        color: active ? const Color(0xFF0F172A) : Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF475569),
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  double parseNum(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildAuditReportList(List<dynamic> filteredList, Map<String, List<dynamic>> grouped, double grandTaxable, double grandCgst, double grandSgst, double grandIgst, double grandTotalVal) {
    if (_isAuditLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment_late_outlined, size: 22, color: Colors.grey),
            SizedBox(height: 6),
            Text("No reports trace found matching query text parameters.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0,right: 24, top: 12.0, bottom: 4.0),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text("PARTY NAME", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
              Expanded(child: Text("TAXABLE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
              Expanded(child: Text("CGST", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
              Expanded(child: Text("SGST", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
              Expanded(child: Text("IGST", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
              Expanded(child: Text("TOTAL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(thickness: 1),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: grouped.length + 1,
            itemBuilder: (context, index) {
              if (index == grouped.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 14.0, bottom: 28.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        border: Border.all(color: const Color(0xFF94A3B8), width: 1.5)
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        const Expanded(flex: 3, child: Text("GRAND TOTALS:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandTaxable.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandCgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandSgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandIgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandTotalVal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFFD97706)))),
                      ],
                    ),
                  ),
                );
              }

              String date = grouped.keys.elementAt(index);
              List txns = grouped[date]!;

              double totalTaxable = txns.fold(0.0, (sum, i) => sum + parseNum(i['total_taxable']));
              double totalCgst = txns.fold(0.0, (sum, i) => sum + (_isState(i) ? parseNum(i['cgst']) : 0.0));
              double totalSgst = txns.fold(0.0, (sum, i) => sum + (_isState(i) ? parseNum(i['sgst']) : 0.0));
              double totalIgst = txns.fold(0.0, (sum, i) => sum + (!_isState(i) ? parseNum(i['igst']) : 0.0));
              double subTotal = txns.fold(0.0, (sum, i) => sum + parseNum(i['grand_total']));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(date, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0F172A))),
                  ),
                  ...txns.map((txn) {
                    bool localState = _isState(txn);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(txn['party_name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                          Expanded(child: Text(parseNum(txn['total_taxable']).toStringAsFixed(2), style: const TextStyle(fontSize: 10, color: Color(0xFF334155)))),
                          Expanded(child: Text(localState ? parseNum(txn['cgst']).toStringAsFixed(2) : "0.00", style: const TextStyle(fontSize: 10, color: Color(0xFF334155)))),
                          Expanded(child: Text(localState ? parseNum(txn['sgst']).toStringAsFixed(2) : "0.00", style: const TextStyle(fontSize: 10, color: Color(0xFF334155)))),
                          Expanded(child: Text(!localState ? parseNum(txn['igst']).toStringAsFixed(2) : "0.00", style: const TextStyle(fontSize: 10, color: Color(0xFF334155)))),
                          Expanded(child: Text(parseNum(txn['grand_total']).toStringAsFixed(2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                        ],
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 16.0),
                    child: Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFFE2E8F0)),
                              top: BorderSide(color: Color(0xFFE2E8F0))
                          )
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Expanded(flex: 3, child: SizedBox()),
                          Expanded(child: Text(totalTaxable.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF1E293B)))),
                          Expanded(child: Text(totalCgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF1E293B)))),
                          Expanded(child: Text(totalSgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF1E293B)))),
                          Expanded(child: Text(totalIgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF1E293B)))),
                          Expanded(child: Text(subTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF475569)))),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopStats(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        final summary = (state is LedgerLoaded) ? state.summary : {};
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              _modernStatTile("TOTAL PURCHASE (CR)", "₹ ${summary['total_credit'] ?? '0'}", Icons.shopping_bag_outlined, Colors.orange),
              const SizedBox(width: 8),
              _modernStatTile("TOTAL PAID (DR)", "₹ ${summary['total_debit'] ?? '0'}", Icons.payments_outlined, Colors.blue),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _modernStatTile("OUTSTANDING BALANCE", "₹ ${summary['closing_balance'] ?? '0'}", Icons.account_balance_wallet, Colors.redAccent),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _modernStatTile(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.08), radius: 14, child: Icon(icon, color: color, size: 12)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(val, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 35,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "FILTER BY DATE (YYYY-MM-DD), PROCUREMENT VOUCHER ID OR SUPPLIER PROFILE NAME...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD97706), size: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _dateFilterButton(),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
        if (state is LedgerLoaded) {
          final filteredData = state.data.where((item) {
            final name = item['inname']?.toString().toLowerCase() ?? "";
            final invNo = item['invno']?.toString().toLowerCase() ?? "";
            final serialNo = item['inv_bill_no']?.toString().toLowerCase() ?? "";
            final dateStr = item['invdate']?.toString().toLowerCase() ?? "";
            return name.contains(_searchQuery) || invNo.contains(_searchQuery) || serialNo.contains(_searchQuery) || dateStr.contains(_searchQuery);
          }).toList();

          if (filteredData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_sharp, size: 22, color: Colors.grey),
                  SizedBox(height: 6),
                  Text("Zero commercial procurement parameters logged under matching criteria rows.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: filteredData.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => _buildTransactionCard(filteredData[index], index, isMobile),
          );
        }
        return const Center(child: Text("Error synchronizing procurement database directory ledger tracks"));
      },
    );
  }

  Widget _buildTransactionCard(dynamic item, int index, bool isMobile) {
    bool isHovered = _hoveredRowIndex == index;
    bool isLive = item['delflag'] == ' ';
    String autoBillNo = item['inv_bill_no']?.toString() ?? 'N/A';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Color(0xFF2E4053), width: 4.5),
            top: BorderSide(color: isHovered ? const Color(0xFFD97706) : Colors.grey.shade200, width: 1),
            bottom: BorderSide(color: isHovered ? const Color(0xFFD97706) : Colors.grey.shade200, width: 1),
            right: BorderSide(color: isHovered ? const Color(0xFFD97706) : Colors.grey.shade200, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF2E4053).withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                    child: const Text("PURCHASE VOUCHER", style: TextStyle(color: Color(0xFF2E4053), fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  ),
                  _buildReprintTrigger(item),
                ],
              ),
              const SizedBox(height: 4),
              Text(item['inname']?.toString().toUpperCase() ?? 'N/A', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 5),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  _metaLabel("SERIAL NO", autoBillNo, highlight: true),
                  _bullet(),
                  _metaLabel("VOUCHER REF", item['invno'] ?? 'N/A'),
                  _bullet(),
                  _metaLabel("DATE", item['invdate'] ?? 'N/A'),
                ],
              ),
              if (item['inaddress'] != null && item['inaddress'].toString().trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("ADDRESS: ${item['inaddress']}".toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.blueGrey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _typeBadge(item['ctype']),
                  Row(
                    children: [
                      _amountCol("PAID (DR)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                      const SizedBox(width: 16),
                      _amountCol("PURCHASE (CR)", "₹${item['trcr']}", const Color(0xFFDC2626)),
                    ],
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
                        Text(item['inname']?.toString().toUpperCase() ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFF2E4053).withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                          child: const Text("PURCHASE VOUCHER", style: TextStyle(color: Color(0xFF2E4053), fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                        ),
                        const SizedBox(width: 8),
                        _typeBadge(item['ctype']),
                        const SizedBox(width: 6),
                        _statusBadge(isLive),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _metaLabel("SERIAL NO", autoBillNo, highlight: true),
                        _bullet(),
                        _metaLabel("VOUCHER REF ID", item['invno'] ?? 'N/A'),
                        _bullet(),
                        _metaLabel("BILL DATE", item['invdate'] ?? 'N/A'),
                        if (item['tranno'] != null) ...[
                          _bullet(),
                          _metaLabel("SYSTEM ID", "#${item['tranno']}"),
                        ]
                      ],
                    ),
                    if (item['inaddress'] != null && item['inaddress'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text("SUPPLIER BILLING ADDRESS: ${item['inaddress']}".toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.blueGrey, fontWeight: FontWeight.w900, letterSpacing: 0.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _amountCol("PAID AMOUNT (DR)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  const SizedBox(width: 24),
                  _amountCol("PROCUREMENT VALUE (CR)", "₹${item['trcr']}", const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(width: 24),
              _buildReprintTrigger(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCol(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildReprintTrigger(dynamic item) {
    return InkWell(
      onTap: () => _generatePdf(item),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300)
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print_rounded, color: Color(0xFF475569), size: 12),
            SizedBox(width: 4),
            Text("REPRINT", style: TextStyle(fontSize: 8, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _metaLabel(String label, String value, {bool active = false, bool highlight = false}) {
    return Text(
      "$label: ${value.toUpperCase()}",
      style: TextStyle(
          fontSize: 8.5,
          color: highlight ? const Color(0xFFD97706) : (active ? const Color(0xFF0284C7) : Colors.grey.shade600),
          fontWeight: (active || highlight) ? FontWeight.w900 : FontWeight.bold,
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

  Widget _typeBadge(String? type) {
    bool isTo = type?.toLowerCase() == 'to';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: isTo ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(2)),
      child: Text(type?.toUpperCase() ?? "TO", style: TextStyle(color: isTo ? Colors.green : Colors.blue, fontSize: 7, fontWeight: FontWeight.w900)),
    );
  }

  Widget _statusBadge(bool live) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: live ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(2)),
      child: Text(live ? "LIVE" : "VOID", style: TextStyle(color: live ? Colors.green[800] : Colors.red[800], fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
    );
  }

  Widget _dateFilterButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDialog<DateTimeRange>(
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Theme(
                      data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2E4053))),
                      child: DateRangePickerDialog(
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        initialDateRange: _dateRange,
                      ),
                    ),
                  ),
                ),
              );
            }
        );

        if (picked != null) {
          setState(() => _dateRange = picked);
          context.read<LedgerBloc>().add(LoadLedgerData(
            type: "Purchase",
            fromDate: DateFormat('yyyy-MM-dd').format(picked.start),
            toDate: DateFormat('yyyy-MM-dd').format(picked.end),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF2E4053).withOpacity(0.08), borderRadius: BorderRadius.zero),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF2E4053)),
            const SizedBox(width: 8),
            Text(_dateRange == null ? "DATE FILTER" : "${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF2E4053))),
          ],
        ),
      ),
    );
  }
}