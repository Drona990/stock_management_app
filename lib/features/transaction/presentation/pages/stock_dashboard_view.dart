
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
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("${title.toUpperCase()} REPORT")),
          pw.TableHelper.fromTextArray(
            headers: ['DATE', 'ITEM NAME', 'BARCODE', 'PRICE', 'REMARK'],
            data: data.map((item) => [
              item['date']?.toString().split('T')[0] ?? '-',
              item['item_name'] ?? '-',
              item['barcode_number'] ?? '-',
              item['price']?.toString() ?? '0',
              item['sale__bill_no'] ?? item['status'] ?? '-'
            ]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total Items: ${data.length}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Total Amount: ₹${totalAmt.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ]
          )
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: '${title}_Report');
  }
}

// ==========================================================================
// 2. DATA SOURCE FOR PAGINATION
// ==========================================================================
class ReportDataSource extends DataTableSource {
  final List<dynamic> data;
  ReportDataSource(this.data);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final i = data[index];
    return DataRow(cells: [
      DataCell(Text(i['date']?.toString().split('T')[0] ?? "-", style: const TextStyle(fontSize: 11))),
      DataCell(Text(i['item_name']?.toString() ?? "-", style: const TextStyle(fontSize: 11))),
      DataCell(Text(i['barcode_number']?.toString() ?? "-", style: const TextStyle(fontSize: 11))),
      DataCell(Text("₹${i['price']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
      DataCell(Text(i['sale__bill_no']?.toString() ?? i['status']?.toString() ?? "N/A", style: const TextStyle(fontSize: 10))),
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

// ==========================================================================
// 4. MAIN UI SCREEN
// ==========================================================================
class StockDashboardView extends StatefulWidget {
  const StockDashboardView({super.key});
  @override
  State<StockDashboardView> createState() => _StockDashboardViewState();
}

class _StockDashboardViewState extends State<StockDashboardView> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(sl<DashboardRepository>())..add(LoadDash()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text("BUSINESS ANALYTICS", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          actions: [
            _actionBtn(context, "STOCK REPORT", Colors.blue, () => _showDateDialog(context, "stock")),
            _actionBtn(context, "SALES REPORT", Colors.green, () => _showDateDialog(context, "sales")),
            const SizedBox(width: 10),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashState>(
          builder: (context, state) {
            if (state is DashLoading) return const Center(child: CircularProgressIndicator());
            if (state is DashLoaded) return _buildMainDashboard(context, state.data);
            return const Center(child: Text("Error fetching analytics"));
          },
        ),
      ),
    );
  }

  Widget _actionBtn(BuildContext context, String lab, Color col, VoidCallback fn) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(side: BorderSide(color: col), foregroundColor: col),
      onPressed: fn, child: Text(lab, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    ),
  );

  void _showDateDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Generate ${type.toUpperCase()} Report"),
        content: StatefulBuilder(builder: (context, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dateField("From Date", _from, (d) => setS(() => _from = d)),
            const SizedBox(height: 10),
            _dateField("To Date", _to, (d) => setS(() => _to = d)),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            onPressed: () { Navigator.pop(ctx); _fetchDetailed(type); },
            child: const Text("PROCEED", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _fetchDetailed(String type) async {
    final start = "${_from.year}-${_from.month.toString().padLeft(2, '0')}-${_from.day.toString().padLeft(2, '0')}";
    final end = "${_to.year}-${_to.month.toString().padLeft(2, '0')}-${_to.day.toString().padLeft(2, '0')}";
    final res = await sl<ApiClient>().get('/api/inventory/dashboard/detailed_report/', query: {'type': type, 'start_date': start, 'end_date': end});
    _showPaginatedReport(type, res.data);
  }

  void _showPaginatedReport(String title, List data) {
    double totalAmt = data.fold(0, (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0));
    final source = ReportDataSource(data);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${title.toUpperCase()} REPORT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Total Items: ${data.length} | Total Value: ₹${totalAmt.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  ]),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), onPressed: () => ReportPrintService.generateReportPDF(title, data)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ])
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    source: source,
                    columns: const [
                      DataColumn(label: Text("DATE")),
                      DataColumn(label: Text("ITEM NAME")),
                      DataColumn(label: Text("BARCODE")),
                      DataColumn(label: Text("PRICE")),
                      DataColumn(label: Text("REMARK")),
                    ],
                    rowsPerPage: data.length > 10 ? 10 : (data.length > 0 ? data.length : 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDashboard(BuildContext context, DashboardModel d) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, crossAxisSpacing: 15, childAspectRatio: 2.3,
        children: [
          _kpi("REVENUE", "₹${d.revenue}", Colors.green, Icons.payments),
          _kpi("STOCK", "${d.currentStock}", Colors.blue, Icons.inventory),
          _kpi("SOLD", "${d.itemsSold}", Colors.orange, Icons.shopping_bag),
          _kpi("DISCOUNT", "₹${d.discountGiven}", Colors.red, Icons.sell),
        ],
      ),
      const SizedBox(height: 25),
      _recentSalesTable(d.recentSales),
    ]),
  );

  Widget _kpi(String t, String v, Color c, IconData i) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      Icon(i, color: c, size: 24), const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ])
    ]),
  );

  Widget _recentSalesTable(List sales) => Container(
    width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
      columns: const [DataColumn(label: Text("BILL NO")), DataColumn(label: Text("CUSTOMER")), DataColumn(label: Text("MODE")), DataColumn(label: Text("TOTAL"))],
      rows: sales.map((s) => DataRow(cells: [
        DataCell(Text(s['bill_no']?.toString() ?? "-")),
        DataCell(Text(s['customer_name']?.toString() ?? "Cash")),
        DataCell(Text(s['payment_mode']?.toString() ?? "CASH")),
        DataCell(Text("₹${s['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
      ])).toList(),
    ),
  );

  Widget _dateField(String lab, DateTime dt, Function(DateTime) onPick) => ListTile(
    title: Text(lab, style: const TextStyle(fontSize: 12)),
    subtitle: Text("${dt.day}/${dt.month}/${dt.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
    trailing: const Icon(Icons.event),
    onTap: () async {
      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: dt);
      if (d != null) onPick(d);
    },
  );
}