import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/salse_purchase_legder_report_bloc.dart';

class SalesLedgerReportPage extends StatefulWidget {
  const SalesLedgerReportPage({super.key});
  @override
  State<SalesLedgerReportPage> createState() => _SalesLedgerReportPageState();
}

class _SalesLedgerReportPageState extends State<SalesLedgerReportPage> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return BlocProvider(
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Sales")),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Slate background
        body: Column(
          children: [
            _buildProfessionalHeader(isMobile),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 20),
                child: Column(
                  children: [
                    _buildTopStats(isMobile),
                    const SizedBox(height: 24),
                    // Table Card
                    Expanded(child: _buildCustomTableCard(isMobile)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. PROFESSIONAL HEADER ---
  Widget _buildProfessionalHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Color(0xFF38BDF8), size: 26),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sales Ledger",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Organization Revenue Audit",
                  style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
          const Spacer(),
          if (!isMobile) _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.print_outlined, size: 16),
      label: const Text("PRINT REPORT"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // --- 2. SUMMARY STATS ---
  Widget _buildTopStats(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        final summary = (state is LedgerLoaded) ? state.summary : {};
        return Row(
          children: [
            _modernStatTile("Total Sales", "₹ ${summary['total_debit'] ?? '0'}", Icons.trending_up, Colors.blue),
            const SizedBox(width: 16),
            _modernStatTile("Receipts Total", "₹ ${summary['total_credit'] ?? '0'}", Icons.account_balance_wallet, Colors.teal),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              _modernStatTile("Net Revenue", "₹ ${summary['closing_balance'] ?? '0'}", Icons.pie_chart_outline, Colors.orange),
            ]
          ],
        );
      },
    );
  }

  Widget _modernStatTile(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 18, child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 12),
            Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                FittedBox(child: Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // --- 3. CUSTOM SCROLLABLE TABLE (CRITICAL FIX FOR OVERFLOW) ---
  Widget _buildCustomTableCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          _buildTableFilterBar(isMobile),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Horizontal Scroll Enabled
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: 1350, // Total fixed width for all columns combined
                child: Column(
                  children: [
                    _buildTableStickyHeader(),
                    const Divider(height: 1, thickness: 1),
                    Expanded(child: _buildTableRows()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableStickyHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        children: [
          _headerCell("TR. NO", 100),
          _headerCell("TR. DATE", 120),
          _headerCell("BILL DETAILS", 250),
          _headerCell("CUSTOMER INFO", 300),
          _headerCell("GSTIN", 180),
          _headerCell("DEBIT (DR)", 150),
          _headerCell("CREDIT (CR)", 150),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width) => SizedBox(
    width: width,
    child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
  );

  Widget _buildTableRows() {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
        if (state is LedgerLoaded) {
          if (state.data.isEmpty) return const Center(child: Text("No records found"));
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: state.data.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 24, endIndent: 24),
            itemBuilder: (context, index) {
              return _buildDataRow(state.data[index]);
            },
          );
        }
        return const Center(child: Text("Error loading data"));
      },
    );
  }

  Widget _buildDataRow(dynamic item) {
    bool isLive = item['delflag'] == ' ';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text("#${item['tranno']}", style: const TextStyle(fontSize: 12, color: Colors.grey))),
          SizedBox(width: 120, child: Text(item['trdate'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),

          // BILL DETAILS
          SizedBox(width: 250, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['invno'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Text("Inv Date: ${item['invdate']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          )),

          // CUSTOMER INFO
          SizedBox(width: 300, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['inname']?.toString().toUpperCase() ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              Text(item['inaddress'] ?? "No Address", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
            ],
          )),

          SizedBox(width: 180, child: Text(item['invgst'] ?? "-", style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
          SizedBox(width: 150, child: Text("₹ ${item['trdr']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w700))),
          SizedBox(width: 150, child: Text("₹ ${item['trcr']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }


  Widget _buildTableFilterBar(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: TextField(
                onChanged: (v) => context.read<LedgerBloc>().add(LoadLedgerData(search: v)),
                decoration: const InputDecoration(hintText: "Search Customer or Bill No...", icon: Icon(Icons.search, size: 18), border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _dateFilterButton(),
        ],
      ),
    );
  }

  Widget _dateFilterButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2101));
        if (picked != null) {
          setState(() => _dateRange = picked);
          context.read<LedgerBloc>().add(LoadLedgerData(fromDate: DateFormat('yyyy-MM-dd').format(picked.start), toDate: DateFormat('yyyy-MM-dd').format(picked.end)));
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(_dateRange == null ? "Period" : DateFormat('dd MMM').format(_dateRange!.start), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}