
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
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

  @override void initState() { super.initState(); _fetchLocs(); }

  Future<void> _fetchLocs() async {
    final res = await sl<ApiClient>().get('/api/inventory/locations/');
    setState(() { _locations = res.data is List ? res.data : res.data['results'] ?? []; });
  }

  void _fetchDetailed(String type) async {
    Map<String, dynamic> q = {
      'type': type, 'start_date': _from.toIso8601String().split('T')[0], 'end_date': _to.toIso8601String().split('T')[0]
    };
    // Ensure we don't send string "null"
    if (_selectedLocationId != null) q['location'] = _selectedLocationId.toString();

    final data = await DashboardRepository().getDetailed(q);
    ReportModal.show(context, type, data);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(DashboardRepository())..add(LoadDash()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(backgroundColor: const Color(0xFF0F172A), title: const Text("ERP ANALYTICS", style: TextStyle(color: Colors.white, fontSize: 14)),
            actions: [_actionBtn("PERFORMANCE", Colors.purple, () => PerformanceModal.show(context, DateTime.now().month, _months, _locations)), _actionBtn("STOCK", Colors.blue, () => _showFilterDialog('stock')), _actionBtn("SALES", Colors.green, () => _showFilterDialog('sales'))]),
        body: BlocBuilder<DashboardBloc, DashState>(builder: (context, state) {
          if (state is DashLoaded) {
            final d = state.data;
            return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
              GridView.count(crossAxisCount: 5, shrinkWrap: true, crossAxisSpacing: 10, childAspectRatio: 2.3, children: [
                _kpi("REVENUE", "₹${d.revenue}", Colors.green, Icons.payments),
                _kpi("DISCOUNT", "₹${d.discountGiven}", Colors.red, Icons.card_giftcard),
                _kpi("STOCK", "${d.currentStock}", Colors.blue, Icons.inventory),
                _kpi("SOLD", "${d.itemsSold}", Colors.orange, Icons.shopping_cart),
                _kpi("BILLS", "${d.billCount}", Colors.purple, Icons.receipt_long),
              ]),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _recentSalesTable(d.recentSales)),
                const SizedBox(width: 15),
                Expanded(flex: 1, child: _paymentBreakdown(d.revenueByMode))
              ])
            ]));
          }
          return const Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }

  Widget _actionBtn(String l, Color c, VoidCallback f) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: c), onPressed: f, child: Text(l, style: const TextStyle(fontSize: 10, color: Colors.white))));
  Widget _kpi(String t, String v, Color c, IconData i) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: c, width: 4))), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 10), leading: Icon(i, color: c, size: 20), title: Text(t, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)), subtitle: Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))));
  Widget _recentSalesTable(List sales) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: DataTable(columns: const [DataColumn(label: Text("BILL")), DataColumn(label: Text("TOTAL"))], rows: sales.map((s) => DataRow(cells: [DataCell(Text(s['bill_no'] ?? "-")), DataCell(Text("₹${s['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)))] )).toList()));
  Widget _paymentBreakdown(Map m) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("PAYMENTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), const Divider(), ...m.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(fontSize: 10)), Text("₹${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))])))]));

  void _showFilterDialog(String type) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: StatefulBuilder(
          builder: (context, setS) => Container(
            width: 400, // Fixed width for consistent look
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${type.toUpperCase()} FILTERS",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1)),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 30),

                // --- Branch Selection ---
                const Text("Select Business Unit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedLocationId,
                  decoration: _inputDecoration(Icons.business_center),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Branches / Global")),
                    ..._locations.map((l) => DropdownMenuItem<int>(value: l['id'], child: Text(l['name'])))
                  ],
                  onChanged: (v) => setS(() => _selectedLocationId = v),
                ),
                const SizedBox(height: 20),

                // --- Date Range Selection ---
                const Text("Reporting Timeframe", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _dateTile("START", _from, () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: _from);
                      if (d != null) setS(() => _from = d);
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _dateTile("END", _to, () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: _to);
                      if (d != null) setS(() => _to = d);
                    })),
                  ],
                ),

                const SizedBox(height: 32),

                // --- Action Button ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _fetchDetailed(type);
                    },
                    child: const Text("GENERATE REPORT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for UI ---

  static Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 14, color: Colors.indigo),
                const SizedBox(width: 6),
                Text("${date.day}/${date.month}/${date.year}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, size: 18, color: Colors.indigo),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
  );
}