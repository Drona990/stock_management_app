/*
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

class LedgerReportScreen extends StatefulWidget {
  const LedgerReportScreen({super.key});

  @override
  State<LedgerReportScreen> createState() => _LedgerReportScreenState();
}

class _LedgerReportScreenState extends State<LedgerReportScreen> {
  int? _selectedLedgerId;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<LedgerMasterBloc>().add(LoadData());
  }

  Future<void> _fetchReport(int id) async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/api/transactions/cash-ledger-report/$id/detailed_report/');
      setState(() {
        _reportData = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack("Error: $e", Colors.red);
    }
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Light Grayish Blue Background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("LEDGER STATEMENT",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        actions: [
          if (_selectedLedgerId != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: () => _fetchReport(_selectedLedgerId!),
            )
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                : _reportData == null
                ? _buildInitialState()
                : _buildReportList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]
      ),
      child: BlocBuilder<LedgerMasterBloc, LedgerState>(
        builder: (context, state) {
          List ledgers = state is LLoaded ? state.data : [];

          return DropdownSearch<dynamic>(
            items: (f, l) => ledgers,
            filterFn: (item, filter) => item['name'].toString().toLowerCase().contains(filter.toLowerCase()),
            compareFn: (i, s) => i['id'] == s['id'],
            itemAsString: (item) => item['name'].toString(),

            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search Ledger...",
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1A237E)),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              itemBuilder: (context, item, isSelected, isHovered) {
                return ListTile(
                  dense: true,
                  title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  subtitle: Text(item['group'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                );
              },
            ),

            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: ledgers.isEmpty ? "Loading Ledgers..." : "Select Customer / Supplier",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              ),
            ),

            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedLedgerId = v['id']);
                _fetchReport(v['id']);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildReportList() {
    var summary = _reportData!['summary'];
    List txns = _reportData!['transactions'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(summary),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.history, size: 14, color: Colors.blueGrey),
            SizedBox(width: 8),
            Text("TRANSACTION HISTORY", style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (txns.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No records found", style: TextStyle(color: Colors.grey))))
        else
          ...txns.map((t) => _buildTransactionCard(t)).toList(),
      ],
    );
  }

  Widget _buildSummaryCard(summary) {
    bool isDR = summary['type'].toString().contains('DR');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: isDR ? Colors.green : Colors.red, width: 5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryCol("TOTAL IN (REC)", "₹${summary['total_receipts']}", Colors.green.shade700),
              _summaryCol("TOTAL OUT (PAY)", "₹${summary['total_payments']}", Colors.red.shade700),
            ],
          ),
          const Divider(height: 35, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NET BALANCE", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${summary['closing_balance']}", style: const TextStyle(color: Color(0xFF1A237E), fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(isDR ? "RECEIVABLE (DR)" : "PAYABLE (CR)",
                      style: TextStyle(color: isDR ? Colors.green.shade700 : Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTransactionCard(t) {
    bool isRec = t['voucher_type'] == 'RECEIPT';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: (isRec ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(isRec ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16, color: isRec ? Colors.green.shade700 : Colors.red.shade700),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['narration'] ?? 'No Description', style: const TextStyle(color: Color(0xFF2E2E2E), fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text("${t['date']} | Vch: ${t['voucher_no']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isRec ? "₹${t['amount']}" : "₹${t['amount']}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isRec ? Colors.green.shade700 : Colors.red.shade700)),
              Text(isRec ? "CREDIT" : "DEBIT", style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryCol(String label, String val, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildInitialState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 15),
        Text("Search a Ledger to view details", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ],
    ),
  );
}*/


import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

class LedgerReportScreen extends StatefulWidget {
  const LedgerReportScreen({super.key});

  @override
  State<LedgerReportScreen> createState() => _LedgerReportScreenState();
}

class _LedgerReportScreenState extends State<LedgerReportScreen> {
  int? _selectedLedgerId;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<LedgerMasterBloc>().add(LoadData());
  }

  Future<void> _fetchReport(int id) async {
    setState(() => _isLoading = true);
    try {
      // ✅ Updated API Path
      final res = await sl<ApiClient>().get('/api/transactions/cash-ledger-report/$id/detailed_report/');
      setState(() {
        _reportData = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _snack("Error fetching report: $e", Colors.red);
    }
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("LEDGER STATEMENT",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        actions: [
          if (_selectedLedgerId != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _fetchReport(_selectedLedgerId!),
            )
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _reportData == null
                ? _buildInitialState()
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: BlocBuilder<LedgerMasterBloc, LedgerState>(
        builder: (context, state) {
          List ledgers = state is LLoaded ? state.data : [];
          return DropdownSearch<dynamic>(
            items: (f, l) => ledgers,
            compareFn: (i, s) => i['id'] == s['id'],
            itemAsString: (item) => item['name'].toString(),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(
                hintText: "Select Ledger Account",
                prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedLedgerId = v['id']);
                _fetchReport(v['id']);
              }
            },
            popupProps: const PopupProps.menu(showSearchBox: true),
          );
        },
      ),
    );
  }

  Widget _buildReportContent() {
    var summary = _reportData!['summary'];
    List txns = _reportData!['transactions'];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSummaryCard(summary),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
          child: Text("TRANSACTION DETAILS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
        ),
        if (txns.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("No transactions found.")))
        else
          ...txns.map((t) => _buildTransactionCard(t)).toList(),
      ],
    );
  }

  Widget _buildSummaryCard(summary) {
    bool isDR = summary['type'].toString().contains('DR');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDR ? Colors.blue.shade200 : Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sumItem("TOTAL DEBIT (DR)", "₹${summary['total_dr']}", Colors.blue.shade800),
                _sumItem("TOTAL CREDIT (CR)", "₹${summary['total_cr']}", Colors.orange.shade800),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("CLOSING BALANCE", style: TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹${summary['closing_balance']}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(summary['type'],
                        style: TextStyle(color: isDR ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(t) {
    // ✅ Logic: Identify if it's a Debit or Credit transaction
    String vType = t['v_type'].toString();
    String source = t['source'] ?? 'N/A';
    bool isDebit = (vType == 'PAYMENT' || vType == 'DEBIT');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: (isDebit ? Colors.red : Colors.green).withOpacity(0.1),
          child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDebit ? Colors.red : Colors.green, size: 18),
        ),
        title: Text(t['narration'] ?? 'No Narration',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text("${t['date']} | ${t['v_no']} [$source]",
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("₹${t['amount']}",
                style: TextStyle(fontWeight: FontWeight.bold, color: isDebit ? Colors.red : Colors.green)),
            Text(isDebit ? "DR" : "CR",
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _sumItem(String label, String val, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ],
  );

  Widget _buildInitialState() => const Center(
    child: Text("Please select a ledger to view the statement", style: TextStyle(color: Colors.grey)),
  );
}