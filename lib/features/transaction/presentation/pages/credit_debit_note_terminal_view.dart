import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/customer_master_screen.dart';
import '../../../masters/presentation/pages/supplier_master_screen.dart';
import '../../../masters/presentation/pages/uom_master_screen.dart';
import 'financial_note_pdf_generator.dart';

// ==========================================================================
// REPOSITORY LAYER
// ==========================================================================
class FinancialNoteRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> saveNote({required Map<String, dynamic> data}) async {
    final response = await apiClient.post('/api/transactions/financial_notes/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchNotesRegistry({String? search, String? noteType}) async {
    try {
      final response = await apiClient.get(
        '/api/transactions/financial_notes/',
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (noteType != null && noteType != 'ALL') 'note_type': noteType,
        },
      );
      if (response.data is Map && response.data['results'] != null) {
        return response.data['results'] as List<dynamic>;
      }
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error fetching notes registry: $e");
      return [];
    }
  }
}

// ==========================================================================
// BLOC LAYER
// ==========================================================================
abstract class NoteTxEvent {}
class SaveNoteEvent extends NoteTxEvent { final Map<String, dynamic> data; SaveNoteEvent(this.data); }
class LoadNotesRegistryEvent extends NoteTxEvent {
  final String? search; final String? noteType;
  LoadNotesRegistryEvent({this.search, this.noteType});
}

abstract class NoteTxState {}
class NoteTxInitial extends NoteTxState {}
class NoteTxLoading extends NoteTxState {}
class NoteTxSuccess extends NoteTxState { final Map<String, dynamic> responseData; NoteTxSuccess(this.responseData); }
class NoteTxError extends NoteTxState { final String message; NoteTxError(this.message); }
class NoteRegistryLoadedState extends NoteTxState { final List<dynamic> notesList; NoteRegistryLoadedState(this.notesList); }

class NoteTxBloc extends Bloc<NoteTxEvent, NoteTxState> {
  final FinancialNoteRepository repository;
  NoteTxBloc(this.repository) : super(NoteTxInitial()) {
    on<SaveNoteEvent>((event, emit) async {
      emit(NoteTxLoading());
      try {
        final savedResponse = await repository.saveNote(data: event.data);
        emit(NoteTxSuccess(savedResponse));
      } catch (e) { emit(NoteTxError(e.toString())); }
    });
    on<LoadNotesRegistryEvent>((event, emit) async {
      emit(NoteTxLoading());
      try {
        final data = await repository.fetchNotesRegistry(search: event.search, noteType: event.noteType);
        emit(NoteRegistryLoadedState(data));
      } catch (e) { emit(NoteTxError(e.toString())); }
    });
  }
}

// ==========================================================================
// ROW CONTROLLER CORE MATRIX
// ==========================================================================
class NoteRowController {
  int sno;
  final productCtrl = TextEditingController();
  final hsnCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "0");
  final rateCtrl = TextEditingController(text: "0");
  final cgstPCtrl = TextEditingController(text: "9");
  final sgstPCtrl = TextEditingController(text: "9");
  final igstPCtrl = TextEditingController(text: "18");
  final lineTotalCtrl = TextEditingController(text: "0.00");
  String? selectedUom;

  NoteRowController({required this.sno});

  void calculate() {
    double q = double.tryParse(qtyCtrl.text) ?? 0;
    double r = double.tryParse(rateCtrl.text) ?? 0;
    double cP = double.tryParse(cgstPCtrl.text) ?? 0;
    double sP = double.tryParse(sgstPCtrl.text) ?? 0;

    double iP = cP + sP;
    igstPCtrl.text = iP.toStringAsFixed(0);

    double baseAmt = q * r;
    double taxAmt = (baseAmt * iP / 100);
    lineTotalCtrl.text = (baseAmt + taxAmt).toStringAsFixed(2);
  }
}

// ==========================================================================
// MAIN PRESENTATION CANCEL CANVAS SURFACE
// ==========================================================================
class CreditDebitNoteTerminalScreen extends StatefulWidget {
  const CreditDebitNoteTerminalScreen({super.key});

  @override
  State<CreditDebitNoteTerminalScreen> createState() => _CreditDebitNoteTerminalScreenState();
}

class _CreditDebitNoteTerminalScreenState extends State<CreditDebitNoteTerminalScreen> {
  String _noteMode = "DEBIT_NOTE";
  String _selectedReason = "DAMAGED_GOODS";

