import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import 'stock_dashboard_view.dart';

class MyReportsView extends StatefulWidget {
  const MyReportsView({super.key});

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  List<dynamic> _mySales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMySales();
  }

  // ✅ API CALL: Sirf logged-in staff ki sales fetch hogi
  Future<void> _fetchMySales() async {
    setState(() => _isLoading = true);
    final start = "${_from.year}-${_from.month.toString().padLeft(2, '0')}-${_from.day.toString().padLeft(2, '0')}";
    final end = "${_to.year}-${_to.month.toString().padLeft(2, '0')}-${_to.day.toString().padLeft(2, '0')}";

    try {
      final res = await sl<ApiClient>().get(
          '/api/inventory/dashboard/detailed_report/',
          query: {
            'type': 'sales',
            'start_date': start,
            'end_date': end,
          }
      );
      setState(() => _mySales = res.data);
    } catch (e) {
      log("Error fetching my reports: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalEarned = _mySales.fold(0, (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("MY SALES REPORT", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchMySales,
          )
        ],
      ),
      body: Column(
        children: [
          // 📅 DATE FILTER SECTION
          _buildFilterHeader(),

          // 💰 TOTAL SUMMARY CARD
          _buildSummaryCard(totalEarned),

          // 📊 DATA TABLE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mySales.isEmpty
                ? const Center(child: Text("No sales found for this period"))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: PaginatedDataTable(
                header: const Text("My Sales Logs", style: TextStyle(fontSize: 12)),
                rowsPerPage: _mySales.length > 10 ? 10 : (_mySales.isEmpty ? 1 : _mySales.length),
                source: AdvanceReportDataSource(_mySales), // Dashboard wala data source reuse
                columns: const [
                  DataColumn(label: Text("DATE")),
                  DataColumn(label: Text("LOCATION")),
                  DataColumn(label: Text("ITEM")),
                  DataColumn(label: Text("USER")),
                  DataColumn(label: Text("BILL NO")),
                  DataColumn(label: Text("AMOUNT")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _datePickerTile("FROM", _from, (d) => setState(() => _from = d))),
          const SizedBox(width: 10),
          Expanded(child: _datePickerTile("TO", _to, (d) => setState(() => _to = d))),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: _fetchMySales,
            child: const Icon(Icons.search, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("MY TOTAL CONTRIBUTION", style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text("Performance Summary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _datePickerTile(String label, DateTime dt, Function(DateTime) onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime(2030), initialDate: dt);
        if (d != null) {
          onPick(d);
          _fetchMySales(); // Date change hote hi auto-fetch
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text("${dt.day}/${dt.month}/${dt.year}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}