
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../main/presentation/pages/bar&resturant/master_report_view.dart';
import '../widgets/performance_modal.dart';
import '../widgets/report_modal.dart';
import 'package:flutter/material.dart';


class DashboardModel {
  final int currentStock, itemsSold, billCount;
  final double revenue, discountGiven;
  final Map<String, double> revenueByMode;
  final List<Map<String, dynamic>> recentSales;

  DashboardModel({required this.currentStock, required this.itemsSold, required this.billCount, required this.revenue, required this.discountGiven, required this.recentSales, required this.revenueByMode});

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] ?? {};
    final f = s['financials'] ?? {};
    Map<String, double> revModes = {};
    if (f['revenue_by_mode'] != null) {
      (f['revenue_by_mode'] as Map).forEach((k, v) => revModes[k.toString()] = double.tryParse(v.toString()) ?? 0.0);
    }
    return DashboardModel(
      currentStock: s['current_stock'] ?? 0, itemsSold: s['items_sold'] ?? 0, billCount: f['bill_count'] ?? 0,
      revenue: double.tryParse(f['total_revenue']?.toString() ?? '0') ?? 0,
      discountGiven: double.tryParse(f['total_discount_amt']?.toString() ?? '0') ?? 0,
      revenueByMode: revModes, recentSales: List<Map<String, dynamic>>.from(json['recent_sales'] ?? []),
    );
  }
}

class DashboardRepository {
  final ApiClient _api = sl<ApiClient>();
  Future<DashboardModel> getSummary() async {
    final res = await _api.get('/api/inventory/dashboard/');
    return DashboardModel.fromJson(res.data);
  }

  Future<List<dynamic>> getDetailed(Map<String, dynamic> params) async {
    final res = await _api.get('/api/inventory/dashboard/detailed_report/', query: params);
    return res.data is List ? res.data : [];
  }
}

abstract class DashEvent {}
class LoadDash extends DashEvent {}
abstract class DashState {}
class DashLoading extends DashState {}
class DashLoaded extends DashState { final DashboardModel data; DashLoaded(this.data); }

class DashboardBloc extends Bloc<DashEvent, DashState> {
  final DashboardRepository repo;
  DashboardBloc(this.repo) : super(DashLoading()) {
    on<LoadDash>((event, emit) async {
      emit(DashLoading());
      try { emit(DashLoaded(await repo.getSummary())); } catch (e) { emit(DashLoading()); }
    });
  }
}


class StockDashboardView extends StatefulWidget {
  const StockDashboardView({super.key});
  @override State<StockDashboardView> createState() => _StockDashboardViewState();
}

class _StockDashboardViewState extends State<StockDashboardView> {
  DateTime _from = DateTime.now(), _to = DateTime.now();
  int? _selectedLocationId;
  List<dynamic> _locations = [];
  final List<Map<String, dynamic>> _months = [{"id": 1, "name": "January"}, {"id": 2, "name": "February"}, {"id": 3, "name": "March"}, {"id": 4, "name": "April"}, {"id": 5, "name": "May"}, {"id": 6, "name": "June"}, {"id": 7, "name": "July"}, {"id": 8, "name": "August"}, {"id": 9, "name": "September"}, {"id": 10, "name": "October"}, {"id": 11, "name": "November"}, {"id": 12, "name": "December"}];

  @override void initState() { super.initState(); _fetchLocation(); }

  Future<void> _fetchLocation() async {
    final res = await sl<ApiClient>().get('/api/inventory/locations/');
    setState(() { _locations = res.data is List ? res.data : res.data['results'] ?? []; });
  }

