import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

// =============================================================================
// 1. REPOSITORY
// =============================================================================
class CashTransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<dynamic>> fetchTransactions({String? search}) async {
    final res = await apiClient.get('/api/transactions/cash-transactions/', query: {if (search != null) 'search': search});
    print("response $res");
    return res.data;
  }

  Future<void> saveTransaction(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await apiClient.put('/api/transactions/cash-transactions/$id/', data: data);
    } else {
      await apiClient.post('/api/transactions/cash-transactions/', data: data);
    }
  }
}

// =============================================================================
// 2. BLOC (Events & States)
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
      try { emit(CTLoaded(await repo.fetchTransactions(search: e.s))); } catch (err) { emit(CTError(err.toString())); }
    });
    on<SaveTransactionEvent>((e, emit) async {
      try { await repo.saveTransaction(e.d, id: e.id); add(LoadTransactions()); } catch (err) { emit(CTError(err.toString())); }
    });
  }
}


// =============================================================================
// 3. UI SCREEN
// =============================================================================


class CashTransactionPage extends StatefulWidget {
  const CashTransactionPage({super.key});

  @override
  State<CashTransactionPage> createState() => _CashTransactionPageState();
}

class _CashTransactionPageState extends State<CashTransactionPage> {
  // Controllers
  final _amount = TextEditingController();
  final _narration = TextEditingController();

  // State
  final DateTime _fixedDate = DateTime.now(); // Locked Date
  String? _transactionType;
  int? _selectedLedgerId;

  @override
  void initState() {
    super.initState();
    context.read<LedgerMasterBloc>().add(LoadData());
    context.read<CashTransactionBloc>().add(LoadTransactions());
  }

  void _resetForm() {
    setState(() {
      _amount.clear();
      _narration.clear();
      _selectedLedgerId = null;
      _transactionType = null;
    });
  }

  void _onSave() {
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
    context.read<CashTransactionBloc>().add(LoadTransactions());
  }
  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: c, duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("CASH RECEIPT / CASH PAYMENT", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1300),
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? ListView(
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 15),
              _buildEntryForm(),
              const SizedBox(height: 25),
              _buildPassbookPanel(isMobile: true),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: SingleChildScrollView(child: Column(children: [_buildTypeSelector(), const SizedBox(height: 15), _buildEntryForm()]))),
              const SizedBox(width: 20),
              Expanded(flex: 6, child: _buildPassbookPanel(isMobile: false)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. SEARCHABLE DROPDOWN (CUST/SUPP TAGS) ---
  Widget _buildLedgerDropdown() {
    return BlocBuilder<LedgerMasterBloc, LedgerState>(
      builder: (context, state) {
        List ledgers = state is LLoaded ? state.data : [];
        return DropdownSearch<dynamic>(
          items: (filter, loadProps) => ledgers,
          compareFn: (i, s) => i['id'] == s['id'],
          itemAsString: (item) => item['name'].toString(),
          onChanged: (v) => setState(() => _selectedLedgerId = v?['id']),
          filterFn: (item, filter) => item['name'].toString().toLowerCase().contains(filter.toLowerCase()) || item['group'].toString().toLowerCase().contains(filter.toLowerCase()),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: const TextFieldProps(decoration: InputDecoration(hintText: "Search Customer/Supplier...", border: OutlineInputBorder())),
            itemBuilder: (context, item, isSelected, isHovered) {
              bool isCust = item['group'].toString().toUpperCase().contains('DEBTOR');
              return ListTile(
                title: Text(item['name'], style: const TextStyle(fontSize: 13)),
                trailing: Text(isCust ? "CUST" : "SUPP", style: TextStyle(fontSize: 9, color: isCust ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
              );
            },
          ),
          decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8))),
        );
      },
    );
  }

  // --- 2. ENTRY FORM (LOCK DATE + NUMBER KEYBOARD) ---
  Widget _buildEntryForm() {
    if (_transactionType == null) return _placeholder();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("NEW $_transactionType ENTRY", style: TextStyle(color: _transactionType == "RECEIPT" ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => setState(() => _transactionType = null), icon: const Icon(Icons.close, size: 18)),
        ]),
        const Divider(),
        _label("VOUCHER DATE"),
        _buildReadOnlyDate(),
        _label("LEDGER NAME"),
        _buildLedgerDropdown(),
        _tf(_amount, "AMOUNT", isNum: true),
        _tf(_narration, "NARRATION", maxLines: 2),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _transactionType == "RECEIPT" ? Colors.green[700] : Colors.red[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: _onSave,
            child: const Text("SAVE TRANSACTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ]),
    );
  }

  Widget _buildReadOnlyDate() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Text(DateFormat('dd MMM yyyy').format(_fixedDate), style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // --- 3. PASSBOOK PANEL (CR/DR) ---
  Widget _buildPassbookPanel({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Color(0xFF263238), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: const Row(children: [Icon(Icons.history, color: Colors.cyanAccent, size: 18), SizedBox(width: 10), Text("CASH PASSBOOK (CR/DR)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
        ),
        Flexible(
          child: BlocBuilder<CashTransactionBloc, CashTransactionState>(builder: (context, state) {
            if (state is CTLoaded) {
              return ListView.separated(
                shrinkWrap: true,
                physics: isMobile ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: state.data.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  var e = state.data[i];
                  bool isCR = e['voucher_type'] == "RECEIPT";
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(backgroundColor: isCR ? Colors.green.shade50 : Colors.red.shade50, child: Text(isCR ? "CR" : "DR", style: TextStyle(color: isCR ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold))),
                    title: Text(e['ledger_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text("${e['date']} | ${e['narration'] ?? ''}", style: const TextStyle(fontSize: 10), maxLines: 1),
                    trailing: Text("₹${e['amount']}", style: TextStyle(fontWeight: FontWeight.bold, color: isCR ? Colors.green : Colors.red)),
                  );
                },
              );
            }
            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
          }),
        ),
      ]),
    );
  }

  // --- HELPERS ---
  Widget _buildTypeSelector() {
    return Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [_typeBtn("RECEIPT", Colors.green), const SizedBox(width: 8), _typeBtn("PAYMENT", Colors.red)]));
  }

  Widget _typeBtn(String t, Color c) {
    bool sel = _transactionType == t;
    return Expanded(child: InkWell(onTap: () => setState(() => _transactionType = t), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? c : Colors.white, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(t, style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13))))));
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 5), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)));


  Widget _tf(TextEditingController c, String l, {bool isNum = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l),
        TextField(
          controller: c,
          maxLines: maxLines,
          // ✅ Ye keyboard type numbers ke liye hai
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          // ✅ Ye input ko strictly filter karega (Text block ho jayega)
          inputFormatters: isNum ? [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ] : null,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            hintText: "Enter $l...",
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
  Widget _placeholder() => Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_task, color: Colors.grey), Text("Select Receipt or Payment", style: TextStyle(color: Colors.grey))]));
}