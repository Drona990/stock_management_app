import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/salse_purchase_legder_report_bloc.dart';
import 'package:flutter/services.dart';


class PurchaseLedgerReportPage extends StatefulWidget {
  const PurchaseLedgerReportPage({super.key});
  @override
  State<PurchaseLedgerReportPage> createState() => _PurchaseLedgerReportPageState();
}

class _PurchaseLedgerReportPageState extends State<PurchaseLedgerReportPage> {
  DateTimeRange? _dateRange;
  int? _hoveredRowIndex;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 950;

    return BlocProvider(
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Purchase")),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Soft industrial slate background
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          toolbarHeight: 52,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B), size: 18),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PURCHASE LEDGER AUDIT REPORT",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3)),
              Text("REAL-TIME PROCUREMENT MONITORING & SUPPLIER LEDGER ENTRIES DIRECTORY",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold))
            ],
          ),
          shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        body: Column(
          children: [
            _buildTopStats(isMobile),
            _buildFilterSection(isMobile),
            const Divider(height: 1),
            Expanded(child: _buildTransactionList(isMobile)),
          ],
        ),
      ),
    );
  }

  // --- 1. COMPACT METRICS TILES OVERVIEW ---
  Widget _buildTopStats(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        final summary = (state is LedgerLoaded) ? state.summary : {};
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              _modernStatTile("TOTAL PURCHASE (CR)", "₹ ${summary['total_credit'] ?? '0'}", Icons.shopping_bag_outlined, Colors.orange),
              const SizedBox(width: 8),
              _modernStatTile("TOTAL PAID (DR)", "₹ ${summary['total_debit'] ?? '0'}", Icons.payments_outlined, Colors.blue),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _modernStatTile("OUTSTANDING BALANCE", "₹ ${summary['closing_balance'] ?? '0'}", Icons.account_balance_wallet, Colors.redAccent),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _modernStatTile(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.08), radius: 14, child: Icon(icon, color: color, size: 12)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(val, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. REGISTRY FILTERS CONSOLE BAR ---
  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 35,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "FILTER BY SERIAL NO, PROCUREMENT VOUCHER ID OR SUPPLIER PROFILE NAME...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD97706), size: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _dateFilterButton(),
        ],
      ),
    );
  }

  // --- 3. HIGH-DENSITY AUDIT LIST WITH FRONTEND FRONT-END STRING FILTERS ---
  Widget _buildTransactionList(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
        if (state is LedgerLoaded) {
          // Multi-aligned Front-end matching logic maps auto serial entries too
          final filteredData = state.data.where((item) {
            final name = item['inname']?.toString().toLowerCase() ?? "";
            final invNo = item['invno']?.toString().toLowerCase() ?? "";
            final serialNo = item['inv_bill_no']?.toString().toLowerCase() ?? "";
            return name.contains(_searchQuery) || invNo.contains(_searchQuery) || serialNo.contains(_searchQuery);
          }).toList();

          if (filteredData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_sharp, size: 22, color: Colors.grey),
                  SizedBox(height: 6),
                  Text("Zero commercial procurement parameters logged under matching criteria rows.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: filteredData.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => _buildTransactionCard(filteredData[index], index, isMobile),
          );
        }
        return const Center(child: Text("Error synchronizing procurement database directory ledger tracks"));
      },
    );
  }

  // --- 4. HIGH DENSITY METRIC DATA CARDS MATRIX ---
  Widget _buildTransactionCard(dynamic item, int index, bool isMobile) {
    bool isHovered = _hoveredRowIndex == index;
    bool isLive = item['delflag'] == ' ';
    String autoBillNo = item['inv_bill_no']?.toString() ?? 'N/A';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Color(0xFF2E4053), width: 4.5),
            top: BorderSide(color: isHovered ? const Color(0xFFD97706) : Colors.grey.shade200, width: 1),
            bottom: BorderSide(color: isHovered ? const Color(0xFFD97706) : Colors.grey.shade200, width: 1),
            right: BorderSide(color: isHovered ? const Color(0xFFD97706) : Colors.grey.shade200, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF2E4053).withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                    child: const Text("PURCHASE VOUCHER", style: TextStyle(color: Color(0xFF2E4053), fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  ),
                  _statusBadge(isLive),
                ],
              ),
              const SizedBox(height: 4),
              Text(item['inname']?.toString().toUpperCase() ?? 'N/A', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 5),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  _metaLabel("SERIAL NO", autoBillNo, highlight: true),
                  _bullet(),
                  _metaLabel("VOUCHER REF", item['invno'] ?? 'N/A'),
                  _bullet(),
                  _metaLabel("DATE", item['invdate'] ?? 'N/A'),
                ],
              ),
              if (item['inaddress'] != null && item['inaddress'].toString().trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("ADDRESS: ${item['inaddress']}".toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.blueGrey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _typeBadge(item['ctype']),
                  Row(
                    children: [
                      _amountCol("PAID (DR)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                      const SizedBox(width: 16),
                      _amountCol("PURCHASE (CR)", "₹${item['trcr']}", const Color(0xFFDC2626)),
                    ],
                  )
                ],
              )
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item['inname']?.toString().toUpperCase() ?? 'N/A', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFF2E4053).withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                          child: const Text("PURCHASE VOUCHER", style: TextStyle(color: Color(0xFF2E4053), fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                        ),
                        const SizedBox(width: 8),
                        _typeBadge(item['ctype']),
                        const SizedBox(width: 6),
                        _statusBadge(isLive),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _metaLabel("SERIAL NO", autoBillNo, highlight: true),
                        _bullet(),
                        _metaLabel("VOUCHER REF ID", item['invno'] ?? 'N/A'),
                        _bullet(),
                        _metaLabel("BILL DATE", item['invdate'] ?? 'N/A'),
                        if (item['tranno'] != null) ...[
                          _bullet(),
                          _metaLabel("SYSTEM ID", "#${item['tranno']}"),
                        ]
                      ],
                    ),
                    if (item['inaddress'] != null && item['inaddress'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text("SUPPLIER BILLING ADDRESS: ${item['inaddress']}".toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.blueGrey, fontWeight: FontWeight.w900, letterSpacing: 0.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _amountCol("PAID AMOUNT (DR)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  const SizedBox(width: 24),
                  _amountCol("PROCUREMENT VALUE (CR)", "₹${item['trcr']}", const Color(0xFFDC2626)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCol(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
      ],
    );
  }

  Widget _metaLabel(String label, String value, {bool active = false, bool highlight = false}) {
    return Text(
      "$label: ${value.toUpperCase()}",
      style: TextStyle(
          fontSize: 8.5,
          color: highlight ? const Color(0xFFD97706) : (active ? const Color(0xFF0284C7) : Colors.grey.shade600),
          fontWeight: (active || highlight) ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: 0.1
      ),
    );
  }

  Widget _bullet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text("•", style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
    );
  }

  Widget _typeBadge(String? type) {
    bool isTo = type?.toLowerCase() == 'to';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: isTo ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(2)),
      child: Text(type?.toUpperCase() ?? "TO", style: TextStyle(color: isTo ? Colors.green : Colors.blue, fontSize: 7, fontWeight: FontWeight.w900)),
    );
  }

  Widget _statusBadge(bool live) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: live ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(2)),
      child: Text(live ? "LIVE" : "VOID", style: TextStyle(color: live ? Colors.green[800] : Colors.red[800], fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
    );
  }

  Widget _dateFilterButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (context, child) {
              return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2E4053))), child: child!);
            }
        );
        if (picked != null) {
          setState(() => _dateRange = picked);
          context.read<LedgerBloc>().add(LoadLedgerData(
            type: "Purchase",
            fromDate: DateFormat('yyyy-MM-dd').format(picked.start),
            toDate: DateFormat('yyyy-MM-dd').format(picked.end),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF2E4053).withOpacity(0.08), borderRadius: BorderRadius.zero),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF2E4053)),
            const SizedBox(width: 8),
            Text(_dateRange == null ? "DATE FILTER" : "${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF2E4053))),
          ],
        ),
      ),
    );
  }
}