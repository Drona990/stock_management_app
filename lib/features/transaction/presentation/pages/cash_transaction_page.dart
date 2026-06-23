
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

// =============================================================================
// 1. REPOSITORY LAYER (Crash-Proof Paginated Extraction)
// =============================================================================
class CashTransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<dynamic>> fetchTransactions({String? search}) async {
    try {
      final res = await apiClient.get('/api/transactions/cash-transactions/', query: {if (search != null) 'search': search});
      print("cash transaction response $res");

      if (res.data is Map && res.data['results'] != null) {
        return res.data['results'] as List<dynamic>;
      }
      if (res.data is List) {
        return res.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error fetching cash transactions: $e");
      return [];
    }
  }

  Future<void> saveTransaction(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await apiClient.put('/api/transactions/cash-transactions/$id/', data: data);
    } else {
      await apiClient.post('/api/transactions/cash-transactions/', data: data);
    }
  }
}

class LocalLedgerExtractor {
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

// =============================================================================
// 2. BLOC LAYER: LOGIC PIPELINE
// =============================================================================
abstract class CashTransactionEvent {}
class LoadTransactions extends CashTransactionEvent { final String? s; LoadTransactions({this.s}); }
class SaveTransactionEvent extends CashTransactionEvent {
  final Map<String, dynamic> d; final int? id; SaveTransactionEvent(this.d, {this.id});
}

abstract class CashTransactionState {}
class CTInitial extends CashTransactionState {}
class CTLoading extends CashTransactionState {}
class CTLoaded extends CashTransactionState { final List data; CTLoaded(this.data); }
class CTError extends CashTransactionState { final String msg; CTError(this.msg); }

class CashTransactionBloc extends Bloc<CashTransactionEvent, CashTransactionState> {
  final CashTransactionRepository repo;
  CashTransactionBloc(this.repo) : super(CTInitial()) {
    on<LoadTransactions>((e, emit) async {
      emit(CTLoading());
      try {
        final data = await repo.fetchTransactions(search: e.s);
        emit(CTLoaded(data));
      } catch (err) {
        emit(CTError(err.toString()));
      }
    });
    on<SaveTransactionEvent>((e, emit) async {
      try {
        await repo.saveTransaction(e.d, id: e.id);
        final data = await repo.fetchTransactions();
        emit(CTLoaded(data));
      } catch (err) {
        emit(CTError(err.toString()));
      }
    });
  }
}

// =============================================================================
// 3. UI SCREEN LAYER (High Density Constraints Locked Canvas)
// =============================================================================
class CashTransactionPage extends StatefulWidget {
  const CashTransactionPage({super.key});

  @override
  State<CashTransactionPage> createState() => _CashTransactionPageState();
}

class _TransactionTerminalScreenState {} // Retaining compilation hooks references

class _CashTransactionPageState extends State<CashTransactionPage> {
  final _amount = TextEditingController();
  final _narration = TextEditingController();

  final DateTime _fixedDate = DateTime.now();
  String? _transactionType;
  int? _selectedLedgerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CashTransactionBloc>().add(LoadTransactions());
        context.read<LedgerMasterBloc>().add(LoadData());
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _narration.dispose();
    super.dispose();
  }

  void _resetForm() {
    if (!mounted) return;
    setState(() {
      _amount.clear();
      _narration.clear();
      _selectedLedgerId = null;
      _transactionType = null;
    });
  }

