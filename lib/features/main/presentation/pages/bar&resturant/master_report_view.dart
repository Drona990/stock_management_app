
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

class MasterReportScreen extends StatefulWidget {
  const MasterReportScreen({super.key});
  @override
  State<MasterReportScreen> createState() => _MasterReportScreenState();
}

class _MasterReportScreenState extends State<MasterReportScreen> {
  String _category = 'SALES';
  String _reportType = 'TODAY';
  String? _selectedSubMaster;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  final Color kPrimary = const Color(0xFF0F172A);
  final Color kHeaderColor = const Color(0xFF1E293B);

  Future<void> _fetchReport() async {
    setState(() { _isLoading = true; _reportData = null; _selectedSubMaster = null; });
    Map<String, dynamic> params = {'category': _category, 'type': _reportType};
    if (_category == 'SALES') {
      if (_reportType == 'MONTH') params['month'] = _selectedMonth;
      if (_reportType == 'CUSTOM') {
        params['start_date'] = DateFormat('yyyy-MM-dd').format(_start);
        params['end_date'] = DateFormat('yyyy-MM-dd').format(_end);
      }
    }
    try {
      final res = await sl<ApiClient>().get('/api/inventory/reports/', query: params);
      if (!mounted) return;
      setState(() { _reportData = res.data; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMsg("Error: $e", isError: true);
    }
  }

  // --- MULTI-PLATFORM XLSX DOWNLOAD ---
  Future<void> _downloadXlsx() async {
    if (_reportData == null) return;
    setState(() => _isLoading = true);

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Audit_Report'];
      excel.delete('Sheet1');

      List data = _reportData!['data'];

      // Table Headers (Exactly as your working code)
      if (_category == 'STOCK') {
        sheetObject.appendRow([
          TextCellValue("BARCODE"), TextCellValue("ITEM GROUP"), TextCellValue("ITEM NAME"),
          TextCellValue("LOCATION"), TextCellValue("PRICE")
        ]);
        for (var row in data) {
          sheetObject.appendRow([
            TextCellValue(row['barcode']?.toString() ?? ""),
            TextCellValue(row['group']?.toString() ?? ""),
            TextCellValue(row['sub_master']?.toString() ?? ""),
            TextCellValue(row['item_location_name']?.toString() ?? "N/A"),
            DoubleCellValue(double.tryParse(row['price'].toString()) ?? 0.0),
          ]);
        }
      } else {
        sheetObject.appendRow([
          TextCellValue("BILL NO"), TextCellValue("CUSTOMER"), TextCellValue("DATE"),
          TextCellValue("TOTAL"), TextCellValue("MODE")
        ]);
        for (var inv in data) {
          sheetObject.appendRow([
            TextCellValue(inv['bill_no'].toString()),
            TextCellValue(inv['customer'].toString()),
            TextCellValue(inv['date'].toString()),
            DoubleCellValue(double.tryParse(inv['total'].toString()) ?? 0.0),
            TextCellValue(inv['mode'].toString()),
          ]);
        }
      }

      var fileBytes = excel.encode()!;
      final String fileName = "Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (kIsWeb) {
        // --- WEB DOWNLOAD LOGIC ---
        final content = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(content);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showMsg("XLSX Download Started", isError: false);
      } else {
        // --- MOBILE/DESKTOP DOWNLOAD LOGIC ---
        final directory = await getTemporaryDirectory();
        final String path = "${directory.path}/$fileName";
        final file = File(path);
        await file.writeAsBytes(fileBytes);

        if (mounted) {
          await Share.shareXFiles([XFile(path)], text: 'Business Audit Export');
        }
      }
    } catch (e) {
      _showMsg("Export Failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PDF GENERATION (Multi-Platform compatible by default via Printing) ---
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final List data = _reportData!['data'];
    final summary = _reportData!['summary'] ?? {};

    Map<String, int> locSummary = {};
    if (_category == 'STOCK') {
      for (var item in data) {
        String loc = item['item_location_name'] ?? "Main Store";
        locSummary[loc] = (locSummary[loc] ?? 0) + 1;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("BUSINESS AUDIT REPORT - $_category", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text("Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: _category == 'SALES'
                    ? [
                  pw.Text("Total Revenue: Rs. ${double.parse(summary['rev'].toString()).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Total Bills: ${data.length}"),
                ]
                    : [
                  pw.Text("Total Pieces: ${summary['total_count']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Net Valuation: Rs. ${double.parse(summary['total_val'].toString()).toStringAsFixed(2)}"),
                ]
            ),
          ),
          pw.SizedBox(height: 15),
          if (_category == 'STOCK') ...[
            pw.Text("LOCATION WISE SUMMARY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              headers: ['Location / Rack Name', 'Item Count'],
              data: locSummary.entries.map((e) => [e.key, e.value.toString()]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            ),
            pw.SizedBox(height: 20),
          ],
          if (_category == 'SALES')
            ...data.map((inv) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  color: PdfColors.blueGrey100,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Inv: ${inv['bill_no']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("Customer: ${inv['customer']}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Date: ${inv['date']}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Mode: ${inv['mode']}", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text("Total: Rs. ${double.parse(inv['total'].toString()).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
                pw.Table.fromTextArray(
                  headers: ['Product Name', 'Barcode', 'HSN', 'CGST', 'SGST', 'Rate'],
                  data: (inv['items'] as List).map((itm) => [
                    itm['name'],
                    itm['barcode'],
                    itm['hsn'],
                    "Rs. ${double.parse(itm['cgst_amt'].toString()).toStringAsFixed(2)}",
                    "Rs. ${double.parse(itm['sgst_amt'].toString()).toStringAsFixed(2)}",
                    "Rs. ${double.parse(itm['rate'].toString()).toStringAsFixed(2)}"
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 10),
              ],
            )).toList()
          else
            pw.Table.fromTextArray(
              headers: ['Item Group', 'Item Name', 'HSN', 'Price','Location'],
              data: data.map((e) => [
                e['group'],
                e['sub_master'],
                e['hsn'],
                "Rs. ${double.parse(e['price'].toString()).toStringAsFixed(2)}",
                e['item_location_name'] ?? "N/A"
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: AppBar(
        backgroundColor: kPrimary,
        // manually back button enable karne ke liye (Optional agar Navigator use ho raha hai)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
            "AUDIT CENTER",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)
        ),
        actions: [
          if (_reportData != null) ...[
            IconButton(
                icon: const Icon(Icons.table_view, color: Colors.greenAccent),
                onPressed: _downloadXlsx
            ),
            IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: _generatePdf
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          _buildCategoryToggle(),
          _buildDynamicFilterPanel(),
          if (_reportData != null) _buildSummaryBanner(),
          Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildScrollableTable()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_reportData != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton.small(
                heroTag: "p",
                backgroundColor: Colors.redAccent,
                onPressed: _generatePdf,
                child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
              ),
            ),
          FloatingActionButton.extended(
            heroTag: "g",
            backgroundColor: kPrimary,
            onPressed: _fetchReport,
            icon: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
            label: const Text(
              "GENERATE DATA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING HELPER WIDGETS (UNCHANGED) ---
  Widget _buildCategoryToggle() => Container(color: Colors.white, padding: const EdgeInsets.all(8), child: SegmentedButton<String>(
    segments: const [ButtonSegment(value: 'SALES', label: Text('SALES'), icon: Icon(Icons.receipt)), ButtonSegment(value: 'STOCK', label: Text('STOCK'), icon: Icon(Icons.inventory))],
    selected: {_category}, onSelectionChanged: (v) => setState(() { _category = v.first; _reportData = null; }),
  ));

  Widget _buildDynamicFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_category == 'SALES') ...[
            Row(
              children: ["TODAY", "MONTH", "CUSTOM"].map((t) {
                bool isSelected = _reportType == t;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(child: Text(t, style: TextStyle(color: isSelected ? Colors.white : kPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                      selected: isSelected, selectedColor: kPrimary, backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false, onSelected: (v) => setState(() => _reportType = t),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_reportType == 'MONTH') Padding(padding: const EdgeInsets.only(top: 12), child: _buildMonthDropdown()),
            if (_reportType == 'CUSTOM') Padding(padding: const EdgeInsets.only(top: 8), child: _buildCustomDatePickers()),
          ],
          if (_category == 'STOCK' && _reportData != null) _buildStockSubMasterFilter(),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() => DropdownButtonFormField<int>(
    value: _selectedMonth, decoration: const InputDecoration(labelText: "Month"),
    items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(DateFormat('MMMM').format(DateTime(2026, i+1))))),
    onChanged: (v) => setState(() => _selectedMonth = v!),
  );

  Widget _buildCustomDatePickers() => Row(children: [
    Expanded(child: ListTile(title: const Text("From", style: TextStyle(fontSize: 10)), subtitle: Text(DateFormat('dd/MM/yy').format(_start)), onTap: () async { var d = await showDatePicker(context: context, initialDate: _start, firstDate: DateTime(2024), lastDate: DateTime.now()); if(d!=null) setState(()=>_start=d); })),
    Expanded(child: ListTile(title: const Text("To", style: TextStyle(fontSize: 10)), subtitle: Text(DateFormat('dd/MM/yy').format(_end)), onTap: () async { var d = await showDatePicker(context: context, initialDate: _end, firstDate: DateTime(2024), lastDate: DateTime.now()); if(d!=null) setState(()=>_end=d); })),
  ]);

  Widget _buildStockSubMasterFilter() {
    Map counts = _reportData!['item_wise_counts'] ?? {};
    return DropdownButtonFormField<String>(
      value: _selectedSubMaster, decoration: const InputDecoration(labelText: "Item Filter", border: OutlineInputBorder()),
      items: [const DropdownMenuItem(value: null, child: Text("All Items")), ...counts.keys.map((k) => DropdownMenuItem(value: k, child: Text("$k (${counts[k]})"))) ],
      onChanged: (v) => setState(() => _selectedSubMaster = v),
    );
  }

  Widget _buildSummaryBanner() {
    final s = _reportData!['summary'] ?? {};

    // SALES ke liye 'rev', STOCK ke liye 'total_val' (Amount)
    double totalAmount = double.parse((_category == 'SALES' ? s['rev'] : s['total_val']).toString());

    // Count nikalne ke liye (Bills for Sales, Pieces for Stock)
    int totalCount = _category == 'SALES' ? (_reportData!['data'] as List).length : (s['total_count'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Yahan Amount dikhega (Valuation/Revenue)
          _kpi(_category == 'SALES' ? "REVENUE" : "VALUATION", "₹${totalAmount.toStringAsFixed(2)}"),

          // Yahan Count dikhega (Qty/Bills) - Isme ₹ hataya gaya hai
          _kpi(_category == 'SALES' ? "BILLS" : "TOTAL QTY", "$totalCount"),
        ],
      ),
    );
  }
  Widget _kpi(String l, String v) => Column(children: [Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10))]);

  Widget _buildScrollableTable() {
    if (_reportData == null) return const Center(child: Text("Ready to generate."));
    List data = _reportData!['data'];
    if (_category == 'STOCK') {
      if (_selectedSubMaster != null) data = data.where((e) => e['sub_master'] == _selectedSubMaster).toList();
      return _buildFullStockTable(data);
    } else {
      return _buildSalesNestedList(data);
    }
  }

  Widget _buildFullStockTable(List data) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kHeaderColor),
          columns: ["BARCODE", "ITEM GROUP", "ITEM NAME", "CGST", "SGST", "COST PRICE", "LOCATION"].map((s) => DataColumn(label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11)))).toList(),
          rows: data.map((e) => DataRow(cells: [
            DataCell(Text(e['barcode'].toString())),
            DataCell(Text(e['group'].toString())), DataCell(Text(e['sub_master'].toString())),
            DataCell(Text("${e['cgst']}%")), DataCell(Text("${e['sgst']}%")),
            DataCell(Text("₹${double.parse(e['price'].toString()).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
            DataCell(Text(e['item_location_name'] ?? "N/A")),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildSalesNestedList(List data) {
    return ListView.builder(
      itemCount: data.length, padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final inv = data[i];
        return Card(
          child: ExpansionTile(
            title: Text(inv['bill_no'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            subtitle: Text("${inv['customer']} | ₹${double.parse(inv['total'].toString()).toStringAsFixed(2)}"),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.green.shade800),
                  columns: ["ITEM", "BARCODE", "CGST", "SGST", "PRICE"].map((s) => DataColumn(label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 10)))).toList(),
                  rows: (inv['items'] as List).map((itm) => DataRow(cells: [
                    DataCell(Text(itm['name'].toString())),
                    DataCell(Text(itm['barcode'].toString())),
                    DataCell(Text("₹${double.parse(itm['cgst_amt'].toString()).toStringAsFixed(2)}")),
                    DataCell(Text("₹${double.parse(itm['sgst_amt'].toString()).toStringAsFixed(2)}")),
                    DataCell(Text("₹${double.parse(itm['rate'].toString()).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ])).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }
}