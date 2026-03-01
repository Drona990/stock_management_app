import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. PDF SERVICE (With Summary)
// ==========================================================================
class ReportPrintService {
  static Future<void> generateReportPDF(String title, List data) async {
    final pdf = pw.Document();
    double totalAmt = data.fold(0, (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape, // ✅ Wide columns ke liye
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("${title.toUpperCase()} ERP ANALYTICS REPORT")),
          pw.TableHelper.fromTextArray(
            headers: ['DATE', 'LOCATION', 'ITEM NAME', 'SOLD BY', 'REMARK', 'PRICE'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: data.map((item) => [
              item['date']?.toString().split('T')[0] ?? '-',
              item['location_name'] ?? '-',
              item['item_name'] ?? '-',
              item['sold_by'] ?? 'Administrator',
              item['sale__bill_no'] ?? item['status_text'] ?? '-',
              'Rs. ${item['price']}'
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Records: ${data.length}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Net Total: Rs. ${totalAmt.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]
          )
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: '${title}_ERP_Report');
  }
}
// ==========================================================================
// 2. DATA SOURCE FOR PAGINATION
// ==========================================================================

class AdvanceReportDataSource extends DataTableSource {
  final List<dynamic> data;
  AdvanceReportDataSource(this.data);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final i = data[index];
    return DataRow(cells: [
      DataCell(Text(i['date']?.toString().split('T')[0] ?? "-", style: const TextStyle(fontSize: 11))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
        child: Text(i['location_name'] ?? "Main", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
      )),
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(i['item_name'] ?? "-", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Text("HSN: ${i['hsn'] ?? '-'}", style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      )),
      DataCell(Text(i['sold_by'] ?? "Admin", style: const TextStyle(fontSize: 11))),
      DataCell(Text(i['sale__bill_no'] ?? i['status_text'] ?? "-", style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
      DataCell(Text("₹${i['price']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))),
    ]);
  }
  @override bool get isRowCountApproximate => false;
  @override int get rowCount => data.length;
  @override int get selectedRowCount => 0;
}

// ==========================================================================
// 3. MODELS & BLOC
// ==========================================================================
class DashboardModel {
  final int currentStock, itemsSold, billCount;
  final double revenue, discountGiven;
  final List<Map<String, dynamic>> recentSales;

  DashboardModel({
    required this.currentStock, required this.itemsSold, required this.billCount,
    required this.revenue, required this.discountGiven, required this.recentSales,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final f = s['financials'] ?? {};
    return DashboardModel(
      currentStock: s['current_stock'] ?? 0,
      itemsSold: s['items_sold'] ?? 0,
      billCount: f['bill_count'] ?? 0,
      revenue: double.tryParse(f['total_revenue']?.toString() ?? '0') ?? 0,
      discountGiven: double.tryParse(f['total_discount_amt']?.toString() ?? '0') ?? 0,
      recentSales: List<Map<String, dynamic>>.from(json['recent_sales'] ?? []),
    );
  }
}

class DashboardRepository {
  final ApiClient apiClient = sl<ApiClient>();
  Future<DashboardModel> getSummary() async => DashboardModel.fromJson((await apiClient.get('/api/inventory/dashboard/')).data);
}

abstract class DashEvent {}
class LoadDash extends DashEvent {}
abstract class DashState {}
class DashLoading extends DashState {}
class DashLoaded extends DashState { final DashboardModel data; DashLoaded(this.data); }
class DashError extends DashState { final String msg; DashError(this.msg); }

class DashboardBloc extends Bloc<DashEvent, DashState> {
  final DashboardRepository repo;
  DashboardBloc(this.repo) : super(DashLoading()) {
    on<LoadDash>((event, emit) async {
      emit(DashLoading());
      try { emit(DashLoaded(await repo.getSummary())); } catch (e) { emit(DashError(e.toString())); }
    });
  }
}

class StockDashboardView extends StatefulWidget {
  const StockDashboardView({super.key});
  @override
  State<StockDashboardView> createState() => _StockDashboardViewState();
}

class _StockDashboardViewState extends State<StockDashboardView> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  int? _selectedLocationId;
  List<dynamic> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final res = await sl<ApiClient>().get('/api/inventory/locations/');
      setState(() {
        // ✅ DJANGO PAGINATION RESULTS KEY HANDLING
        if (res.data is Map && res.data.containsKey('results')) {
          _locations = res.data['results'];
        } else if (res.data is List) {
          _locations = res.data;
        }
      });
    } catch (e) { log("Location Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(sl<DashboardRepository>())..add(LoadDash()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text("ERP ANALYTICS TERMINAL", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          actions: [
            _actionBtn(context, "STOCK REPORT", Colors.blue, () => _showFilterDialog(context, "stock")),
            _actionBtn(context, "SALES REPORT", Colors.green, () => _showFilterDialog(context, "sales")),
            const SizedBox(width: 15),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashState>(
          builder: (context, state) {
            if (state is DashLoading) return const Center(child: CircularProgressIndicator());
            if (state is DashLoaded) return _buildMainDashboard(context, state.data);
            return const Center(child: Text("Connection Error"));
          },
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("REPORT CONFIGURATION (${type.toUpperCase()})"),
        content: StatefulBuilder(builder: (context, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ DROPDOWN FIX
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _selectedLocationId,
              hint: const Text("Select Branch/Location"),
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              items: [
                const DropdownMenuItem(value: null, child: Text("Global (All Branches)")),
                ..._locations.map((loc) => DropdownMenuItem<int>(
                  value: loc['id'], child: Text(loc['name'].toString()),
                )).toList(),
              ],
              onChanged: (v) {
                setS(() => _selectedLocationId = v);
                _selectedLocationId = v;
              },
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _dateTile("START", _from, (d) => setS(() => _from = d))),
                const SizedBox(width: 10),
                Expanded(child: _dateTile("END", _to, (d) => setS(() => _to = d))),
              ],
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            onPressed: () { Navigator.pop(ctx); _fetchDetailed(type); },
            child: const Text("GENERATE REPORT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _fetchDetailed(String type) async {
    final start = "${_from.year}-${_from.month.toString().padLeft(2, '0')}-${_from.day.toString().padLeft(2, '0')}";
    final end = "${_to.year}-${_to.month.toString().padLeft(2, '0')}-${_to.day.toString().padLeft(2, '0')}";
    try {
      final res = await sl<ApiClient>().get('/api/inventory/dashboard/detailed_report/', query: {
        'type': type, 'start_date': start, 'end_date': end, 'location': _selectedLocationId?.toString() ?? 'null'
      });
      _showFullscreenReport(type, res.data);
    } catch (e) { log("Fetch Error: $e"); }
  }

  void _showFullscreenReport(String title, List data) {
    final source = AdvanceReportDataSource(data);
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            title: Text("${title.toUpperCase()} ERP JOURNAL"),
            actions: [
              IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent), onPressed: () => ReportPrintService.generateReportPDF(title, data)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          body: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PaginatedDataTable(
                header: Text("Audit Logs: ${data.length} records found"),
                source: source,
                columnSpacing: 40,
                horizontalMargin: 20,
                rowsPerPage: (data.length > 10) ? 10 : (data.length > 0 ? data.length : 1),
                columns: const [
                  DataColumn(label: Text("POSTING DATE")),
                  DataColumn(label: Text("LOCATION")),
                  DataColumn(label: Text("ITEM DESCRIPTION")),
                  DataColumn(label: Text("USER/STAFF")),
                  DataColumn(label: Text("REMARK/DOC")),
                  DataColumn(label: Text("VALUATION")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPERS (Reuse existing methods) ---
  Widget _kpi(String t, String v, Color c, IconData i) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: c, width: 4))),
    child: Row(children: [
      Icon(i, color: c, size: 22), const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(t, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ])
    ]),
  );

  Widget _buildMainDashboard(BuildContext context, DashboardModel d) => SingleChildScrollView(
    padding: const EdgeInsets.all(25),
    child: Column(children: [
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, crossAxisSpacing: 20, childAspectRatio: 2.5,
        children: [
          _kpi("REVENUE", "₹${d.revenue}", Colors.green, Icons.analytics),
          _kpi("STOCK", "${d.currentStock}", Colors.blue, Icons.inventory_2),
          _kpi("SOLD", "${d.itemsSold}", Colors.orange, Icons.shopping_bag),
          _kpi("DISCOUNT", "₹${d.discountGiven}", Colors.red, Icons.discount),
        ],
      ),
      const SizedBox(height: 30),
      _recentSalesTable(d.recentSales),
    ]),
  );

  Widget _recentSalesTable(List sales) => Container(
    width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      columns: const [DataColumn(label: Text("DOC NO")), DataColumn(label: Text("CUSTOMER")), DataColumn(label: Text("PAYMENT")), DataColumn(label: Text("TOTAL"))],
      rows: sales.map((s) => DataRow(cells: [
        DataCell(Text(s['bill_no']?.toString() ?? "-", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
        DataCell(Text(s['customer_name']?.toString() ?? "CASH")),
        DataCell(Text(s['payment_mode']?.toString() ?? "CASH")),
        DataCell(Text("₹${s['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
      ])).toList(),
    ),
  );

  Widget _dateTile(String lab, DateTime dt, Function(DateTime) onPick) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(lab, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
    subtitle: Text("${dt.day}/${dt.month}/${dt.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    onTap: () async {
      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: dt);
      if (d != null) onPick(d);
    },
  );

  Widget _actionBtn(BuildContext context, String lab, Color col, VoidCallback fn) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(side: BorderSide(color: col), foregroundColor: col, backgroundColor: col.withOpacity(0.05)),
      onPressed: fn, child: Text(lab, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    ),
  );
}