  void _onSave() {
    if (_transactionType == null) {
      _snack("Please select a voucher type first", Colors.orange);
      return;
    }
    if (_selectedLedgerId == null) {
      _snack("Please select a Ledger", Colors.red);
      return;
    }

    double? parsedAmount = double.tryParse(_amount.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      _snack("Please enter a valid number amount", Colors.red);
      return;
    }

    context.read<CashTransactionBloc>().add(SaveTransactionEvent({
      "date": DateFormat('yyyy-MM-dd').format(_fixedDate),
      "ledger": _selectedLedgerId,
      "amount": _amount.text,
      "voucher_type": _transactionType,
      "narration": _narration.text,
    }));

    _snack("$_transactionType Saved Successfully!", Colors.green);
    _resetForm();
  }

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(m, style: const TextStyle(fontSize: 11)),
            backgroundColor: c,
            duration: const Duration(seconds: 2)
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 950;
    const Color industrialSlate = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Deeper industrial light-grey surface
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 52,
        iconTheme: const IconThemeData(color: industrialSlate, size: 18),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("CASH RECEIPT / CASH PAYMENT REGISTER",
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: industrialSlate, letterSpacing: 0.3)),
            Text("FINANCIAL CASH REGISTER MANAGEMENT TRANSACTION CORE Pipeline",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold))
          ],
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      // 🌟 FIXED LAYOUT: Top-aligned and wrapped in a SingleChildScrollView with dynamic viewport constraints
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 12),
                _buildEntryForm(),
                const SizedBox(height: 16),
                _buildPassbookPanel(isMobile: true),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Left Form Block Area (Width lock ensures zero movement on dropdown popups)
                SizedBox(
                  width: 440,
                  child: Column(
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 12),
                      _buildEntryForm(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Fluid Right Passbook Panel
                Expanded(
                  child: _buildPassbookPanel(isMobile: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. SEARCHABLE DROPDOWN WITH LIFECYCLE TRACKING LOGS ---
  Widget _buildLedgerDropdown() {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4)),
      child: BlocBuilder<LedgerMasterBloc, LedgerState>(
        builder: (context, ledgerState) {
          print("[Dropdown Log] 🔄 LedgerMasterBloc Current State: $ledgerState");

          List ledgersList = [];
          if (ledgerState is LLoaded) {
            ledgersList = LocalLedgerExtractor.extract(ledgerState.data);
            print("[Dropdown Log] ✅ Data Found! Total Raw Items: ${ledgerState.data.length} | Extracted List Size: ${ledgersList.length}");
          }

          return DropdownSearch<dynamic>(
            items: (filter, loadProps) {
              print("[Dropdown Log] 📤 Dropdown requested items. Current list size being injected: ${ledgersList.length}");
              return ledgersList;
            },
            compareFn: (i, s) {
              return i != null && s != null && i['id'] == s['id'];
            },
            itemAsString: (item) {
              if (item == null) return "";
              return item['name'].toString();
            },
            onChanged: (v) {
              print("[Dropdown Log] 🎯 User Selected Item: $v");
              if (mounted && v != null) {
                setState(() {
                  _selectedLedgerId = v['id'];
                });
              }
            },
            filterFn: (item, filter) {
              if (item == null) return false;
              final name = item['name'].toString().toLowerCase();
              final group = item['group'].toString().toLowerCase();
              final query = filter.toLowerCase();
              return name.contains(query) || group.contains(query);
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(
                  style: TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                      hintText: "Search Customer/Supplier...",
                      hintStyle: TextStyle(fontSize: 11),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero)
                  )
              ),
              itemBuilder: (context, item, isSelected, isHovered) {
                if (item == null) return const SizedBox();
                bool isCust = item['group'].toString().toUpperCase().contains('DEBTOR');
                return ListTile(
                  dense: true,
                  title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: isCust ? Colors.blue.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(2)),
                    child: Text(isCust ? "CUST" : "SUPP", style: TextStyle(fontSize: 8, color: isCust ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                  ),
                );
              },
            ),
            decoratorProps: const DropDownDecoratorProps(
                baseStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    isDense: true,
                    fillColor: Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                )
            ),
          );
        },
      ),
    );
  }

  // --- 2. ENTRY FORM (Size Locked Container to stop resizing artifacts) ---
  Widget _buildEntryForm() {
    // 🌟 STABLE HEIGHT LOCK: Form height remains constant even before a type selection
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      constraints: const BoxConstraints(minHeight: 342),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey.shade200),
          // Subtle visual color accents indicating currently chosen workflow
          boxShadow: [
            if (_transactionType != null)
              BoxShadow(
                color: _transactionType == "RECEIPT" ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ]
      ),
      child: _transactionType == null
          ? _placeholder()
          : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("NEW $_transactionType RECORD".toUpperCase(),
                      style: TextStyle(fontSize: 11, color: _transactionType == "RECEIPT" ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                  IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _transactionType = null),
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey)
                  ),
                ]
            ),
            const Divider(height: 16),
            _label("VOUCHER REGISTRATION DATE"),
            _buildReadOnlyDate(),
            _label("TARGET ALLOCATED LEDGER NAME *"),
            _buildLedgerDropdown(),
            _tf(_amount, "TRANSACTION VOUCHER AMOUNT *", isNum: true),
            _tf(_narration, "VOUCHER REMARKS / NARRATION", maxLines: 2),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _transactionType == "RECEIPT" ? Colors.green[700] : Colors.red[700],
                    elevation: 0,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
                ),
                onPressed: _onSave,
                child: const Text("SAVE ENTRY UNTO CASHBOOKS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.3)),
              ),
            )
          ]
      ),
    );
  }

  Widget _buildReadOnlyDate() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.zero),
      child: Row(children: [
        const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(DateFormat('dd MMM yyyy').format(_fixedDate).toUpperCase(), style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.bold, letterSpacing: 0.2)),
      ]),
    );
  }

  // --- 3. PASSBOOK PANEL ---
  Widget _buildPassbookPanel({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
            child: const Row(children: [Icon(Icons.history_toggle_off_rounded, color: Color(0xFF0F4C81), size: 14), SizedBox(width: 8), Text("CASH PASSBOOK (CR/DR) ACCOUNT TRANSACTION DIRECTORY LOGS", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.3))]),
          ),
          const Divider(height: 1),
          Container(
            constraints: BoxConstraints(maxHeight: isMobile ? 400 : 540), // Infinite height layout overflow protection
            child: BlocBuilder<CashTransactionBloc, CashTransactionState>(
              builder: (context, state) {
                if (state is CTLoaded) {
                  if (state.data.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("Zero operational cash parameters logged.", style: TextStyle(fontSize: 11, color: Colors.grey))));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    itemCount: state.data.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) {
                      var e = state.data[i];
                      bool isCR = e['voucher_type'] == "RECEIPT";
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 24, height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: isCR ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(2)
                          ),
                          child: Text(isCR ? "CR" : "DR", style: TextStyle(color: isCR ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(e['ledger_name'] ?? e['ledger'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E293B))),
                        subtitle: Text("${e['date']} | ${e['narration'] ?? ''}", style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text("₹${e['amount']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: isCR ? Colors.green : Colors.red)),
                      );
                    },
                  );
                }
                if (state is CTError) {
                  return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${state.msg}", style: const TextStyle(fontSize: 11, color: Colors.red))));
                }
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF0F4C81), strokeWidth: 1.5)));
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildTypeSelector() {
    return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [_typeBtn("RECEIPT", Colors.green[700]!), const SizedBox(width: 6), _typeBtn("PAYMENT", Colors.red[700]!)])
    );
  }

  Widget _typeBtn(String t, Color c) {
    bool sel = _transactionType == t;
    return Expanded(
        child: InkWell(
            onTap: () {
              if (mounted) {
                setState(() => _transactionType = t);
              }
            },
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: sel ? c : Colors.white, borderRadius: BorderRadius.zero),
                child: Center(child: Text(t, style: TextStyle(color: sel ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)))
            )
        )
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 4), child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.2)));

  Widget _tf(TextEditingController c, String l, {bool isNum = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(10),
            hintText: "Enter $l...",
            hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return const SizedBox(
      height: 310, // Explicit height allocation prevents structural shifting artifacts
      width: double.infinity,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_task_rounded, color: Colors.blueGrey, size: 22),
            SizedBox(height: 8),
            Text("Select Receipt or Payment Voucher Type", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2))
          ]
      ),
    );
  }
}