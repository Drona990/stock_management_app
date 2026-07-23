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

class SalesLedgerReportPage extends StatefulWidget {
  const SalesLedgerReportPage({super.key});
  @override
  State<SalesLedgerReportPage> createState() => _SalesLedgerReportPageState();
}

class _SalesLedgerReportPageState extends State<SalesLedgerReportPage> {
  DateTimeRange? _dateRange;
  int? _hoveredRowIndex;
  String _searchQuery = "";

  // View State Management Variables
  bool _isAuditMode = false;
  bool _isCustomerLedgerMode = false;

  List<dynamic> _cachedAuditData = [];
  bool _isAuditLoading = false;

  // Real API Server State Variables
  List<dynamic> _customersList = [];
  bool _isCustomersLoading = false;
  String? _selectedCustomerId;

  Map<String, dynamic>? _serverPartySummary;
  List<dynamic> _serverLedgerEntries = [];
  bool _isLedgerEntriesLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAuditData();
    _fetchCustomers();
  }

  // 🟢 Fetches master ledger rows safely
  Future<void> _fetchCustomers() async {
    setState(() => _isCustomersLoading = true);
    try {
      final response = await sl<ApiClient>().get(
          '/api/master/ledger/',
          query: {'group': 'SUNDRY DEBTOR'}
      );

      if (response.data != null) {
        setState(() {
          if (response.data['results'] != null) {
            _customersList = response.data['results'] as List;
          } else if (response.data['data'] != null) {
            _customersList = response.data['data'] as List;
          } else if (response.data is List) {
            _customersList = response.data as List;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching customer masters: $e");
    } finally {
      setState(() => _isCustomersLoading = false);
    }
  }

  // 🟢 Chronological Account Book retrieval engine
  Future<void> _fetchLedgerWiseStatement(String ledgerId) async {
    setState(() => _isLedgerEntriesLoading = true);
    try {
      final Map<String, dynamic> queryParameters = {
        'ledger_id': ledgerId,
        'party_type': 'CUSTOMER',
      };

      if (_dateRange != null) {
        queryParameters['from_date'] = DateFormat('yyyy-MM-dd').format(_dateRange!.start);
        queryParameters['to_date'] = DateFormat('yyyy-MM-dd').format(_dateRange!.end);
      }

      final response = await sl<ApiClient>().get(
        '/api/transactions/ledger-statement/',
        query: queryParameters,
      );

      print("ledger statement data $response");


      if (response.data != null && response.data['status'] == 'success') {
        setState(() {
          _serverPartySummary = response.data['party'];
          _serverLedgerEntries = response.data['ledger_entries'] as List;
        });
      }
    } catch (e) {
      debugPrint("Error fetching statement logs: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch ledger details: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLedgerEntriesLoading = false);
    }
  }

  Future<void> _fetchAuditData() async {
    setState(() => _isAuditLoading = true);
    try {
      final response = await sl<ApiClient>().get('/api/transactions/salse-purchase-audit-report/');
      if (response.data != null && response.data['data'] != null) {
        setState(() {
          _cachedAuditData = (response.data['data'] as List)
              .where((txn) => txn['txn_type']?.toString().toUpperCase() == "SALES")
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 1.5));
        },
      );

      final response = await sl<ApiClient>().get(
          '/api/transactions/invoice-print-data/',
          query: {'inv_no': ledgerItem['invno'], 'type': 'SALES'}
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
          isSales: true,
          headings: ["ORIGINAL FOR RECIPIENT", "DUPLICATE FOR TRANSPORTER", "TRIPLICATE FOR SUPPLIER", "COPY FOR ACCOUNTS", "EXTRA COPY"],
        );

        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'Sales_${savedData['billno']}.pdf',
        );
      }
    } catch (e) {
      if (isLoaderVisible) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }


  // 🟢 FIXED PRINT LAYOUT: Strictly Right Aligns Numerical Amounts

  Future<void> _generateCustomerLedgerPdf(Map<String, dynamic> party, List<dynamic> entries) async {
    final pdf = pw.Document();

    // Font fetch logic for Currency Symbol (₹) rendering
    final ttfFont = await PdfGoogleFonts.notoSansRegular();
    final boldTtfFont = await PdfGoogleFonts.notoSansBold();

    const String currencySymbol = "₹ ";

    double currentBal = parseNum(party['opening_balance']);
    double totalDr = 0.0;
    double totalCr = 0.0;

    final List<pw.TableRow> rowsMatrix = [];

    // Header Configuration Entry
    rowsMatrix.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("DATE", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("TXN TYPE", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("REF NO", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("NARRATION", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("DEBIT (DR)", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("CREDIT (CR)", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("BALANCE", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))),
        ],
      ),
    );

    for (var entry in entries) {
      double dr = parseNum(entry['debit']);
      double cr = parseNum(entry['credit']);
      totalDr += dr;
      totalCr += cr;
      currentBal = currentBal + dr - cr;

      String dynamicFormattedDate = entry['date'] ?? '';
      try {
        dynamicFormattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(entry['date']));
      } catch (_) {}

      rowsMatrix.add(
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(dynamicFormattedDate, style: const pw.TextStyle(fontSize: 6.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(entry['type'] ?? '', style: const pw.TextStyle(fontSize: 6.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(entry['ref_no'] ?? '', style: const pw.TextStyle(fontSize: 6.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(entry['description']?.toString().toUpperCase() ?? '', style: const pw.TextStyle(fontSize: 6.5))),
            // Currency symbol mapping for inside data cells
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text(currencySymbol + (dr > 0 ? dr.toStringAsFixed(2) : '0.00'), style: const pw.TextStyle(fontSize: 6.5)))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text(currencySymbol + (cr > 0 ? cr.toStringAsFixed(2) : '0.00'), style: const pw.TextStyle(fontSize: 6.5)))),
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text(currencySymbol + currentBal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)))),
          ],
        ),
      );
    }

    pdf.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4, // FIXED: Landscape hata kar Portrait kiya
            margin: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 20), // Reduced margin for portrait layout
            theme: pw.ThemeData.withFont(
              base: ttfFont,
              bold: boldTtfFont,
            ),
            build: (pw.Context context) {
              return [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("CLIENTS STATEMENT OF ACCOUNT LEDGER BOOK", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text("CUSTOMER: ${party['name']}".toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                            pw.Text("Customer System Reference ID: ${party['id']}", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                          ]
                      ),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 7)),
                            pw.Text("Opening Bal: $currencySymbol${parseNum(party['opening_balance']).toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ]
                      )
                    ]
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  // FIXED: Column widths optimized narrowly to perfectly fit A4 Portrait
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.1), // Date
                    1: const pw.FlexColumnWidth(1.0), // Txn Type
                    2: const pw.FlexColumnWidth(1.1), // Ref No
                    3: const pw.FlexColumnWidth(2.2), // Narration
                    4: const pw.FlexColumnWidth(1.2), // Debit
                    5: const pw.FlexColumnWidth(1.2), // Credit
                    6: const pw.FlexColumnWidth(1.3), // Balance
                  },
                  children: rowsMatrix,
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("Total Billing Dispatches (DR): $currencySymbol${totalDr.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 7.5)),
                          pw.Text("Total Receipts Collection (CR): $currencySymbol${totalCr.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 7.5)),
                          pw.Divider(color: PdfColors.black, thickness: 0.5),
                          pw.Text("Total Net Outstanding Asset Receivable: $currencySymbol${currentBal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        ]
                    )
                )
              ];
            }
        )
    );

    // FIXED: Normal Print format passing clean A4 without orientation shifts
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Sales_Customer_Statement_${party['id']}.pdf',
      format: PdfPageFormat.a4,
    );
  }

  Future<void> _generateAuditReportPdf(
      Map<String, List<dynamic>> groupedData,
      double grandTaxable,
      double grandCgst,
      double grandSgst,
      double grandIgst,
      double grandTotalVal
      ) async {
    final pdf = pw.Document();

    // Font fetch logic for Currency Symbol (₹)
    final ttfFont = await PdfGoogleFonts.notoSansRegular();
    final boldTtfFont = await PdfGoogleFonts.notoSansBold();

    const String currencySymbol = "₹ ";

    pdf.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4, // Changed to Normal Portrait
            margin: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 20), // Reduced margin for portrait
            theme: pw.ThemeData.withFont(
              base: ttfFont,
              bold: boldTtfFont,
            ),
            build: (pw.Context context) {
              return [
                pw.Header(
                    level: 0,
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1.0))),
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text("SALES AUDIT REPORT SYSTEM", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 2),
                                pw.Text("REAL-TIME TAX COMPLIANCE ACCOUNTING LEDGER DIRECTORY", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                              ]
                          ),
                          pw.Text("Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600))
                        ]
                    )
                ),
                pw.SizedBox(height: 10),

                ...groupedData.entries.map((entry) {
                  String date = entry.key;
                  List txns = entry.value;

                  double totalTaxable = txns.fold(0.0, (sum, i) => sum + parseNum(i['total_taxable']));
                  double totalCgst = txns.fold(0.0, (sum, i) => sum + (_isState(i) ? parseNum(i['cgst']) : 0.0));
                  double totalSgst = txns.fold(0.0, (sum, i) => sum + (_isState(i) ? parseNum(i['sgst']) : 0.0));
                  double totalIgst = txns.fold(0.0, (sum, i) => sum + (!_isState(i) ? parseNum(i['igst']) : 0.0));
                  double subTotal = txns.fold(0.0, (sum, i) => sum + parseNum(i['grand_total']));

                  String formattedDisplayDate = date;
                  try {
                    formattedDisplayDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
                  } catch (_) {}

                  return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                          child: pw.Text(formattedDisplayDate, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ),
                        pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                            // Optimised narrower column widths for Portrait A4
                            columnWidths: {
                              0: const pw.FlexColumnWidth(1.2),
                              1: const pw.FlexColumnWidth(2.2),
                              2: const pw.FlexColumnWidth(1.1),
                              3: const pw.FlexColumnWidth(0.9),
                              4: const pw.FlexColumnWidth(0.9),
                              5: const pw.FlexColumnWidth(0.9),
                              6: const pw.FlexColumnWidth(1.3),
                            },
                            children: [
                              pw.TableRow(
                                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("INV / BILL", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("PARTY NAME", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("TAXABLE", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("CGST", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("SGST", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("IGST", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("TOTAL", style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                                  ]
                              ),

                              ...txns.map((txn) {
                                bool localState = _isState(txn);
                                String billNumber = txn['inv_bill_no']?.toString() ?? txn['inv_no']?.toString() ?? '-';

                                return pw.TableRow(
                                    children: [
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(billNumber, style: const pw.TextStyle(fontSize: 5.5))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(txn['party_name']?.toString().toUpperCase() ?? '', style: const pw.TextStyle(fontSize: 5.5))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + parseNum(txn['total_taxable']).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 5.5))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(localState ? currencySymbol + parseNum(txn['cgst']).toStringAsFixed(2) : "${currencySymbol}0.00", style: const pw.TextStyle(fontSize: 5.5))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(localState ? currencySymbol + parseNum(txn['sgst']).toStringAsFixed(2) : "${currencySymbol}0.00", style: const pw.TextStyle(fontSize: 5.5))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(!localState ? currencySymbol + parseNum(txn['igst']).toStringAsFixed(2) : "${currencySymbol}0.00", style: const pw.TextStyle(fontSize: 5.5))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + parseNum(txn['grand_total']).toStringAsFixed(2), style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold))),
                                    ]
                                );
                              }),

                              pw.TableRow(
                                  decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("", style: const pw.TextStyle(fontSize: 5.5))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold)))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + totalTaxable.toStringAsFixed(2), style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + totalCgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + totalSgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + totalIgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(currencySymbol + subTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900))),
                                  ]
                              )
                            ]
                        ),
                        pw.SizedBox(height: 6),
                      ]
                  );
                }).toList(),

                pw.SizedBox(height: 8),

                pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.4),
                      1: const pw.FlexColumnWidth(1.1),
                      2: const pw.FlexColumnWidth(0.9),
                      3: const pw.FlexColumnWidth(0.9),
                      4: const pw.FlexColumnWidth(0.9),
                      5: const pw.FlexColumnWidth(1.3),
                    },
                    children: [
                      pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text("GRAND TOTALS:", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencySymbol + grandTaxable.toStringAsFixed(2), style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencySymbol + grandCgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencySymbol + grandSgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencySymbol + grandIgst.toStringAsFixed(2), style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencySymbol + grandTotalVal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green800))),
                          ]
                      )
                    ]
                )
              ];
            }
        )
    );

    // Normal Print preview without rotating the paper (Portrait Format)
    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Sales_Audit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        format: PdfPageFormat.a4
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
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Sales")),
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
              const Text("SALES LEDGER AUDIT REPORT",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3)),
              Text(_isCustomerLedgerMode ? "INDIVIDUAL CUSTOMER DETAILED ACCOUNT STATEMENT DIRECTORY" : "REAL-TIME REVENUE MONITORING & RECIPIENT LEDGER ENTRIES DIRECTORY",
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
                    _toggleNavButton(label: "LEDGER VIEW", active: !_isAuditMode && !_isCustomerLedgerMode, onTap: () => setState(() { _isAuditMode = false; _isCustomerLedgerMode = false; })),
                    Container(width: 1, color: Colors.grey.shade300),
                    _toggleNavButton(label: "AUDIT REPORT", active: _isAuditMode && !_isCustomerLedgerMode, onTap: () => setState(() { _isAuditMode = true; _isCustomerLedgerMode = false; })),
                    Container(width: 1, color: Colors.grey.shade300),
                    _toggleNavButton(label: "VIEW LEDGER WISE", active: _isCustomerLedgerMode, onTap: () => setState(() { _isCustomerLedgerMode = true; _isAuditMode = false; })),
                  ],
                ),
              ),
            ),
            if (_isAuditMode && !_isCustomerLedgerMode)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0F172A), size: 18),
                tooltip: "Print Landscape Report Layout",
                onPressed: () => _generateAuditReportPdf(groupedMap, grandTaxable, grandCgst, grandSgst, grandIgst, grandTotalVal),
              ),
            if (_isCustomerLedgerMode && _selectedCustomerId != null && _serverPartySummary != null)
              IconButton(
                icon: const Icon(Icons.print_outlined, color: Color(0xFF0284C7), size: 18),
                tooltip: "Export Customer Ledger Statement PDF",
                onPressed: () {
                  _generateCustomerLedgerPdf(_serverPartySummary!, _serverLedgerEntries);
                },
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            if (!_isCustomerLedgerMode) _buildTopStats(isMobile),
            if (!_isCustomerLedgerMode) _buildFilterSection(isMobile),
            if (!_isCustomerLedgerMode) const Divider(height: 1),
            Expanded(
              child: _buildMainContentBody(filteredAuditList, groupedMap, grandTaxable, grandCgst, grandSgst, grandIgst, grandTotalVal, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContentBody(List filteredAuditList, Map<String, List> groupedMap, double grandTaxable, double grandCgst, double grandSgst, double grandIgst, double grandTotalVal, bool isMobile) {
    if (_isCustomerLedgerMode) {
      return _buildCustomerLedgerWiseView();
    }
    if (_isAuditMode) {
      return _buildAuditReportList(filteredAuditList, groupedMap, grandTaxable, grandCgst, grandSgst, grandIgst, grandTotalVal);
    }
    return _buildTransactionList(isMobile);
  }

  Widget _buildCustomerLedgerWiseView() {
    if (_isCustomersLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0284C7)));
    }

    // Filter customers explicitly on the frontend loop block to only allow SUNDRY DEBTOR profiles
    final List<dynamic> strictlyDebtorsOnly = _customersList.where((c) {
      final String grp = c['group']?.toString().toUpperCase() ?? '';
      return grp == 'SUNDRY DEBTOR' || grp == 'SALES';
    }).toList();

    double runningCalcBalance = _serverPartySummary != null ? parseNum(_serverPartySummary!['opening_balance']) : 0.0;
    double summaryDebitTotal = 0.0;
    double summaryCreditTotal = 0.0;

    for (var entry in _serverLedgerEntries) {
      summaryDebitTotal += parseNum(entry['debit']);
      summaryCreditTotal += parseNum(entry['credit']);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCustomerId,
                hint: const Text("CHOOSE OR SELECT DEBTOR CUSTOMER CLIENT REGISTER PROFILE...", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                isExpanded: true,
                items: strictlyDebtorsOnly.map((cust) {
                  final String currentId = cust['id']?.toString() ?? '';
                  return DropdownMenuItem<String>(
                    value: currentId,
                    child: Text("${cust['id']} - ${cust['name']}".toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCustomerId = val;
                    });
                    _fetchLedgerWiseStatement(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedCustomerId == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.supervised_user_circle_outlined, size: 36, color: Colors.blueGrey),
                    SizedBox(height: 8),
                    Text("Select a customer client database line row item to view accounts directory tracks.", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else if (_isLedgerEntriesLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0284C7))))
          else ...[
              Row(
                children: [
                  _miniAccountStatTile("OPENING BALANCE", "₹ ${runningCalcBalance.toStringAsFixed(2)}", Colors.blueGrey),
                  const SizedBox(width: 8),
                  _miniAccountStatTile("GROSS SALES BILLING (DR)", "₹ ${summaryDebitTotal.toStringAsFixed(2)}", Colors.blue),
                  const SizedBox(width: 8),
                  _miniAccountStatTile("TOTAL RECEIVED (CR)", "₹ ${summaryCreditTotal.toStringAsFixed(2)}", Colors.green),
                  const SizedBox(width: 8),
                  _miniAccountStatTile("NET OUTSTANDING DUE", "₹ ${(runningCalcBalance + summaryDebitTotal - summaryCreditTotal).toStringAsFixed(2)}", const Color(0xFF0F172A)),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: const Color(0xFFF1F5F9),
                        child: Row(
                          children: const [
                            Expanded(flex: 2, child: Text("DATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF475569)))),
                            Expanded(flex: 2, child: Text("TXN TYPE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF475569)))),
                            Expanded(flex: 2, child: Text("REF / INVOICE ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF475569)))),
                            Expanded(flex: 4, child: Text("PARTICULARS / NARRATION ENTRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF475569)))),
                            Expanded(flex: 2, child: Text("DEBIT (DR) [+]", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blue))),
                            Expanded(flex: 2, child: Text("CREDIT (CR) [-]", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.green))),
                            Expanded(flex: 2, child: Text("BALANCE (₹)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Color(0xFF0F172A)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _serverLedgerEntries.isEmpty
                            ? const Center(child: Text("Zero trading transaction tracks encountered under filtered parameter specifications.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))
                            : ListView.builder(
                          itemCount: _serverLedgerEntries.length,
                          itemBuilder: (context, index) {
                            final item = _serverLedgerEntries[index];
                            double dr = parseNum(item['debit']);
                            double cr = parseNum(item['credit']);
                            runningCalcBalance = runningCalcBalance + dr - cr;

                            String uiFormattedDisplayDate = item['date'] ?? '';
                            try {
                              uiFormattedDisplayDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(item['date']));
                            } catch (_) {}

                            return Container(
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(uiFormattedDisplayDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500))),
                                  Expanded(flex: 2, child: _getTxnTypeBadge(item['type'] ?? '')),
                                  Expanded(flex: 2, child: Text(item['ref_no'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                                  Expanded(flex: 4, child: Text(item['description'].toString().toUpperCase(), style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
                                  Expanded(flex: 2, child: Text(dr > 0 ? "₹ ${dr.toStringAsFixed(2)}" : "-", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600))),
                                  Expanded(flex: 2, child: Text(cr > 0 ? "₹ ${cr.toStringAsFixed(2)}" : "-", style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600))),
                                  Expanded(flex: 2, child: Text("₹ ${runningCalcBalance.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ]
        ],
      ),
    );
  }

  Widget _miniAccountStatTile(String label, String value, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 7.5, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textCol)),
          ],
        ),
      ),
    );
  }

  Widget _getTxnTypeBadge(String type) {
    Color col = Colors.grey;
    if (type == "SALES") col = Colors.blue;
    if (type == "RECEIPT") col = Colors.green;
    if (type == "JOURNAL") col = Colors.amber.shade900;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: col.withOpacity(0.1)),
          child: Text(type, style: TextStyle(color: col, fontSize: 7.5, fontWeight: FontWeight.w900)),
        ),
      ],
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
          padding: const EdgeInsets.only(left: 24.0, right: 24, top: 12.0, bottom: 4.0),
          child: Row(
            children: const [
              Expanded(flex: 1, child: Text("BILL NO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Color(0xFF475569)))),
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
                        const Expanded(flex: 4, child: Text("GRAND TOTALS:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandTaxable.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandCgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandSgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandIgst.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF0F172A)))),
                        Expanded(child: Text(grandTotalVal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF16A34A)))),
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

              String auditDisplayDate = date;
              try {
                auditDisplayDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
              } catch (_) {}

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 🟢 FIXED ENUM HERE
                children: [ // 🟢 FIXED CHILDREN LIST
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(auditDisplayDate, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0F172A))),
                  ),
                  ...txns.map((txn) {
                    bool localState = _isState(txn);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text(txn['inv_bill_no']?.toString() ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
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
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)), top: BorderSide(color: Color(0xFFE2E8F0)))),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Expanded(flex: 4, child: SizedBox()),
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
              _modernStatTile("GROSS SALES (DR)", "₹ ${summary['total_debit'] ?? '0'}", Icons.show_chart, Colors.blue),
              const SizedBox(width: 8),
              _modernStatTile("TOTAL RECEIPTS (CR)", "₹ ${summary['total_credit'] ?? '0'}", Icons.account_balance, Colors.green),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _modernStatTile("NET BALANCES REVENUE", "₹ ${summary['closing_balance'] ?? '0'}", Icons.account_balance_wallet, Colors.orange),
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
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade200)),
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
                  Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
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
                  hintText: "FILTER BY DATE (YYYY-MM-DD), INVOICE SERIAL ID OR CUSTOMER CONSIGNMENT NAME...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 14),
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
                  Icon(Icons.receipt_long_sharp, size: 22, color: Colors.grey),
                  SizedBox(height: 6),
                  Text("Zero commercial sales parameters logged under matching criteria rows.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
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
        return const Center(child: Text("Error synchronizing revenue database directory ledger tracks"));
      },
    );
  }

  Widget _buildTransactionCard(dynamic item, int index, bool isMobile) {
    bool isHovered = _hoveredRowIndex == index;
    String autoBillNo = item['inv_bill_no']?.toString() ?? 'N/A';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Color(0xFF0F172A), width: 4.5),
            top: BorderSide(color: isHovered ? const Color(0xFF38BDF8) : Colors.grey.shade200, width: 1),
            bottom: BorderSide(color: isHovered ? const Color(0xFF38BDF8) : Colors.grey.shade200, width: 1),
            right: BorderSide(color: isHovered ? const Color(0xFF38BDF8) : Colors.grey.shade200, width: 1),
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
                    decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.08)),
                    child: const Text("SALES INVOICE", style: TextStyle(color: Color(0xFF0F172A), fontSize: 6.5, fontWeight: FontWeight.bold)),
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
                  _metaLabel("DOC ID", item['invno'] ?? 'N/A'),
                  _bullet(),
                  _metaLabel("DATE", item['invdate'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountCol("DEBIT VAL (REV)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  _amountCol("CREDIT VAL (REC)", "₹${item['trcr']}", const Color(0xFFDC2626)),
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
                          decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.08)),
                          child: const Text("SALES INVOICE", style: TextStyle(color: Color(0xFF0F172A), fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _metaLabel("SERIAL NO", autoBillNo, highlight: true),
                        _bullet(),
                        _metaLabel("DOC ID", item['invno'] ?? 'N/A'),
                        _bullet(),
                        _metaLabel("RECORDING DATE", item['invdate'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _amountCol("DEBIT VAL (REV)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  const SizedBox(width: 24),
                  _amountCol("CREDIT VAL (REC)", "₹${item['trcr']}", const Color(0xFFDC2626)),
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
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildReprintTrigger(dynamic item) {
    return InkWell(
      onTap: () => _generatePdf(item),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: Colors.grey.shade300)),
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
        color: highlight ? const Color(0xFF16A085) : (active ? const Color(0xFF0284C7) : Colors.grey.shade600),
        fontWeight: (active || highlight) ? FontWeight.w900 : FontWeight.bold,
      ),
    );
  }

  Widget _bullet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text("•", style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
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
                    child: Theme(
                      data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0F172A))),
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

          if (_isCustomerLedgerMode && _selectedCustomerId != null) {
            _fetchLedgerWiseStatement(_selectedCustomerId!);
          } else {
            context.read<LedgerBloc>().add(LoadLedgerData(
              type: "Sales",
              fromDate: DateFormat('yyyy-MM-dd').format(picked.start),
              toDate: DateFormat('yyyy-MM-dd').format(picked.end),
            ));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.08)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Text(_dateRange == null ? "DATE FILTER" : "${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}