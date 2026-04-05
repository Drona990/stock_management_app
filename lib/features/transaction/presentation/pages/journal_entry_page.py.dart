/*
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/ledger_entry_screen.dart';

// ==========================================================================
// 1. DATA LAYER (Repository)
// ==========================================================================
class JournalRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<void> saveJournal(Map<String, dynamic> data) async {
    await apiClient.post('/api/transactions/journal/', data: data);
  }
}

// ==========================================================================
// 2. BLOC LAYER
// ==========================================================================
abstract class JournalEvent {}
class SaveJournalEvent extends JournalEvent { final Map<String, dynamic> data; SaveJournalEvent(this.data); }

abstract class JournalState {}
class JournalInitial extends JournalState {}
class JournalLoading extends JournalState {}
class JournalSuccess extends JournalState { final String message; JournalSuccess(this.message); }
class JournalError extends JournalState { final String error; JournalError(this.error); }

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalRepository repo;
  JournalBloc(this.repo) : super(JournalInitial()) {
    on<SaveJournalEvent>((event, emit) async {
      emit(JournalLoading());
      try {
        await repo.saveJournal(event.data);
        emit(JournalSuccess("Journal Voucher Saved Successfully!"));
      } catch (e) {
        emit(JournalError(e.toString()));
      }
    });
  }
}

// ==========================================================================
// 3. UI LAYER (Presentation - Single Line Entry)
// ==========================================================================
class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final _narration = TextEditingController();
  final DateTime _fixedDate = DateTime.now();

  // ✅ Each row represents one complete DR/CR transaction
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
    context.read<LedgerMasterBloc>().add(LoadData());
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
    setState(() {
      _narration.clear();
      rows = [{
        "dr_ledger": null,
        "cr_ledger": null,
        "amount_ctrl": TextEditingController(text: ""),
      }];
    });
  }

  void _onSave() {
    List<Map<String, dynamic>> items = [];
    for (var row in rows) {
      double amt = double.tryParse(row['amount_ctrl'].text) ?? 0;
      if (amt <= 0 || row['dr_ledger'] == null || row['cr_ledger'] == null) continue;

      items.add({"ledger": row['dr_ledger']['id'], "amount": amt, "type": "DEBIT"});
      items.add({"ledger": row['cr_ledger']['id'], "amount": amt, "type": "CREDIT"});
    }

    if (items.isEmpty) {
      _snack("Please complete at least one entry with amount!", Colors.red);
      return;
    }

    context.read<JournalBloc>().add(SaveJournalEvent({
      "date": DateFormat('yyyy-MM-dd').format(_fixedDate),
      "narration": _narration.text,
      "items": items,
    }));
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalLoading) {
          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        } else if (state is JournalSuccess) {
          Navigator.pop(context);
          _snack(state.message, Colors.green);
          _resetForm();
        } else if (state is JournalError) {
          Navigator.pop(context);
          _snack(state.error, Colors.red);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("JOURNAL VOUCHER", style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("DATE", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(DateFormat('dd-MMM-yyyy').format(_fixedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(width: 20),
            Expanded(child: TextField(
              controller: _narration,
              decoration: const InputDecoration(labelText: "NARRATION / REMARKS", border: OutlineInputBorder(), isDense: true),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleLineRow(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Entry Heading Badge
        Container(
          margin: const EdgeInsets.only(left: 5, bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(4)),
          child: Text("ENTRY #${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 25), // ✅ Gap between cards
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300, width: 1), // ✅ Fixed BorderSide Error
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                _rowLedger(index, "DR", "Debit (To) / Receiver", const Color(0xFF1A237E), true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.arrow_downward, size: 16, color: Colors.grey)),
                _rowLedger(index, "CR", "Credit (By) / Giver", Colors.orange, false),
                const Divider(height: 30),
                Row(
                  children: [
                    const Text("AMOUNT: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(
                      controller: rows[index]['amount_ctrl'],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(hintText: "0.00", prefixText: "₹ ", border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) => setState(() {}),
                    )),
                    const SizedBox(width: 10),
                    IconButton(onPressed: () => _removeRow(index), icon: const Icon(Icons.delete_sweep, color: Colors.red)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowLedger(int index, String label, String hint, Color color, bool isDebit) {
    return Row(
      children: [
        CircleAvatar(radius: 12, backgroundColor: color, child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.white))),
        const SizedBox(width: 10),
        Expanded(
          child: BlocBuilder<LedgerMasterBloc, LedgerState>(builder: (context, state) {
            List ledgers = state is LLoaded ? state.data : [];
            return DropdownSearch<dynamic>(
              items: (f, l) => ledgers,
              itemAsString: (item) => item['name'].toString(),
              compareFn: (i, s) => i['id'] == s['id'],
              onChanged: (v) => setState(() => isDebit ? rows[index]['dr_ledger'] = v : rows[index]['cr_ledger'] = v),
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  filled: true,
                  fillColor: isDebit ? Colors.blue.shade50 : Colors.orange.shade50,
                ),
              ),
              popupProps: const PopupProps.menu(showSearchBox: true),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    double total = 0;
    for (var r in rows) {
      total += double.tryParse(r['amount_ctrl'].text) ?? 0;
    }

    // LayoutBuilder se hum screen ki width check kar sakte hain
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: isMobile
              ? Column( // ✅ Mobile ke liye upar-niche (Vertical)
            mainAxisSize: MainAxisSize.min,
            children: [
              _totalSection(total),
              const Divider(height: 20),
              _buttonSection(isFullWidth: true),
            ],
          )
              : Row( // ✅ Desktop/Tablet ke liye side-by-side (Horizontal)
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _totalSection(total),
              _buttonSection(isFullWidth: false),
            ],
          ),
        );
      },
    );
  }

// 1. Total Amount Section
  Widget _totalSection(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("NET TRANSACTION TOTAL", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(
          "₹ ${total.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      ],
    );
  }

// 2. Buttons Section
  Widget _buttonSection({required bool isFullWidth}) {
    return Wrap( // ✅ Wrap use karne se overflow nahi hota
      spacing: 10, // Buttons ke beech gap
      runSpacing: 10, // Agar niche shift ho toh gap
      alignment: WrapAlignment.end,
      children: [
        SizedBox(
          width: isFullWidth ? double.infinity : null,
          child: OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text("ADD ANOTHER ENTRY"),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20)),
          ),
        ),
        SizedBox(
          width: isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _onSave,
            child: const Text("SAVE VOUCHER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

}*/

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
// 3. UI LAYER (Presentation)
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
    // Load ledgers for the dropdown
    context.read<LedgerMasterBloc>().add(LoadData());
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
      SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalLoading) {
          dev.log("⏳ UI: Showing Loader Dialog");
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => const Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        } else if (state is JournalSuccess) {
          dev.log("✅ UI: Success State Received");
          Navigator.of(context, rootNavigator: true).pop(); // Safe Pop for Dialog
          _snack(state.message, Colors.green);
          _resetForm();
        } else if (state is JournalError) {
          dev.log("⚠️ UI: Error State Received: ${state.error}");
          Navigator.of(context, rootNavigator: true).pop(); // Safe Pop for Dialog
          _snack(state.error, Colors.red);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("NEW JOURNAL VOUCHER", style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("DATE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(DateFormat('dd-MMM-yyyy').format(_fixedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(width: 20),
            Expanded(child: TextField(
              controller: _narration,
              decoration: const InputDecoration(labelText: "VOUCHER NARRATION", border: OutlineInputBorder(), isDense: true),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleLineRow(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 5, bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(4)),
          child: Text("ENTRY #${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 25),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                _ledgerDropdown(index, true), // DEBIT Side
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.arrow_downward, size: 16, color: Colors.grey)),
                _ledgerDropdown(index, false), // CREDIT Side
                const Divider(height: 30),
                Row(
                  children: [
                    const Text("AMOUNT: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(
                      controller: rows[index]['amount_ctrl'],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(hintText: "0.00", prefixText: "₹ ", border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) => setState(() {}),
                    )),
                    const SizedBox(width: 10),
                    IconButton(onPressed: () => _removeRow(index), icon: const Icon(Icons.delete_sweep, color: Colors.red)),
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
          CircleAvatar(radius: 12, backgroundColor: isDebit ? const Color(0xFF1A237E) : Colors.orange,
              child: Text(isDebit ? "DR" : "CR", style: const TextStyle(fontSize: 9, color: Colors.white))),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownSearch<dynamic>(
              items: (f, l) => ledgers,
              itemAsString: (item) => item['name'].toString(),
              // ✅ CRITICAL FIX: compareFn added to prevent crash
              compareFn: (i, s) => i['id'] == s['id'],
              onChanged: (v) => setState(() => isDebit ? rows[index]['dr_ledger'] = v : rows[index]['cr_ledger'] = v),
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  hintText: isDebit ? "Debit (To) / Receiver" : "Credit (By) / Giver",
                  filled: true,
                  fillColor: isDebit ? Colors.blue.shade50 : Colors.orange.shade50,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              popupProps: const PopupProps.menu(showSearchBox: true),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: isMobile
              ? Column(mainAxisSize: MainAxisSize.min, children: [ _totalSection(total), const Divider(), _buttonSection(true) ])
              : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ _totalSection(total), _buttonSection(false) ]),
        );
      },
    );
  }

  Widget _totalSection(double total) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("TOTAL VOUCHER AMOUNT", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
    Text("₹ ${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  ]);

  Widget _buttonSection(bool fullWidth) => Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
    SizedBox(width: fullWidth ? double.infinity : null,
        child: OutlinedButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text("ADD LINE ENTRY"))),
    SizedBox(width: fullWidth ? double.infinity : null,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: _onSave,
            child: const Text("SAVE JOURNAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
  ]);
}