  final _docNoCtrl = TextEditingController(); // 🌟 Target sequential binder
  final _docDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _invRefCtrl = TextEditingController();
  final _invDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _ewbNoCtrl = TextEditingController();
  final _dispatchCtrl = TextEditingController();

  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();

  final _amtInWordsCtrl = TextEditingController(text: "ZERO RUPEES ONLY");
  double totalPcs = 0, taxableAmt = 0, totalTax = 0, grandTotal = 0, roundOff = 0;

  String? _selectedMasterType;
  int? _selectedMasterId;

  List<NoteRowController> rows = [NoteRowController(sno: 1)];

  final List<Map<String, String>> _reasons = [
    {"value": "DAMAGED_GOODS", "label": "DAMAGED GOODS"},
    {"value": "RATE_DIFFERENCE", "label": "RATE DIFFERENCE"},
    {"value": "SALES_RETURN", "label": "SALES RETURN"},
    {"value": "PURCHASE_RETURN", "label": "PURCHASE RETURN"},
    {"value": "SHORTAGE", "label": "SHORTAGE / LESS QTY"},
  ];

  @override
  void initState() {
    super.initState();
    _loadMasters();
    _fetchNextNoteCounter(); // 👈 Sequential counter initial load preload hook
  }

  @override
  void dispose() {
    _docNoCtrl.dispose(); _docDateCtrl.dispose(); _invRefCtrl.dispose(); _invDateCtrl.dispose();
    _ewbNoCtrl.dispose(); _dispatchCtrl.dispose(); _nameCtrl.dispose(); _addrCtrl.dispose();
    _cityCtrl.dispose(); _pinCtrl.dispose(); _gstNoCtrl.dispose(); _narrationCtrl.dispose();
    _amtInWordsCtrl.dispose();
    super.dispose();
  }

