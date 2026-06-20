import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. REPOSITORY LAYER
// ==========================================================================
// ==========================================================================
// 1. REPOSITORY LAYER (Fixed Paginated Extraction Strategy)
// ==========================================================================
class LedgerMasterRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<dynamic>> fetchLedgers({String? search}) async {
    final res = await apiClient.get('/api/master/ledger/', query: {if (search != null) 'search': search});
    print("ledger master data $res");

    // ✅ FIX: Django DRF Pagination layer se 'results' key ko extract kiya
    if (res.data is Map && res.data['results'] != null) {
      return res.data['results'] as List<dynamic>;
    }

    // Fallback layer agar bina pagination ke direct list aaye
    if (res.data is List) {
      return res.data as List<dynamic>;
    }

    return [];
  }

  Future<void> saveLedger(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await apiClient.put('/api/master/ledger/$id/', data: data);
    } else {
      await apiClient.post('/api/master/ledger/', data: data);
    }
  }
}
// ==========================================================================
// 2. BLOC LAYER: LOGIC STRATIFICATION
// ==========================================================================
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

// ==========================================================================
// 3. MAIN SURFACE CONTAINER UI
// ==========================================================================
class LedgerMasterPage extends StatefulWidget {
  const LedgerMasterPage({super.key});
  @override
  State<LedgerMasterPage> createState() => _LedgerMasterPageState();
}

class _LedgerMasterPageState extends State<LedgerMasterPage> {
  // Hardcoded identical internal naming parameters controller setups
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
    // Safe initialization context triggers block
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerMasterBloc>().add(LoadData());
    });
  }

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
      .showSnackBar(SnackBar(content: Text(m, style: const TextStyle(fontSize: 12)), backgroundColor: c));

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
            const Text("LEDGER MASTER",
                style: TextStyle(color: industrialSlate, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            Text("FINANCIAL REPOSITORIES PARAMETERS REGISTRY",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold))
          ],
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;
        return isMobile
            ? ListView(
            padding: const EdgeInsets.all(8),
            children: [_buildFormCard(double.infinity), const SizedBox(height: 12), _buildTableCard(500, constraints)])
            : Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(280),
              const SizedBox(width: 12),
              Expanded(child: _buildTableCard(null, constraints))
            ],
          ),
        );
      }),
    );
  }

  // --- High Density Input Form Canvas ---
  Widget _buildFormCard(double w) => Container(
    width: w,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200)),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((_id != null ? "EDIT ACCOUNT" : "NEW ENTRY").toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0F172A), letterSpacing: 0.3)),
          const Divider(height: 16, color: Colors.cyan),
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
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                    onPressed: _resetForm,
                    child: const Text("RESET",
                        style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 8),
            Expanded(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                    onPressed: () {
                      if (_isValid()) {
                        context.read<LedgerMasterBloc>().add(SaveData({
                          "name": _name.text.trim(),
                          "opening_balance_credit": _cr.text,
                          "opening_balance_debit": _dr.text,
                          "group": _grp,
                          "head": _hd,
                          "group_wise": _gw
                        }, id: _id));
                        _resetForm();
                      }
                    },
                    child: Text((_id != null ? "UPDATE" : "SAVE").toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
          ])
        ]),
  );

  // --- High Density Table Matrix Canvas ---
  Widget _buildTableCard(double? h, BoxConstraints rootConstraints) => Container(
    height: h,
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200)),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: TextField(
                      controller: _search,
                      style: const TextStyle(fontSize: 11),
                      onChanged: (v) => context.read<LedgerMasterBloc>().add(LoadData(s: v.trim())),
                      decoration: const InputDecoration(
                          hintText: "Search Ledger Accounts Registry...",
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                          prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.blueGrey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 12))))),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            icon: const Icon(Icons.date_range_rounded, color: Colors.cyanAccent, size: 14),
            label: const Text("PRINT RANGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            onPressed: _showPicker,
          ),
        ]),
      ),
      Expanded(
        child: BlocBuilder<LedgerMasterBloc, LedgerState>(
            builder: (context, state) {
              if (state is LLoading) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyan, strokeWidth: 1.5));
              }
              if (state is LLoaded) {
                return LayoutBuilder(builder: (context, tableConstraints) {
                  final finalConstraints = tableConstraints.maxWidth > 0 ? tableConstraints : rootConstraints;
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: finalConstraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 12,
                        headingRowHeight: 34,
                        dataRowMinHeight: 36,
                        dataRowMaxHeight: 36,
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
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
                              ? DateFormat('HH:mm').format(DateTime.parse(e['updated_at']).toLocal())
                              : '--';

                          return DataRow(cells: [
                            DataCell(_cellText(e['name'] ?? '', bold: true, flex: 3, constraints: finalConstraints)),
                            DataCell(_cellText(e['group'] ?? '', flex: 2, constraints: finalConstraints)),
                            DataCell(_cellText(e['opening_balance_credit']?.toString() ?? '0.00', color: Colors.green, flex: 1.5, constraints: finalConstraints)),
                            DataCell(_cellText(e['opening_balance_debit']?.toString() ?? '0.00', color: Colors.redAccent, flex: 1.5, constraints: finalConstraints)),
                            DataCell(_cellText(time, flex: 1.2, constraints: finalConstraints)),
                            DataCell(SizedBox(
                              width: (finalConstraints.maxWidth * (1.2 / 10.4)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (e['group'] != "SALES" && e['group'] != "PURCHASE")
                                    InkWell(
                                      onTap: () => _fill(e),
                                      child: const Icon(Icons.edit_outlined, color: Colors.orange, size: 14),
                                    )
                                  else
                                    const SizedBox(width: 14),

                                  const SizedBox(width: 10),

                                  InkWell(
                                    onTap: () => _printPdf(context, d: e),
                                    child: const Icon(Icons.print_outlined, color: Colors.blueAccent, size: 14),
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

  // --- Core Functional Micro Helpers ---

  DataColumn _profColumn(String label, {required double flex}) {
    return DataColumn(
        label: Expanded(
            flex: (flex * 10).toInt(),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2))));
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
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? const Color(0xFF1E293B))),
    );
  }

  Widget _tf(TextEditingController c, String l,
      {bool readOnly = false, bool isNum = false, Function(String)? onCh}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
            controller: c,
            readOnly: readOnly,
            onChanged: onCh,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
                labelText: l,
                labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                border: const OutlineInputBorder(),
                filled: readOnly,
                fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.all(10))),
      );

  Widget _dd(String l, String? v, Function(String?) onCh) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(
        value: v,
        style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
            labelText: l,
            labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
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