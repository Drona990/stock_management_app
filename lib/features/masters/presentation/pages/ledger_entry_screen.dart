import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// REPOSITORY
class LedgerMasterRepository {
  final ApiClient apiClient = sl<ApiClient>();
  Future<List<dynamic>> fetchLedgers({String? search}) async {
    final res = await apiClient.get('/api/master/ledger/', query: {if (search != null) 'search': search});
    print("ledger master data $res");
    return res.data;
  }
  Future<void> saveLedger(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await apiClient.put('/api/master/ledger/$id/', data: data);
    } else {
      await apiClient.post('/api/master/ledger/', data: data);
    }
  }
}

// BLOC
abstract class LedgerEvent {}
class LoadData extends LedgerEvent { final String? s; LoadData({this.s}); }
class SaveData extends LedgerEvent { final Map<String, dynamic> d; final int? id; SaveData(this.d, {this.id}); }

abstract class LedgerState {}
class LInitial extends LedgerState {}
class LLoading extends LedgerState {}
class LLoaded extends LedgerState { final List data; LLoaded(this.data); }
class LError extends LedgerState { final String msg; LError(this.msg); }

class LedgerMasterBloc extends Bloc<LedgerEvent, LedgerState> {
  final LedgerMasterRepository repo;
  LedgerMasterBloc(this.repo) : super(LInitial()) {
    on<LoadData>((e, emit) async {
      emit(LLoading());
      try { emit(LLoaded(await repo.fetchLedgers(search: e.s))); } catch (err) { emit(LError(err.toString())); }
    });
    on<SaveData>((e, emit) async {
      try { await repo.saveLedger(e.d, id: e.id); add(LoadData()); } catch (err) { emit(LError(err.toString())); }
    });
  }
}

// UI PAGE
class LedgerMasterPage extends StatefulWidget {
  const LedgerMasterPage({super.key});
  @override
  State<LedgerMasterPage> createState() => _LedgerMasterPageState();
}


class _LedgerMasterPageState extends State<LedgerMasterPage> {
  final _name = TextEditingController();
  final _cr = TextEditingController(text: "0.00");
  final _dr = TextEditingController(text: "0.00");
  final _search = TextEditingController();

