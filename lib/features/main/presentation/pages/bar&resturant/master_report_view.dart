
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
      setState(() { _reportData = res.data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- 100% FIXED PDF GENERATION (TAX SEPARATED & BARCODE ADDED) ---
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final List data = _reportData!['data'];
    final summary = _reportData!['summary'] ?? {};

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

          // Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: _category == 'SALES'
                    ? [
                  pw.Text("Total Revenue: Rs. ${summary['rev']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Total Bills: ${data.length}"),
                ]
                    : [
                  pw.Text("Total Pieces: ${summary['total_count']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Net Valuation: Rs. ${summary['total_val']}"),
                ]
            ),
          ),
          pw.SizedBox(height: 15),

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
                      pw.Text("Total: Rs. ${inv['total']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ),
                pw.Table.fromTextArray(
                  headers: ['Product Name', 'Barcode', 'HSN', 'CGST', 'SGST', 'Rate'],
                  data: (inv['items'] as List).map((itm) => [
                    itm['name'],
                    itm['barcode'], // ✅ Added Barcode
                    itm['hsn'],
                    "Rs. ${itm['cgst_amt']}", // ✅ Tax Separated
                    "Rs. ${itm['sgst_amt']}", // ✅ Tax Separated
                    "Rs. ${itm['rate']}"
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 10),
              ],
            )).toList()
          else
            pw.Table.fromTextArray(
              headers: ['Barcode', 'Item Name', 'SubMaster', 'HSN', 'CGST%', 'SGST%', 'Price'],
              data: data.map((e) => [
                e['barcode'], e['group'], e['sub_master'], e['hsn'],
                "${e['cgst']}%", "${e['sgst']}%", "Rs. ${e['price']}"
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
        title: const Text("INDUSTRIAL AUDIT CENTER", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (_reportData != null)
            IconButton(icon: const Icon(Icons.print, color: Colors.white), onPressed: _generatePdf),
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
        crossAxisAlignment: CrossAxisAlignment.end, // Align buttons to the right
        children: [
          // --- PDF PRINT BUTTON ---
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

          // --- GENERATE DATA BUTTON ---
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
      ),    );
  }

  // --- UI FILTERS ---
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
                      // ✅ Text Color Logic: Selected = White, Unselected = kPrimary
                      label: Center(
                        child: Text(
                          t,
                          style: TextStyle(
                            color: isSelected ? Colors.white : kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: kPrimary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false, // Checkmark hata diya industrial look ke liye
                      onSelected: (v) => setState(() => _reportType = t),
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
    return Container(
      padding: const EdgeInsets.all(16), margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _kpi(_category == 'SALES' ? "REVENUE" : "QTY", "₹${_category == 'SALES' ? s['rev'] : s['total_count']}"),
        _kpi(_category == 'SALES' ? "BILLS" : "VALUATION", "${_category == 'SALES' ? _reportData!['data'].length : '₹' + s['total_val'].toString()}"),
      ]),
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
          headingRowColor: MaterialStateProperty.all(kHeaderColor),
          columns: ["BARCODE", "ITEM", "SUBMASTER", "CGST", "SGST", "PRICE"].map((s) => DataColumn(label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11)))).toList(),
          rows: data.map((e) => DataRow(cells: [
            DataCell(Text(e['barcode'].toString())),
            DataCell(Text(e['group'].toString())), DataCell(Text(e['sub_master'].toString())),
            DataCell(Text("${e['cgst']}%")), DataCell(Text("${e['sgst']}%")),
            DataCell(Text("₹${e['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
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
            subtitle: Text("${inv['customer']} | ₹${inv['total']}"),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.green.shade800),
                  columns: ["ITEM", "BARCODE", "CGST", "SGST", "RATE"].map((s) => DataColumn(label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 10)))).toList(),
                  rows: (inv['items'] as List).map((itm) => DataRow(cells: [
                    DataCell(Text(itm['name'].toString())),
                    DataCell(Text(itm['barcode'].toString())), // ✅ UI fixed
                    DataCell(Text("₹${itm['cgst_amt']}")),
                    DataCell(Text("₹${itm['sgst_amt']}")),
                    DataCell(Text("₹${itm['rate']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ])).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}