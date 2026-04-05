import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/salse_purchase_legder_report_bloc.dart';

class PurchaseLedgerReportPage extends StatefulWidget {
  const PurchaseLedgerReportPage({super.key});
  @override
  State<PurchaseLedgerReportPage> createState() => _PurchaseLedgerReportPageState();
}

class _PurchaseLedgerReportPageState extends State<PurchaseLedgerReportPage> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return BlocProvider(
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Purchase")),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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

  // --- 1. STATS CARDS (Summary) ---
  Widget _buildTopStats(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        final summary = (state is LedgerLoaded) ? state.summary : {};
        return Row(
          children: [
            _modernStatTile("Total Purchase", "₹ ${summary['total_credit'] ?? '0'}", Icons.shopping_bag_outlined, Colors.orange),
            const SizedBox(width: 16),
            _modernStatTile("Total Paid", "₹ ${summary['total_debit'] ?? '0'}", Icons.payments_outlined, Colors.blue),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              _modernStatTile("Outstanding", "₹ ${summary['closing_balance'] ?? '0'}", Icons.account_balance_wallet, Colors.redAccent),
            ]
          ],
        );
      },
    );
  }

  // --- 2. CUSTOM TABLE CARD ---
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
          // Scrollable Header & Body
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Horizontal scroll for All Columns
              child: SizedBox(
                width: isMobile ? 1200 : 1600, // Fixed width for horizontal content
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

  // --- 3. STICKY HEADER (All DB Fields) ---
  Widget _buildTableStickyHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        children: [
          _headerCell("TR. NO", 1),
          _headerCell("TR. DATE", 1.5),
          _headerCell("BILL DETAILS (INV NO/DATE)", 2.5),
          _headerCell("PARTY INFO (NAME/GST)", 3),
          _headerCell("ADDRESS", 3),
          _headerCell("DEBIT (DR)", 1.5),
          _headerCell("CREDIT (CR)", 1.5),
          _headerCell("TYPE", 1),
          _headerCell("STATUS", 1),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double flex) => Expanded(
    flex: (flex * 100).toInt(),
    child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11)),
  );

  // --- 4. DYNAMIC ROWS (All DB Fields) ---
  Widget _buildTableRows() {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) return const Center(child: CircularProgressIndicator());
        if (state is LedgerLoaded) {
          return ListView.separated(
            itemCount: state.data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.data[index];
              return _buildDataRow(item);
            },
          );
        }
        return const Center(child: Text("No records available"));
      },
    );
  }

  Widget _buildDataRow(dynamic item) {
    bool isLive = item['delflag'] == ' ';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          // 1. TRANNO
          Expanded(flex: 100, child: Text("#${item['tranno']}", style: const TextStyle(fontSize: 12, color: Colors.grey))),

          // 2. TRDATE
          Expanded(flex: 150, child: Text(item['trdate'] ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),

          // 3. BILL DETAILS (INVNO & INVDATE)
          Expanded(flex: 250, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['invno'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Text("Date: ${item['invdate']}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          )),

          // 4. PARTY INFO (INNAME & INVGST)
          Expanded(flex: 300, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['inname']?.toString().toUpperCase() ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E293B))),
              Text("GST: ${item['invgst'] ?? 'N/A'}", style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
            ],
          )),

          // 5. INADDRESS
          Expanded(flex: 300, child: Text(item['inaddress'] ?? "-",
              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),

          // 6. TRDR
          Expanded(flex: 150, child: Text("₹ ${item['trdr']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w700))),

          // 7. TRCR
          Expanded(flex: 150, child: Text("₹ ${item['trcr']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),

          // 8. CTYPE (To/By)
          Expanded(flex: 100, child: _typeBadge(item['ctype'])),

          // 9. DELFLAG (Status)
          Expanded(flex: 100, child: _statusBadge(isLive)),
        ],
      ),
    );
  }

  // --- UI COMPONENTS (Badges) ---

  Widget _typeBadge(String? type) {
    bool isTo = type?.toLowerCase() == 'to';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isTo ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
      child: Text(type ?? "To", textAlign: TextAlign.center, style: TextStyle(color: isTo ? Colors.green : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(bool live) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: live ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text(live ? "LIVE" : "VOID", textAlign: TextAlign.center, style: TextStyle(color: live ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  // Summary Stat Card
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

  // Filter Bar logic remains same...
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
                decoration: const InputDecoration(hintText: "Search Ledger...", icon: Icon(Icons.search, size: 18), border: InputBorder.none),
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
          const Icon(Icons.calendar_today_outlined, size: 14),
          const SizedBox(width: 8),
          Text(_dateRange == null ? "Date" : "${DateFormat('dd MMM').format(_dateRange!.start)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // Header implementation same as previous professional header...
  Widget _buildProfessionalHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF38BDF8), size: 24),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Purchase Ledger", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Industry Grade Audit Log", style: TextStyle(color: Colors.white60, fontSize: 10)),
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
      label: const Text("PRINT"),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black, elevation: 0),
    );
  }
}