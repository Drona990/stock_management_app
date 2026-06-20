import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev; // For Logs
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

// ==========================================================================
// 1. DATA LAYER (Repository)
// ==========================================================================
class JournalRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<void> saveJournal(Map<String, dynamic> data) async {
    dev.log("➡️ API REQUEST: /api/transactions/journal/ | DATA: $data");
    final res = await apiClient.post('/api/transactions/journal/', data: data);
    dev.log("⬅️ API RESPONSE: ${res.data}");
  }
}

// ==========================================================================
// 2. BLOC LAYER (Fixed State Inheritance)
// ==========================================================================
abstract class JournalState {}
class JournalInitial extends JournalState {}
class JournalLoading extends JournalState {}
class JournalSuccess extends JournalState { final String message; JournalSuccess(this.message); }
class JournalError extends JournalState { final String error; JournalError(this.error); }

abstract class JournalEvent {}
class SaveJournalEvent extends JournalEvent { final Map<String, dynamic> data; SaveJournalEvent(this.data); }

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalRepository repo;
  JournalBloc(this.repo) : super(JournalInitial()) {
    on<SaveJournalEvent>((event, emit) async {
      dev.log("🚀 Bloc Event: SaveJournalEvent Triggered");
      emit(JournalLoading());
      try {
        await repo.saveJournal(event.data);
        emit(JournalSuccess("Journal Voucher Saved Successfully!"));
      } catch (e) {
        dev.log("❌ Bloc Error: ${e.toString()}");
        emit(JournalError(e.toString()));
      }
    });
  }
}

// ==========================================================================
// 3. UI LAYER (Presentation High Density Re-engineered Canvas)
// ==========================================================================
class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _narration = TextEditingController();
  final DateTime _fixedDate = DateTime.now();

  List<Map<String, dynamic>> rows = [
    {
      "dr_ledger": null,
      "cr_ledger": null,
      "amount_ctrl": TextEditingController(text: ""),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerMasterBloc>().add(LoadData());
    });
  }

  @override
  void dispose() {
    _narration.dispose();
    for (var row in rows) {
      (row['amount_ctrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      rows.add({
        "dr_ledger": null,
        "cr_ledger": null,
        "amount_ctrl": TextEditingController(text: ""),
      });
    });
  }

  void _removeRow(int index) {
    if (rows.length > 1) {
      setState(() => rows.removeAt(index));
    }
  }

  void _resetForm() {
    dev.log("🧹 Resetting Form...");
    _narration.clear();
    setState(() {
      rows = [{
        "dr_ledger": null,
        "cr_ledger": null,
        "amount_ctrl": TextEditingController(text: ""),
      }];
    });
  }

  void _onSave() {
    dev.log("📝 UI: Preparing Payload...");
    List<Map<String, dynamic>> items = [];
    for (var row in rows) {
      double amt = double.tryParse(row['amount_ctrl'].text) ?? 0;
      if (amt <= 0 || row['dr_ledger'] == null || row['cr_ledger'] == null) continue;

      items.add({"ledger": row['dr_ledger']['id'], "amount": amt, "type": "DEBIT"});
      items.add({"ledger": row['cr_ledger']['id'], "amount": amt, "type": "CREDIT"});
    }

    if (items.isEmpty) {
      _snack("Please fill both ledgers and amount correctly!", Colors.red);
      return;
    }

    context.read<JournalBloc>().add(SaveJournalEvent({
      "date": DateFormat('yyyy-MM-dd').format(_fixedDate),
      "narration": _narration.text,
      "items": items,
    }));
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m, style: const TextStyle(fontSize: 11)), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    const Color industrialSlate = Color(0xFF1E293B);

    return BlocListener<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalLoading) {
          dev.log("⏳ UI: Showing Loader Dialog");
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5)),
          );
        } else if (state is JournalSuccess) {
          dev.log("✅ UI: Success State Received");
          Navigator.of(context, rootNavigator: true).pop();
          _snack(state.message, Colors.green);
          _resetForm();
        } else if (state is JournalError) {
          dev.log("⚠️ UI: Error State Received: ${state.error}");
          Navigator.of(context, rootNavigator: true).pop();
          _snack(state.error, Colors.red);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          toolbarHeight: 50,
          iconTheme: const IconThemeData(color: industrialSlate, size: 18),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("NEW JOURNAL VOUCHER", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: industrialSlate, letterSpacing: 0.3)),
              Text("DOUBLE ENTRY FINANCIAL ADJUSTMENT INTERCEPTOR JOURNAL", style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold))
            ],
          ),
          shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _buildSingleLineRow(index),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("VOUCHER DATE", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Text(DateFormat('dd-MMM-yyyy').format(_fixedDate).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B))),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 36,
              child: TextField(
                controller: _narration,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                    labelText: "VOUCHER NARRATION EXPLANATION DESCRIPTION",
                    labelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLineRow(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2)),
          child: Text("ENTRY TRANSACTION DIRECTORY #${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _ledgerDropdown(index, true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.grey)),
                _ledgerDropdown(index, false),
                const Divider(height: 16),
                Row(
                  children: [
                    const Text("TRANSACTION VALUE AMOUNT:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: Colors.blueGrey)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 34,
                        child: TextField(
                          controller: rows[index]['amount_ctrl'],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(hintText: "0.00", prefixText: "₹ ", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeRow(index),
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ledgerDropdown(int index, bool isDebit) {
    return BlocBuilder<LedgerMasterBloc, LedgerState>(builder: (context, state) {
      List ledgers = state is LLoaded ? state.data : [];
      return Row(
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: isDebit ? const Color(0xFF0F4C81) : Colors.orange,
                borderRadius: BorderRadius.circular(2)
            ),
            child: Text(isDebit ? "DR" : "CR", style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 34,
              child: DropdownSearch<dynamic>(
                items: (f, l) => ledgers,
                itemAsString: (item) => item['name'].toString(),
                compareFn: (i, s) => i['id'] == s['id'],
                onChanged: (v) => setState(() => isDebit ? rows[index]['dr_ledger'] = v : rows[index]['cr_ledger'] = v),
                popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                        style: TextStyle(fontSize: 11),
                        decoration: InputDecoration(hintText: "Filter master accounts hierarchy...", hintStyle: TextStyle(fontSize: 11), border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8))
                    )
                ),
                decoratorProps: DropDownDecoratorProps(
                  baseStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                      hintText: isDebit ? "Debit (To) / Receiver Account Parameters" : "Credit (By) / Giver Account Parameters",
                      hintStyle: const TextStyle(fontSize: 11, color: Colors.black54),
                      filled: true,
                      fillColor: isDebit ? const Color(0xFFF0F6FC) : const Color(0xFFFFF8E1),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBottomBar() {
    double total = 0;
    for (var r in rows) { total += double.tryParse(r['amount_ctrl'].text) ?? 0; }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
          child: isMobile
              ? Column(mainAxisSize: MainAxisSize.min, children: [ _totalSection(total), const Divider(height: 12), _buttonSection(true) ])
              : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ _totalSection(total), _buttonSection(false) ]),
        );
      },
    );
  }

  Widget _totalSection(double total) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("TOTAL VOUCHER SUMMARY VALUE AMOUNT", style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
    const SizedBox(height: 2),
    Text("₹ ${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
  ]);

  Widget _buttonSection(bool fullWidth) => Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
    SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 36,
        child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
            ),
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text("ADD LINE ENTRY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))
        )
    ),
    SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 36,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 24)
            ),
            onPressed: _onSave,
            child: const Text("SAVE JOURNAL RECORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.3))
        )
    ),
  ]);
}