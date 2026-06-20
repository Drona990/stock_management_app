import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

// =============================================================================
// BOUNDED SAFE EXTRACTION HELPER
// =============================================================================
class ReportLedgerExtractor {
  static List<dynamic> extract(dynamic data) {
    if (data is Map && data['results'] != null) {
      return data['results'] as List<dynamic>;
    }
    if (data is List) {
      return data;
    }
    return [];
  }
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LedgerMasterBloc>().add(LoadData());
      }
    });
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
      _snack("Error fetching report: $e", Colors.redAccent);
    }
  }

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m, style: const TextStyle(fontSize: 11)), backgroundColor: c, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    const Color industrialSlate = Color(0xFF1E293B);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 50,
        iconTheme: const IconThemeData(color: industrialSlate, size: 18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LEDGER STATEMENT REPORT",
                style: TextStyle(color: industrialSlate, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            Text("DETAILED AUDIT TRAIL PARAMETERS",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold))
          ],
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        actions: [
          if (_selectedLedgerId != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: industrialSlate, size: 18),
              onPressed: () => _fetchReport(_selectedLedgerId!),
            )
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5))
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: BlocBuilder<LedgerMasterBloc, LedgerState>(
        builder: (context, state) {
          List ledgers = [];
          if (state is LLoaded) {
            ledgers = ReportLedgerExtractor.extract(state.data);
          }
          return Container(
            height: 36,
            child: DropdownSearch<dynamic>(
              items: (f, l) => ledgers,
              compareFn: (i, s) => i != null && s != null && i['id'] == s['id'],
              itemAsString: (item) => item != null ? item['name'].toString().toUpperCase() : "",
              decoratorProps: const DropDownDecoratorProps(
                baseStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                    hintText: "SELECT ACCOUNT LEDGER DIRECTORY...",
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                ),
              ),
              onChanged: (v) {
                if (v != null && mounted) {
                  setState(() => _selectedLedgerId = v['id']);
                  _fetchReport(v['id']);
                }
              },
              filterFn: (item, filter) {
                if (item == null) return false;
                return item['name'].toString().toLowerCase().contains(filter.toLowerCase());
              },
              popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                      style: TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                          hintText: "Type to lookup account...",
                          hintStyle: TextStyle(fontSize: 11),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder()
                      )
                  ),
                  itemBuilder: (context, item, isSelected, isHovered) {
                    return ListTile(
                      dense: true,
                      title: Text(item['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      subtitle: Text(item['group']?.toString() ?? '', style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    );
                  }
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportContent() {
    var summary = _reportData!['summary'];
    List txns = _reportData!['transactions'] ?? [];

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(summary),
                const Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 8, left: 2),
                  child: Row(
                    children: [
                      VerticalDivider(width: 4, thickness: 10, color: Colors.blueGrey),
                      Icon(Icons.format_list_bulleted_rounded, size: 12, color: Colors.blueGrey),
                      SizedBox(width: 6),
                      Text("ACCOUNT TRANSACTIONAL AUDIT DETAILS",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey, letterSpacing: 0.3)),
                    ],
                  ),
                ),
                if (txns.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
                    child: const Center(child: Text("Zero running balance parameters logged for this period.", style: TextStyle(fontSize: 11, color: Colors.grey))),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, idx) => _buildTransactionRow(txns[idx]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSummaryCard(summary) {
    bool isDR = summary['type'].toString().contains('DR');
    Color typeColor = isDR ? const Color(0xFF1E3A8A) : const Color(0xFF047857); // Deep Blue vs Deep Emerald

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sumItem("TOTAL DEBIT (DR)", "₹${summary['total_dr']}", const Color(0xFF1E40AF)),
              _sumItem("TOTAL CREDIT (CR)", "₹${summary['total_cr']}", const Color(0xFF065F46)),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CLOSING NET ACCOUNT BALANCE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF475569), letterSpacing: 0.2)),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("₹${summary['closing_balance']}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
                    child: Text(summary['type'],
                        style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.3)),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTransactionRow(t) {
    String vType = t['v_type'].toString().toUpperCase();
    String source = t['source'] ?? 'GENERAL';
    bool isDebit = (vType == 'PAYMENT' || vType == 'DEBIT');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: (isDebit ? const Color(0xFF1E40AF) : const Color(0xFF065F46)).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3)
            ),
            child: Text(isDebit ? "DR" : "CR",
                style: TextStyle(color: isDebit ? const Color(0xFF1E40AF) : const Color(0xFF065F46), fontSize: 8, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['narration'] ?? 'OPERATIONAL DEBIT ENTRY',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text("${t['date']}  |  DOC NO: ${t['v_no']}  |  MODULE: $source".toUpperCase(),
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("₹${t['amount']}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0F172A))),
              const SizedBox(height: 1),
              Text(isDebit ? "DEBIT" : "CREDIT",
                  style: TextStyle(fontSize: 7, color: Colors.grey.shade400, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String val, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
      const SizedBox(height: 2),
      Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
    ],
  );

  Widget _buildInitialState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.analytics_outlined, size: 24, color: Colors.grey),
        SizedBox(height: 6),
        Text("SELECT A VALID LEDGER ACCOUNT TO LOAD AUDIT MATRIX", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
      ],
    ),
  );
}