  // 🟢 NEW ACCURATE FEATURE: Fetches upcoming unique index counters dynamically from views actions
  Future<void> _fetchNextNoteCounter() async {
    try {
      final response = await sl<ApiClient>().get(
        '/api/transactions/financial_notes/next_note_number/',
        query: {'note_type': _noteMode},
      );
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _docNoCtrl.text = response.data['next_note_bill_no'].toString();
        });
      }
    } catch (e) {
      debugPrint("Returns note tracker matrix sequential pre-load execution fail: $e");
    }
  }

  void _loadMasters() {
    context.read<UomBloc>().add(LoadUoms());
    context.read<SupplierBloc>().add(LoadSuppliers());
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  void _calculateTotals() {
    double p = 0, a = 0, tax = 0;

    for (var r in rows) {
      r.calculate();
      double q = double.tryParse(r.qtyCtrl.text) ?? 0;
      double rt = double.tryParse(r.rateCtrl.text) ?? 0;

      p += q;
      a += (q * rt);

      double rowTaxable = q * rt;
      double rowTaxPercent = double.tryParse(r.igstPCtrl.text) ?? 0;
      tax += (rowTaxable * rowTaxPercent / 100);
    }

    double sub = a + tax;
    double roundedTotal = sub.roundToDouble();

    setState(() {
      totalPcs = p;
      taxableAmt = double.parse(a.toStringAsFixed(2));
      totalTax = double.parse(tax.toStringAsFixed(2));
      roundOff = double.parse((roundedTotal - sub).toStringAsFixed(2));
      grandTotal = roundedTotal;
      _amtInWordsCtrl.text = "${_numToWords(grandTotal.toInt())} RUPEES ONLY";
    });
  }

  String _numToWords(int n) {
    var units = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN"];
    var tens = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY"];
    if (n < 20) return units[n];
    if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " ${units[n % 10]}" : "");
    if (n < 1000) return "${units[n ~/ 100]} HUNDRED${n % 100 != 0 ? " AND ${_numToWords(n % 100)}" : ""}";
    if (n < 100000) return "${_numToWords(n ~/ 1000)} THOUSAND${n % 1000 != 0 ? " ${_numToWords(n % 1000)}" : ""}";
    if (n < 10000000) return "${_numToWords(n ~/ 100000)} LAKH${n % 100000 != 0 ? " ${_numToWords(n % 100000)}" : ""}";
    return "${_numToWords(n ~/ 10000000)} CRORE${n % 10000000 != 0 ? " ${_numToWords(n % 10000000)}" : ""}";
  }

  void _resetForm() {
    setState(() {
      _docDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _invRefCtrl.clear();
      _invDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _ewbNoCtrl.clear(); _dispatchCtrl.clear();
      _selectedMasterId = null;
      _selectedMasterType = null;
      _nameCtrl.clear(); _addrCtrl.clear(); _cityCtrl.clear(); _pinCtrl.clear(); _gstNoCtrl.clear(); _narrationCtrl.clear();
      rows = [NoteRowController(sno: 1)];
      totalPcs = 0; taxableAmt = 0; totalTax = 0; grandTotal = 0; roundOff = 0;
      _amtInWordsCtrl.text = "ZERO RUPEES ONLY";
    });
    _fetchNextNoteCounter(); // 👈 Forms reset numeric counter load sequence
  }

  String _formatToBackendDate(String ddMMyyyy) {
    try {
      DateTime parsed = DateFormat('dd-MM-yyyy').parse(ddMMyyyy);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return DateTime.now().toString().split(" ")[0];
    }
  }

  void _dispatchSave() {
    if (_selectedMasterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Select Profile Allocation Entity!")));
      return;
    }

    final payload = {
      "note_type": _noteMode,
      "note_date": _formatToBackendDate(_docDateCtrl.text),
      "original_invoice_no": _invRefCtrl.text,
      "original_invoice_date": _formatToBackendDate(_invDateCtrl.text),
      "reason": _selectedReason,
      "ewb_no": _ewbNoCtrl.text,
      "dispatch": _dispatchCtrl.text,
      "name": _nameCtrl.text,
      "address": _addrCtrl.text,
      "city": _cityCtrl.text,
      "pin": _pinCtrl.text,
      "gst_number": _gstNoCtrl.text,
      "total_pcs": totalPcs,
      "total_taxable": taxableAmt,
      "cgst": totalTax / 2,
      "sgst": totalTax / 2,
      "igst": totalTax,
      "round_off": roundOff,
      "grand_total": grandTotal,
      "amtin_words": _amtInWordsCtrl.text,
      "narration": _narrationCtrl.text,

      if (_selectedMasterType == "SUPPLIER") "supplier": _selectedMasterId,
      if (_selectedMasterType == "CUSTOMER") "customer": _selectedMasterId,

      "details": rows.map((r) => {
        "sno": r.sno,
        "product_name": r.productCtrl.text,
        "uom": r.selectedUom ?? "PCS",
        "hsncode": r.hsnCtrl.text,
        "qty": double.tryParse(r.qtyCtrl.text) ?? 0,
        "rate": double.tryParse(r.rateCtrl.text) ?? 0,
        "amount": (double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0),
        "cgst_p": double.tryParse(r.cgstPCtrl.text) ?? 0,
        "sgst_p": double.tryParse(r.sgstPCtrl.text) ?? 0,
        "igst_p": double.tryParse(r.igstPCtrl.text) ?? 0,
        "cgst_amt": ((double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0) * (double.tryParse(r.cgstPCtrl.text) ?? 0) / 100),
        "sgst_amt": ((double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0) * (double.tryParse(r.sgstPCtrl.text) ?? 0) / 100),
        "igst_amt": ((double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0) * (double.tryParse(r.igstPCtrl.text) ?? 0) / 100),
        "total": double.tryParse(r.lineTotalCtrl.text) ?? 0,
      }).toList(),
    };
    context.read<NoteTxBloc>().add(SaveNoteEvent(payload));
  }

  Future<void> _triggerPdfLayout(Map<String, dynamic> outputData) async {
    try {
      final ByteData rawLogo = await rootBundle.load('assets/images/ultra_logo.jpeg');
      final pw.ImageProvider logoProvider = pw.MemoryImage(rawLogo.buffer.asUint8List());

      List<String> headings = _noteMode == "DEBIT_NOTE"
          ? ["ORIGINAL VENDOR ACCOUNT COPY"]
          : ["ORIGINAL CLIENT BALANCES REVERSAL COPY"];

      final pdfDoc = await FinancialNotePdfService.generate(
        logoImage: logoProvider,
        data: outputData,
        noteMode: _noteMode,
        headings: headings,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfDoc.save(),
        name: '${_noteMode}_${outputData['note_no']}.pdf',
      );
    } catch (e) {
      debugPrint("PDF Engine Matrix Failure Boundary: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 1000;
    Color screenColor = _noteMode == "DEBIT_NOTE" ? const Color(0xFF912B2B) : const Color(0xFF1E5631);

    return BlocListener<NoteTxBloc, NoteTxState>(
      listener: (context, state) {
        if (state is NoteTxLoading) {
          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        } else {
          if (state is NoteTxSuccess || state is NoteTxError) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          if (state is NoteTxSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Note Successfully Posted inside Ledgers!"), backgroundColor: Colors.green));
            _triggerPdfLayout(state.responseData).then((_) {
              if (mounted) _resetForm();
            });
          } else if (state is NoteTxError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error Posting Note: ${state.message}"), backgroundColor: Colors.red));
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: screenColor,
          toolbarHeight: isMobile ? 120 : 65,
          title: isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${_noteMode.replaceAll('_', ' ')} CORE", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildModeDropdown()
          ])
              : Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("${_noteMode.replaceAll('_', ' ')} REVERSAL ENGINE", style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  _stat("PCS ITEM COUNT", totalPcs.toInt().toString()),
                  _stat("TAXABLE AMT", taxableAmt.toStringAsFixed(2)),
                  _stat("TOTAL TAX", totalTax.toStringAsFixed(2)),
                ])
              ]),
            ),
            _buildDesktopToggle(),
            const SizedBox(width: 40),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("NET ACCOUNT REVERSAL VALUE", style: TextStyle(fontSize: 8, color: Colors.white70))
            ])
          ]),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            if (isMobile) ...[
              _section("SECTION 1: DISPATCH / SOURCE METADATA", _buildInvoiceSection()),
              _section("SECTION 2: ALLOCATED PARTY DIRECTORY", _buildMasterSection()),
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _section("SECTION 1: DISPATCH / SOURCE METADATA", _buildInvoiceSection())),
                const SizedBox(width: 12),
                Expanded(child: _section("SECTION 2: ALLOCATED PARTY DIRECTORY", _buildMasterSection())),
              ]),
            _section("SECTION 3: REVERSAL TRANSACTIONAL ACCOUNT MATRIX", _buildProductGrid(isMobile)),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              color: const Color(0xFF1A252F),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(child: _tfNotes(_narrationCtrl, "NARRATION / ACCOUNT COMMENTS")),
                  const SizedBox(width: 16),
                  Text("WORDS: ${_amtInWordsCtrl.text}", style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: screenColor, foregroundColor: Colors.white, minimumSize: const Size(350, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
              onPressed: _dispatchSave,
              icon: const Icon(Icons.security_update_good_rounded, size: 14),
              label: Text("POST & SECURE ${_noteMode.replaceAll('_', ' ')}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildInvoiceSection() => Column(children: [
    Row(children: [
      Expanded(child: _tf(_docNoCtrl, "NOTE NUMERIC NO *", readOnly: true)), // 🌟 Displays tracking serial integers
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_docDateCtrl, "NOTE ISSUE DATE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_invRefCtrl, "ORIGINAL INVOICE REF NO")),
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_invDateCtrl, "ORIGINAL INVOICE DATE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _buildReasonDropdown()),
      const SizedBox(width: 8),
      Expanded(child: _tf(_ewbNoCtrl, "E-WAY BILL NO")),
    ]),
    const SizedBox(height: 10),
    _tf(_dispatchCtrl, "LOGISTICS DISPATCH VEHICLE DETAILS / MODE"),
  ]);

  Widget _buildMasterSection() => Column(children: [
    _masterDropdown(),
    const SizedBox(height: 10),
    _tf(_addrCtrl, "REGISTERED OFFICE BILLING ADDRESS", readOnly: true),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(flex: 2, child: _tf(_cityCtrl, "CITY LOCATION", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(flex: 1, child: _pinCtrl.text.isEmpty ? _tf(_pinCtrl, "PINCODE") : _tf(_pinCtrl, "PINCODE", readOnly: true)),
    ]),
    const SizedBox(height: 10),
    _tf(_gstNoCtrl, "PARTY IDENTIFICATIONIN (GSTIN) NUMBER", readOnly: true),
  ]);

  Widget _buildProductGrid(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        ...rows.asMap().entries.map((e) => _buildMobileProductCard(e.key)),
        _addLineBtn(),
      ]);
    }
    return Column(children: [
      Container(padding: const EdgeInsets.all(8), color: const Color(0xFF2C3E50), child: Row(children: const [
        SizedBox(width: 30, child: Text("SL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 4, child: Text("MATERIAL MATRIX PARTICULARS", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("UOM", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("HSN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("QTY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("RATE/VAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("CGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("SGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("IGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("EXTENDED VAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        SizedBox(width: 35),
      ])),
      ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: rows.length, itemBuilder: (ctx, i) => _itemRowDesktop(i)),
      _addLineBtn(),
    ]);
  }

  Widget _itemRowDesktop(int i) {
    final r = rows[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(children: [
        SizedBox(width: 30, child: Text("${i + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        Expanded(flex: 4, child: _gridTf(r.productCtrl, "Item Description")),
        Expanded(flex: 1, child: _uomDropdown(i)),
        Expanded(flex: 1, child: _gridTf(r.hsnCtrl, "HSN")),
        Expanded(flex: 1, child: _gridTf(r.qtyCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _gridTf(r.rateCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _gridTf(r.cgstPCtrl, "9", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _gridTf(r.sgstPCtrl, "9", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _gridTf(r.igstPCtrl, "18", readOnly: true)),
        Expanded(flex: 2, child: _gridTf(r.lineTotalCtrl, "0", readOnly: true)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
      ]),
    );
  }

  Widget _buildMobileProductCard(int i) {
    final r = rows[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("MATERIAL ITEM #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 16), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
        ]),
        _tf(r.productCtrl, "Particulars Description"),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: _uomDropdown(i)), const SizedBox(width: 6), Expanded(child: _tf(r.hsnCtrl, "HSN"))]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _tf(r.qtyCtrl, "Quantity", isNum: true, onCh: (v)=>_calculateTotals())),
          const SizedBox(width: 6),
          Expanded(child: _tf(r.rateCtrl, "Rate Value", isNum: true, onCh: (v)=>_calculateTotals())),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _tf(r.cgstPCtrl, "CGST%", isNum: true, onCh: (v)=>_calculateTotals())),
          const SizedBox(width: 6),
          Expanded(child: _tf(r.sgstPCtrl, "SGST%", isNum: true, onCh: (v)=>_calculateTotals())),
          const SizedBox(width: 6),
          Expanded(child: _tf(r.igstPCtrl, "IGST%", readOnly: true)),
        ]),
        const SizedBox(height: 6),
        _tf(r.lineTotalCtrl, "Extended Row Balance", readOnly: true),
      ])),
    );
  }

  Widget _buildModeDropdown() => Container(
    height: 32, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _noteMode, dropdownColor: _noteMode == "DEBIT_NOTE" ? const Color(0xFF912B2B) : const Color(0xFF1E5631),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        items: const [DropdownMenuItem(value: "DEBIT_NOTE", child: Text("DEBIT NOTE (PURCHASE RETURN)")), DropdownMenuItem(value: "CREDIT_NOTE", child: Text("CREDIT NOTE (SALES RETURN)"))],
        onChanged: (v) { if(v != null) setState(() { _noteMode = v; _resetForm(); _loadMasters(); }); },
      ),
    ),
  );

  Widget _buildDesktopToggle() => ToggleButtons(
    isSelected: [_noteMode == "DEBIT_NOTE", _noteMode == "CREDIT_NOTE"],
    onPressed: (idx) => setState(() { _noteMode = idx == 0 ? "DEBIT_NOTE" : "CREDIT_NOTE"; _resetForm(); _loadMasters(); }),
    borderRadius: BorderRadius.circular(4), constraints: const BoxConstraints(minHeight: 30, minWidth: 110),
    selectedColor: Colors.white, fillColor: Colors.white24,
    children: const [Text("DEBIT NOTE", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)), Text("CREDIT NOTE", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))],
  );

  Widget _buildReasonDropdown() => DropdownButtonFormField<String>(
    value: _selectedReason,
    decoration: const InputDecoration(labelText: "REASON FOR TRANSACTION REVERSAL", border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
    style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w500),
    items: _reasons.map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label']!, style: const TextStyle(fontSize: 11)))).toList(),
    onChanged: (v) { if (v != null) setState(() => _selectedReason = v); },
  );

  // 🌟 SAFE POINTER MATCH SYNC DROPDOWN
  Widget _masterDropdown() {
    return _noteMode == "DEBIT_NOTE"
        ? BlocBuilder<SupplierBloc, SupplierState>(builder: (context, state) {
      final List<SupplierEntity> list = (state is SupplierLoaded) ? state.suppliers : [];

      final List<DropdownMenuItem<String>> dropdownItems = list.map((s) => DropdownMenuItem(
        value: "SUPPLIER_${s.id}",
        child: Text(s.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
      )).toList();

      String? selectionKey;
      if (_selectedMasterId != null && _selectedMasterType == "SUPPLIER") {
        selectionKey = "SUPPLIER_$_selectedMasterId";
      }

      return DropdownButtonFormField<String>(
        value: selectionKey,
        isExpanded: true,
        decoration: const InputDecoration(labelText: "SELECT SUPPLIER ACCOUNT DIRECTORY *", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
        items: dropdownItems,
        onChanged: (v) {
          if (v != null) {
            final id = int.tryParse(v.split("_")[1]);
            final match = list.firstWhere((e) => e.id == id);
            setState(() {
              _selectedMasterType = "SUPPLIER";
              _selectedMasterId = match.id;
              _nameCtrl.text = match.name;
              _addrCtrl.text = match.address ?? "";
              _cityCtrl.text = match.city ?? "";
              _pinCtrl.text = match.pinCode ?? "";
              _gstNoCtrl.text = match.gstNumber ?? "";
              _calculateTotals();
            });
          }
        },
      );
    })
        : BlocBuilder<CustomerBloc, CustomerState>(builder: (context, state) {
      final List<CustomerEntity> list = (state is CustomerLoaded) ? state.customers : [];

      final List<DropdownMenuItem<String>> dropdownItems = list.map((c) => DropdownMenuItem(
        value: "CUSTOMER_${c.id}",
        child: Text(c.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
      )).toList();

      String? selectionKey;
      if (_selectedMasterId != null && _selectedMasterType == "CUSTOMER") {
        selectionKey = "CUSTOMER_$_selectedMasterId";
      }

      return DropdownButtonFormField<String>(
        value: selectionKey,
        isExpanded: true,
        decoration: const InputDecoration(labelText: "SELECT CUSTOMER ACCOUNT DIRECTORY *", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
        items: dropdownItems,
        onChanged: (v) {
          if (v != null) {
            final id = int.tryParse(v.split("_")[1]);
            final match = list.firstWhere((e) => e.id == id);
            setState(() {
              _selectedMasterType = "CUSTOMER";
              _selectedMasterId = match.id;
              _nameCtrl.text = match.name;
              _addrCtrl.text = match.address;
              _cityCtrl.text = match.city;
              _pinCtrl.text = match.pincode;
              _gstNoCtrl.text = match.gstNo;
              _calculateTotals();
            });
          }
        },
      );
    });
  }

  Widget _uomDropdown(int i) => BlocBuilder<UomBloc, UomState>(builder: (context, state) {
    final List<UomEntity> list = (state is UomLoaded) ? state.uoms : [];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4), color: Colors.white), height: 28,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: rows[i].selectedUom, isExpanded: true, hint: const Text("UOM", style: TextStyle(fontSize: 9)),
          items: list.map((u) => DropdownMenuItem(value: u.uomName, child: Text(u.uomName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)))).toList(),
          onChanged: (v) => setState(() => rows[i].selectedUom = v),
        ),
      ),
    );
  });

  Widget _tf(TextEditingController c, String l, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => TextFormField(
    controller: c, readOnly: readOnly, onChanged: onCh, textInputAction: TextInputAction.next,
    keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10), border: const OutlineInputBorder(), isDense: true, filled: readOnly, fillColor: readOnly ? Colors.grey.shade100 : Colors.white),
  );

  Widget _gridTf(TextEditingController c, String h, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1.0),
    child: TextFormField(
      controller: c, readOnly: readOnly, onChanged: onCh, textInputAction: TextInputAction.next,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(fontSize: 10), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), isDense: true, filled: readOnly, fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white),
    ),
  );

  Widget _dateTf(TextEditingController c, String l) => TextFormField(
    controller: c, readOnly: true, onTap: () async { DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101)); if (p != null) setState(() => c.text = DateFormat('dd-MM-yyyy').format(p)); },
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10), prefixIcon: const Icon(Icons.calendar_today, size: 11), border: const OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
  );

  Widget _tfNotes(TextEditingController c, String l) => SizedBox(height: 35, child: TextField(controller: c, style: const TextStyle(color: Colors.yellowAccent, fontSize: 11), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white70, fontSize: 9), filled: true, fillColor: Colors.black26, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8))));
  Widget _stat(String l, String v) => Padding(padding: const EdgeInsets.only(right: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 8, color: Colors.white70)), Text(v, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))]));
  Widget _addLineBtn() => Padding(padding: const EdgeInsets.only(top: 6.0), child: ElevatedButton.icon(onPressed: () => setState(() => rows.add(NoteRowController(sno: rows.length + 1))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white), icon: const Icon(Icons.add, size: 12), label: const Text("ADD REVERSAL MATERIAL ITEM ROW", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))));
  Widget _section(String t, Widget c) => Card(elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))), const Divider(height: 14), c])));
}