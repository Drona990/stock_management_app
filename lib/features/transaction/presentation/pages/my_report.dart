import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class MyReportsView extends StatefulWidget {
  const MyReportsView({super.key});
  @override State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  DateTime _from = DateTime.now(), _to = DateTime.now();
  List<dynamic> _mySales = [];
  bool _isLoading = false;

  @override void initState() {
    super.initState();
    _fetchMySales();
  }

  // ✅ CALLING SPECIALIZED PERSONAL ENDPOINT
  Future<void> _fetchMySales() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/api/inventory/dashboard/my_personal_report/', query: {
        'start_date': _from.toIso8601String().split('T')[0],
        'end_date': _to.toIso8601String().split('T')[0]
      });
      setState(() => _mySales = res.data ?? []);
    } catch (e) {
      log("Error fetching personal reports: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = _mySales.fold(0.0, (sum, item) => sum + (double.tryParse(item['invoice_total'].toString()) ?? 0.0));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // --- HEADER: PERFORMANCE HIGHLIGHTS ---
          _buildPremiumHeader(total),

          // --- FILTER BAR ---
          _buildFilterBar(),

          // --- TABLE SECTION ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                : _mySales.isEmpty
                ? _buildEmptyState()
                : _buildTableCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("PERSONAL ANALYTICS", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Text("My Sales Activity", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)),
              child: Text("Total Invoices: ${_mySales.length}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text("MY CONTRIBUTION", style: TextStyle(color: Colors.white60, fontSize: 10)),
            Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 26, fontWeight: FontWeight.w900)),
          ]),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _dateItem("FROM", _from, (d) => setState(() => _from = d))),
          const SizedBox(width: 10),
          Expanded(child: _dateItem("TO", _to, (d) => setState(() => _to = d))),
          const SizedBox(width: 10),
          _actionBtn(Icons.refresh_rounded, _fetchMySales),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1100, // Fixed width to prevent rendering crash
            child: PaginatedDataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 20, columnSpacing: 30, showCheckboxColumn: false,
              rowsPerPage: _mySales.length > 8 ? 8 : (_mySales.isEmpty ? 1 : _mySales.length),
              source: MyPersonalDataSource(_mySales, context),
              columns: const [
                DataColumn(label: Text("BARCODE", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("BILL NO", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("DATE", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("CUSTOMER", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("PAYMENT", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        const Text("No personal sales found for this period.", style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _dateItem(String l, DateTime dt, Function(DateTime) onP) => InkWell(
    onTap: () async {
      final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: dt);
      if(d!=null) { onP(d); _fetchMySales(); }
    },
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text("${dt.day}/${dt.month}/${dt.year}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    ),
  );

  Widget _actionBtn(IconData i, VoidCallback f) => GestureDetector(
    onTap: f,
    child: Container(
        height: 48, width: 48,
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
        child: Icon(i, color: Colors.white, size: 20)
    ),
  );
}

class MyPersonalDataSource extends DataTableSource {
  final List data; final BuildContext context;
  MyPersonalDataSource(this.data, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final r = data[index];
    String bCode = r['barcode_no'] ?? "N/A";
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((s) => index.isEven ? Colors.transparent : const Color(0xFFF8FAFC)),
      cells: [
        DataCell(Row(children: [
          const Icon(Icons.qr_code, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(bCode, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          IconButton(icon: const Icon(Icons.copy, size: 12, color: Colors.blue), onPressed: () {
            Clipboard.setData(ClipboardData(text: bCode));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barcode Copied"), behavior: SnackBarBehavior.floating));
          })
        ])),
        DataCell(Text(r['bill_no'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(r['date']?.toString().split('T')[0] ?? "-")),
        DataCell(Text(r['customer_name'] ?? "Walk-in")),
        DataCell(Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
            child: Text(r['payment_mode'] ?? "CASH", style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold))
        )),
        DataCell(Text("₹${r['invoice_total']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900))),
      ],
    );
  }
  @override bool get isRowCountApproximate => false;
  @override int get rowCount => data.length;
  @override int get selectedRowCount => 0;
}