  int? _id;
  String? _grp, _hd, _gw;
  final List<String> _opts = ["SALES", "PURCHASE", "SUNDRY DEBTOR"];
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    context.read<LedgerMasterBloc>().add(LoadData());
  }

  // --- Logic Functions ---

  void _fill(Map<String, dynamic> d) {
    setState(() {
      _id = d['id'];
      _name.text = d['name'] ?? '';
      _cr.text = d['opening_balance_credit']?.toString() ?? "0.00";
      _dr.text = d['opening_balance_debit']?.toString() ?? "0.00";
      _grp = d['group'];
      _hd = d['head'];
      _gw = d['group_wise'];
    });
  }

  void _resetForm() {
    setState(() {
      _id = null;
      _name.clear();
      _cr.text = "0.00";
      _dr.text = "0.00";
      _grp = null;
      _hd = null;
      _gw = null;
    });
  }

  bool _isValid() {
    if (_name.text.trim().isEmpty) {
      _snack("Enter Ledger Name", Colors.red);
      return false;
    }
    if (_grp == null || _hd == null || _gw == null) {
      _snack("Select all categories", Colors.red);
      return false;
    }
    return true;
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        elevation: 0,
        title: const Text("LEDGER MASTER",
            style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;
        return isMobile
            ? ListView(
            children: [_buildFormCard(double.infinity), _buildTableCard(500)])
            : Row(children: [
          _buildFormCard(330),
          Expanded(child: _buildTableCard(null))
        ]);
      }),
    );
  }

  // --- UI Components ---

  Widget _buildFormCard(double w) => Container(
    width: w,
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_id != null ? "EDIT ACCOUNT" : "NEW ENTRY",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(color: Colors.cyan),
          _tf(_name, "NAME", readOnly: _id != null),
          Row(children: [
            Expanded(
                child: _tf(_cr, "CR AMT",
                    isNum: true,
                    onCh: (v) => setState(() => _dr.text = "0.00"))),
            const SizedBox(width: 8),
            Expanded(
                child: _tf(_dr, "DR AMT",
                    isNum: true,
                    onCh: (v) => setState(() => _cr.text = "0.00"))),
          ]),
          _dd("GROUP", _grp, (v) => setState(() => _grp = v)),
          _dd("HEAD", _hd, (v) => setState(() => _hd = v)),
          _dd("GROUP WISE", _gw, (v) => setState(() => _gw = v)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800]),
                    onPressed: _resetForm,
                    child: const Text("RESET",
                        style: TextStyle(color: Colors.white)))),
            const SizedBox(width: 8),
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[700]),
                    onPressed: () {
                      if (_isValid()) {
                        context.read<LedgerMasterBloc>().add(SaveData({
                          "name": _name.text,
                          "opening_balance_credit": _cr.text,
                          "opening_balance_debit": _dr.text,
                          "group": _grp,
                          "head": _hd,
                          "group_wise": _gw
                        }, id: _id));
                        _resetForm();
                      }
                    },
                    child: Text(_id != null ? "UPDATE" : "SAVE",
                        style: const TextStyle(color: Colors.white)))),
          ])
        ]),
  );

  Widget _buildTableCard(double? h) => Container(
    height: h,
    margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ]),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
              child: SizedBox(
                  height: 40,
                  child: TextField(
                      controller: _search,
                      onChanged: (v) =>
                          context.read<LedgerMasterBloc>().add(LoadData(s: v)),
                      decoration: InputDecoration(
                          hintText: "Search Ledger Accounts...",
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon:
                          const Icon(Icons.search, size: 18, color: Colors.cyan),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4)),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12))))),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF263238),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            icon: const Icon(Icons.date_range, color: Colors.cyanAccent, size: 18),
            label: const Text("PRINT RANGE",
                style: TextStyle(color: Colors.white, fontSize: 11)),
            onPressed: _showPicker,
          ),
        ]),
      ),
      Expanded(
        child: BlocBuilder<LedgerMasterBloc, LedgerState>(
            builder: (context, state) {
              if (state is LLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyan));
              }
              if (state is LLoaded) {
                return LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 16,
                        headingRowHeight: 45,
                        dataRowHeight: 50,
                        headingRowColor:
                        MaterialStateProperty.all(const Color(0xFF263238)),
                        columns: [
                          _profColumn("NAME", flex: 3),
                          _profColumn("GROUP", flex: 2),
                          _profColumn("CR (₹)", flex: 1.5),
                          _profColumn("DR (₹)", flex: 1.5),
                          _profColumn("TIME", flex: 1.2),
                          _profColumn("ACT", flex: 1.2),
                        ],
                        rows: state.data.map((e) {
                          String time = e['updated_at'] != null
                              ? DateFormat('HH:mm')
                              .format(DateTime.parse(e['updated_at']).toLocal())
                              : '--';

                          return DataRow(cells: [
                            DataCell(_cellText(e['name'], bold: true, flex: 3, constraints: constraints)),
                            DataCell(_cellText(e['group'] ?? '', flex: 2, constraints: constraints)),
                            DataCell(_cellText(e['opening_balance_credit'].toString(), color: Colors.green, flex: 1.5, constraints: constraints)),
                            DataCell(_cellText(e['opening_balance_debit'].toString(), color: Colors.red, flex: 1.5, constraints: constraints)),
                            DataCell(_cellText(time, flex: 1.2, constraints: constraints)),
                            DataCell(SizedBox(
                              width: (constraints.maxWidth * (1.2 / 10.4)),
                              child: Row(
                                children: [
                                  // ✅ Edit Icon Logic: Hide if SALES or PURCHASE
                                  if (e['group'] != "SALES" && e['group'] != "PURCHASE")
                                    InkWell(
                                      onTap: () => _fill(e),
                                      child: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                    )
                                  else
                                    const SizedBox(width: 18), // Space maintain karne ke liye jab icon hide ho

                                  const SizedBox(width: 12),

                                  InkWell(
                                    onTap: () => _printPdf(context, d: e),
                                    child: const Icon(Icons.print, color: Colors.orange, size: 18),
                                  ),
                                ],
                              ),
                            )),
                          ]);                        }).toList(),
                      ),
                    ),
                  );
                });
              }
              return const SizedBox();
            }),
      ),
    ]),
  );

  // --- Helper Functions ---

  DataColumn _profColumn(String label, {required double flex}) {
    return DataColumn(
        label: Expanded(
            flex: (flex * 10).toInt(),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold))));
  }

  Widget _cellText(String text,
      {bool bold = false,
        Color? color,
        required double flex,
        required BoxConstraints constraints}) {
    return SizedBox(
      width: (constraints.maxWidth * (flex / 10.4)),
      child: Text(text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? const Color(0xFF424242))),
    );
  }

  Widget _tf(TextEditingController c, String l,
      {bool readOnly = false, bool isNum = false, Function(String)? onCh}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
            controller: c,
            readOnly: readOnly,
            onChanged: onCh,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
                labelText: l,
                labelStyle: const TextStyle(fontSize: 11),
                border: const OutlineInputBorder(),
                filled: readOnly,
                fillColor: readOnly ? Colors.grey[200] : Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.all(10))),
      );

  Widget _dd(String l, String? v, Function(String?) onCh) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
        value: v,
        decoration: InputDecoration(
            labelText: l,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.all(10)),
        items: _opts
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 11))))
            .toList(),
        onChanged: onCh),
  );

  void _showPicker() async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
        builder: (context, child) => Center(
            child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                child: child)));
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _printPdf(context, isAll: true);
    }
  }

  Future<void> _printPdf(BuildContext context,
      {bool isAll = false, Map<String, dynamic>? d}) async {
    final pdf = pw.Document();
    final List<dynamic> allData =
        (context.read<LedgerMasterBloc>().state as LLoaded).data;
    List<dynamic> filtered = isAll ? allData : [d!];

    if (isAll && _selectedDateRange != null) {
      filtered = allData.where((e) {
        DateTime dt = DateTime.parse(e['updated_at']).toLocal();
        return dt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            dt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("LEDGER REPORT")),
          pw.Table.fromTextArray(
              headers: ["NAME", "GROUP", "CR", "DR", "TIME"],
              data: filtered.map((e) => [
                e['name'],
                e['group'],
                e['opening_balance_credit'],
                e['opening_balance_debit'],
                DateFormat('dd/MM HH:mm')
                    .format(DateTime.parse(e['updated_at']).toLocal())
              ]).toList()),
        ]));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}