  void _fetchDetailed(String type) async {
    Map<String, dynamic> q = {
      'type': type, 'start_date': _from.toIso8601String().split('T')[0], 'end_date': _to.toIso8601String().split('T')[0]
    };
    if (_selectedLocationId != null) q['location'] = _selectedLocationId.toString();
    final data = await DashboardRepository().getDetailed(q);
    if (mounted) ReportModal.show(context, type, data);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return BlocProvider(
      create: (context) => DashboardBloc(DashboardRepository())..add(LoadDash()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text("ERP ANALYTICS", style: TextStyle(color: Colors.white, fontSize: 14)),
          // For mobile, we might want to wrap actions or use a popup menu if too many
          actions: [
            _actionBtn(
              "MASTER REPORT",
              Colors.blueAccent,
                  () => _showMasterReportDialog(),
            ),
            _actionBtn(isMobile ? "PERF" : "PERFORMANCE", Colors.purple, () => PerformanceModal.show(context, DateTime.now().month, _months, _locations)),
            _actionBtn("STOCK", Colors.blue, () => _showFilterDialog('stock')),
            _actionBtn("SALES", Colors.green, () => _showFilterDialog('sales')),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashState>(builder: (context, state) {
          if (state is DashLoaded) {
            final d = state.data;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Column(
                children: [
                  // --- Responsive KPI Grid ---
                  GridView.count(
                    crossAxisCount: isMobile ? 2 : 5, // 2 columns on mobile, 5 on desktop
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isMobile ? 2.0 : 2.3,
                    children: [
                      _kpi("REVENUE", "₹${d.revenue}", Colors.green, Icons.payments),
                      _kpi("DISCOUNT", "₹${d.discountGiven}", Colors.red, Icons.card_giftcard),
                      _kpi("STOCK", "${d.currentStock}", Colors.blue, Icons.inventory),
                      _kpi("SOLD", "${d.itemsSold}", Colors.orange, Icons.shopping_cart),
                      _kpi("BILLS", "${d.billCount}", Colors.purple, Icons.receipt_long),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Responsive Table & Chart Section ---
                  if (isMobile) ...[
                    _recentSalesTable(d.recentSales, true),
                    const SizedBox(height: 15),
                    _paymentBreakdown(d.revenueByMode),
                  ] else
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _recentSalesTable(d.recentSales, false)),
                          const SizedBox(width: 15),
                          Expanded(flex: 1, child: _paymentBreakdown(d.revenueByMode))
                        ]
                    ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }

  Widget _actionBtn(String l, Color c, VoidCallback f) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
          style: TextButton.styleFrom(backgroundColor: c, minimumSize: const Size(60, 30)),
          onPressed: f,
          child: Text(l, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))
      )
  );

  Widget _kpi(String t, String v, Color c, IconData i) => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4)],
          border: Border(left: BorderSide(color: c, width: 4))
      ),
      child: Center(
        child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(i, color: c, size: 18),
            title: Text(t, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
            )
        ),
      )
  );

  Widget _recentSalesTable(List sales, bool isMobile) => Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("RECENT SALES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
                columnSpacing: isMobile ? 40 : null,
                columns: const [DataColumn(label: Text("BILL")), DataColumn(label: Text("TOTAL"))],
                rows: sales.map((s) => DataRow(cells: [
                  DataCell(Text(s['bill_no'] ?? "-", style: const TextStyle(fontSize: 12))),
                  DataCell(Text("₹${s['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)))
                ])).toList()
            ),
          ),
        ],
      )
  );

  Widget _paymentBreakdown(Map m) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PAYMENTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const Divider(),
            ...m.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 10)),
                      Text("₹${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))
                    ]
                )
            ))
          ]
      )
  );

  void _showFilterDialog(String type) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setS) => Container(
            width: screenWidth > 500 ? 400 : screenWidth, // Responsive width
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${type.toUpperCase()} FILTERS", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _selectedLocationId,
                  decoration: _inputDecoration(Icons.business_center),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Branches")),
                    ..._locations.map((l) => DropdownMenuItem<int>(value: l['id'], child: Text(l['name'])))
                  ],
                  onChanged: (v) => setS(() => _selectedLocationId = v),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _dateTile("START", _from, () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: _from);
                      if (d != null) setS(() => _from = d);
                    })),
                    const SizedBox(width: 10),
                    Expanded(child: _dateTile("END", _to, () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: _to);
                      if (d != null) setS(() => _to = d);
                    })),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () { Navigator.pop(ctx); _fetchDetailed(type); },
                    child: const Text("GENERATE REPORT", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helpers unchanged but checked for scaling ---
  static Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
            Text("${date.day}/${date.month}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, size: 16),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
  );

  void _showMasterReportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MasterReportScreen(),
      ),
    );
  }


}