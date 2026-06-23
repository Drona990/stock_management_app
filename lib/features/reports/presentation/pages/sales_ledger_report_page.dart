import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/salse_purchase_legder_report_bloc.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_management/features/transaction/presentation/pages/salse_invoice_pdf_generation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class SalesLedgerReportPage extends StatefulWidget {
  const SalesLedgerReportPage({super.key});
  @override
  State<SalesLedgerReportPage> createState() => _SalesLedgerReportPageState();
}

class _SalesLedgerReportPageState extends State<SalesLedgerReportPage> {
  DateTimeRange? _dateRange;
  int? _hoveredRowIndex;
  String _searchQuery = "";

  // --- PDF GENERATION LOGIC ---
  Future<void> _generatePdf(dynamic ledgerItem) async {
    bool isLoaderVisible = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          isLoaderVisible = true;
          return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 1.5));
        },
      );

      final response = await sl<ApiClient>().get(
          '/api/transactions/invoice-print-data/',
          query: {'inv_no': ledgerItem['invno'], 'type': 'SALES'}
      );

      if (isLoaderVisible) {
        Navigator.of(context, rootNavigator: true).pop();
        isLoaderVisible = false;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (response.data != null && response.data['status'] == 'success') {
        final Map<String, dynamic> savedData = response.data['data'];
        final Uint8List logoBytes = (await rootBundle.load('assets/images/ultra_logo.jpeg')).buffer.asUint8List();
        final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

        final pdf = await InvoicePdfService.generate(
          logoImage: logoImage,
          data: savedData,
          isSales: true,
          headings: ["ORIGINAL FOR RECIPIENT", "DUPLICATE FOR TRANSPORTER", "TRIPLICATE FOR SUPPLIER", "COPY FOR ACCOUNTS", "EXTRA COPY"],
        );

        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'Sales_${savedData['billno']}.pdf',
        );
      }
    } catch (e) {
      if (isLoaderVisible) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 950;

    return BlocProvider(
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Sales")),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          toolbarHeight: 52,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B), size: 18),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SALES LEDGER AUDIT REPORT",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3)),
              Text("REAL-TIME REVENUE MONITORING & RECIPIENT LEDGER ENTRIES DIRECTORY",
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
              _modernStatTile("GROSS SALES (DR)", "₹${summary['total_debit'] ?? '0'}", Icons.show_chart, Colors.blue),
              const SizedBox(width: 8),
              _modernStatTile("TOTAL RECEIPTS (CR)", "₹${summary['total_credit'] ?? '0'}", Icons.account_balance, Colors.green),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _modernStatTile("NET BALANCES REVENUE", "₹${summary['closing_balance'] ?? '0'}", Icons.account_balance_wallet, Colors.orange),
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
                  Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
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
                  hintText: "FILTER BY SERIAL NO, INVOICE ID OR CUSTOMER CONSIGNMENT NAME...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 14),
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

  // --- 3. HIGH-DENSITY AUDIT LIST WITH BACKEND SYNC EXTRACTION ---
  Widget _buildTransactionList(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
        if (state is LedgerLoaded) {
          // Dynamic Multi-aligned Front-end search matching filters engine
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
                  Icon(Icons.receipt_long_sharp, size: 22, color: Colors.grey),
                  const SizedBox(height: 6),
                  Text("Zero commercial sales parameters logged under matching criteria rows.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
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
        return const Center(child: Text("Error synchronizing revenue database directory ledger tracks"));
      },
    );
  }

  // --- 4. HIGH DENSITY METRIC DATA CARDS MATRIX ---
  Widget _buildTransactionCard(dynamic item, int index, bool isMobile) {
    bool isHovered = _hoveredRowIndex == index;
    String autoBillNo = item['inv_bill_no']?.toString() ?? 'N/A';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Color(0xFF0F172A), width: 4.5),
            top: BorderSide(color: isHovered ? const Color(0xFF38BDF8) : Colors.grey.shade200, width: 1),
            bottom: BorderSide(color: isHovered ? const Color(0xFF38BDF8) : Colors.grey.shade200, width: 1),
            right: BorderSide(color: isHovered ? const Color(0xFF38BDF8) : Colors.grey.shade200, width: 1),
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
                    decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                    child: const Text("SALES INVOICE", style: TextStyle(color: Color(0xFF0F172A), fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  ),
                  _buildReprintTrigger(item),
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
                  _metaLabel("DOC ID", item['invno'] ?? 'N/A'),
                  _bullet(),
                  _metaLabel("DATE", item['invdate'] ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountCol("DEBIT VAL (REV)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  _amountCol("CREDIT VAL (REC)", "₹${item['trcr']}", const Color(0xFFDC2626)),
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
                          decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.08), borderRadius: BorderRadius.circular(2)),
                          child: const Text("SALES INVOICE", style: TextStyle(color: Color(0xFF0F172A), fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _metaLabel("SERIAL NO", autoBillNo, highlight: true),
                        _bullet(),
                        _metaLabel("DOC ID", item['invno'] ?? 'N/A'),
                        _bullet(),
                        _metaLabel("RECORDING DATE", item['invdate'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _amountCol("DEBIT VAL (REV)", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  const SizedBox(width: 24),
                  _amountCol("CREDIT VAL (REC)", "₹${item['trcr']}", const Color(0xFFDC2626)),
                ],
              ),
              const SizedBox(width: 24),
              _buildReprintTrigger(item),
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

  Widget _buildReprintTrigger(dynamic item) {
    return InkWell(
      onTap: () => _generatePdf(item),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300)
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print_rounded, color: Color(0xFF475569), size: 12),
            SizedBox(width: 4),
            Text("REPRINT", style: TextStyle(fontSize: 8, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _metaLabel(String label, String value, {bool active = false, bool highlight = false}) {
    return Text(
      "$label: ${value.toUpperCase()}",
      style: TextStyle(
          fontSize: 8.5,
          color: highlight ? const Color(0xFF16A085) : (active ? const Color(0xFF0284C7) : Colors.grey.shade600),
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

  Widget _dateFilterButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (context, child) {
              return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0F172A))), child: child!);
            }
        );
        if (picked != null) {
          setState(() => _dateRange = picked);
          context.read<LedgerBloc>().add(LoadLedgerData(
            type: "Sales",
            fromDate: DateFormat('yyyy-MM-dd').format(picked.start),
            toDate: DateFormat('yyyy-MM-dd').format(picked.end),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.08), borderRadius: BorderRadius.zero),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Text(_dateRange == null ? "DATE FILTER" : "${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}