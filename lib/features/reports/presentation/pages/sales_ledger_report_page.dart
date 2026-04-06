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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return BlocProvider(
      create: (context) => LedgerBloc(LedgerRepository())..add(LoadLedgerData(type: "Sales")),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Soft slate background
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
                    _buildFilterSection(isMobile),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTransactionList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. PREMIUM HEADER ---
  Widget _buildProfessionalHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Deep navy
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF38BDF8),
            child: Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sales Ledger", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              Text("Real-time Revenue Monitoring", style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const Spacer(),
          if (!isMobile)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text("EXPORT CSV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  // --- 2. STATS ---
  Widget _buildTopStats(bool isMobile) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        final summary = (state is LedgerLoaded) ? state.summary : {};
        return Row(
          children: [
            _modernStatTile("GROSS SALES", "₹${summary['total_debit'] ?? '0'}", Icons.show_chart, Colors.blue),
            const SizedBox(width: 16),
            _modernStatTile("TOTAL RECEIPTS", "₹${summary['total_credit'] ?? '0'}", Icons.account_balance, Colors.greenAccent),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              _modernStatTile("NET REVENUE", "₹${summary['closing_balance'] ?? '0'}", Icons.account_balance_wallet, Colors.orange),
            ]
          ],
        );
      },
    );
  }

  Widget _modernStatTile(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 16, child: Icon(icon, color: color, size: 16)),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  // --- 3. FILTER SECTION ---
  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()), // Frontend Filter Trigger
              decoration: InputDecoration(
                hintText: "Filter by Invoice # or Customer Name...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const VerticalDivider(width: 20),
          _dateFilterButton(),
        ],
      ),
    );
  }

  // --- 4. TRANSACTION LIST WITH FRONTEND FILTERING ---
  Widget _buildTransactionList() {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) return const Center(child: CircularProgressIndicator());
        if (state is LedgerLoaded) {
          // Frontend Filtering Logic
          final filteredData = state.data.where((item) {
            final name = item['inname']?.toString().toLowerCase() ?? "";
            final invNo = item['invno']?.toString().toLowerCase() ?? "";
            return name.contains(_searchQuery) || invNo.contains(_searchQuery);
          }).toList();

          if (filteredData.isEmpty) return const Center(child: Text("No records match your search"));

          return ListView.builder(
            itemCount: filteredData.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => _buildTransactionCard(filteredData[index], index),
          );
        }
        return const Center(child: Text("Error loading data"));
      },
    );
  }

  Widget _buildTransactionCard(dynamic item, int index) {
    bool isHovered = _hoveredRowIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isHovered ? const Color(0xFF38BDF8) : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isHovered ? 0.08 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt, color: Color(0xFF475569), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['invno'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text("Bill Date: ${item['invdate']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  // Hover Action
                  if (isHovered)
                    IconButton(
                      icon: const Icon(Icons.file_open, color: Colors.redAccent, size: 20),
                      onPressed: () => _generatePdf(item),
                      tooltip: "View PDF",
                    ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CONSIGNEE", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(item['inname']?.toString().toUpperCase() ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                  _amountCol("DEBIT", "₹${item['trdr']}", const Color(0xFF2563EB)),
                  _amountCol("CREDIT", "₹${item['trcr']}", const Color(0xFFDC2626)),
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
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
      ],
    );
  }

  Widget _dateFilterButton() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2101));
        if (picked != null) {
          setState(() => _dateRange = picked);
          context.read<LedgerBloc>().add(LoadLedgerData(
            fromDate: DateFormat('yyyy-MM-dd').format(picked.start),
            toDate: DateFormat('yyyy-MM-dd').format(picked.end),
          ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 16, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text(_dateRange == null ? "Date Filter" : DateFormat('dd MMM').format(_dateRange!.start), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
          ],
        ),
      ),
    );
  }
}