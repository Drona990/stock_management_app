
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/customer_master_screen.dart';
import '../../../masters/presentation/pages/supplier_master_screen.dart';
import '../../../masters/presentation/pages/uom_master_screen.dart';

// ==========================================================================
// 1. REPOSITORY LAYER
// ==========================================================================
class TransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<void> saveTransaction(Map<String, dynamic> data, bool isSales) async {
    final endpoint = isSales
        ? '/api/transactions/salse_transaction/'
        : '/api/transactions/purchase_transaction/';
    await apiClient.post(endpoint, data: data);
  }
}

// ==========================================================================
// 2. BLOC LAYER
// ==========================================================================
abstract class TransactionEvent {}
class SaveInvoiceEvent extends TransactionEvent {
  final Map<String, dynamic> data;
  final bool isSales;
  SaveInvoiceEvent(this.data, this.isSales);
}

abstract class TransactionState {}
class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionSuccess extends TransactionState {}
class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc(this.repository) : super(TransactionInitial()) {
    on<SaveInvoiceEvent>((event, emit) async {
      emit(TransactionLoading());
      try {
        await repository.saveTransaction(event.data, event.isSales);
        if (!isClosed) emit(TransactionSuccess());
      } catch (e) {
        if (!isClosed) emit(TransactionError(e.toString()));
      }
    });
  }
}

// ==========================================================================
// 3. ROW CONTROLLER (GRID LOGIC)
// ==========================================================================
/*class TransactionRowController {
  int sno;
  final productCtrl = TextEditingController();
  final hsnCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "0");
  final rateCtrl = TextEditingController(text: "0");
  final cgstPCtrl = TextEditingController(text: "0");
  final sgstPCtrl = TextEditingController(text: "0");
  final igstPCtrl = TextEditingController(text: "0");
  final lineTotalCtrl = TextEditingController(text: "0.00");
  String? selectedUom;

  TransactionRowController({required this.sno});

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

class TransactionTerminalScreen extends StatefulWidget {
  final bool isSales;
  const TransactionTerminalScreen({super.key, required this.isSales});

  @override
  State<TransactionTerminalScreen> createState() => _TransactionTerminalScreenState();
}

class _TransactionTerminalScreenState extends State<TransactionTerminalScreen> {
  // --- Section 1: Invoice Details ---
  final _billNoCtrl = TextEditingController();
  final _billDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _poNoCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _dcNoCtrl = TextEditingController();
  final _dcDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _pkgCtrl = TextEditingController();
  final _dueDaysCtrl = TextEditingController(text: "0");

  // --- Section 2: Party Details ---
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();
  final _shipAddrCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();

  // --- Section 3: Totals & Financials ---
  final _fwdChargeCtrl = TextEditingController(text: "0");
  final _amtInWordsCtrl = TextEditingController(text: "Zero Only");
  double totalPcs = 0, taxableAmt = 0, totalTax = 0, grandTotal = 0, roundOff = 0;
  int? _selectedMasterId;

  List<TransactionRowController> rows = [TransactionRowController(sno: 1)];

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  void _loadMasters() {
    context.read<UomBloc>().add(LoadUoms());
    if (widget.isSales) context.read<CustomerBloc>().add(LoadCustomers());
    else context.read<SupplierBloc>().add(LoadSuppliers());
  }

  void _calculateTotals() {
    double p = 0, a = 0, tax = 0;
    for (var r in rows) {
      r.calculate();
      double q = double.tryParse(r.qtyCtrl.text) ?? 0;
      double rt = double.tryParse(r.rateCtrl.text) ?? 0;
      p += q; a += (q * rt);
      tax += ((q * rt) * (double.tryParse(r.igstPCtrl.text) ?? 0) / 100);
    }
    double fwd = double.tryParse(_fwdChargeCtrl.text) ?? 0;
    double sub = a + tax + fwd;
    double rounded = sub.roundToDouble();
    setState(() {
      totalPcs = p; taxableAmt = a; totalTax = tax;
      roundOff = rounded - sub; grandTotal = rounded;
    });
  }

  // --- RESET FORM AFTER SUCCESS ---
  void _resetForm() {
    setState(() {
      _billNoCtrl.clear();
      _billDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _poNoCtrl.clear();
      _poDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dcNoCtrl.clear();
      _dcDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _pkgCtrl.clear();
      _dueDaysCtrl.text = "0";

      _selectedMasterId = null;
      _nameCtrl.clear();
      _addrCtrl.clear();
      _cityCtrl.clear();
      _pinCtrl.clear();
      _gstNoCtrl.clear();
      _shipAddrCtrl.clear();
      _accNoCtrl.clear();

      _fwdChargeCtrl.text = "0";
      _amtInWordsCtrl.text = "Zero Only";
      rows = [TransactionRowController(sno: 1)];
      totalPcs = 0; taxableAmt = 0; totalTax = 0; grandTotal = 0; roundOff = 0;
    });
  }

  void _dispatchSave() {
    if (_selectedMasterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Party!")));
      return;
    }

    final payload = {
      "billno": int.tryParse(_billNoCtrl.text) ?? 0,
      "billdate": _billDateCtrl.text,
      "purchase_order_no": _poNoCtrl.text,
      "purchase_order_date": _poDateCtrl.text,
      "dc_no": _dcNoCtrl.text,
      "dc_date": _dcDateCtrl.text,
      "no_of_package": _pkgCtrl.text,
      "due_date": int.tryParse(_dueDaysCtrl.text) ?? 0,
      "name": _nameCtrl.text,
      "address": _addrCtrl.text,
      "city": _cityCtrl.text,
      "pin": _pinCtrl.text,
      "gst_number": _gstNoCtrl.text,
      "shipping_address": _shipAddrCtrl.text,
      "total_pcs": totalPcs,
      "totalamount": taxableAmt,
      "forwading_charge": double.tryParse(_fwdChargeCtrl.text) ?? 0,
      "cgst": totalTax / 2,
      "sgst": totalTax / 2,
      "igst": totalTax,
      "round_off": roundOff,
      "grand_totamt": grandTotal,
      "amtin_words": _amtInWordsCtrl.text,
      "accno": _accNoCtrl.text,
      widget.isSales ? "customer" : "supplier": _selectedMasterId,
      "details": rows.map((r) => {
        "sno": r.sno,
        "product_name": r.productCtrl.text,
        "uom": r.selectedUom ?? "PCS",
        "hsncode": r.hsnCtrl.text,
        "qty": double.tryParse(r.qtyCtrl.text) ?? 0,
        "rate": double.tryParse(r.rateCtrl.text) ?? 0,
        "amount": (double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0),
        "cgst": double.tryParse(r.cgstPCtrl.text) ?? 0,
        "sgst": double.tryParse(r.sgstPCtrl.text) ?? 0,
        "igst": double.tryParse(r.igstPCtrl.text) ?? 0,
        "total": double.tryParse(r.lineTotalCtrl.text) ?? 0,
      }).toList(),
    };
    context.read<TransactionBloc>().add(SaveInvoiceEvent(payload, widget.isSales));
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(widget.isSales ? "TAX INVOICE" : "PURCHASE VOUCHER", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text("GSTIN: ${_gstNoCtrl.text}"),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("BILL NO: ${_billNoCtrl.text}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text("DATE: ${_billDateCtrl.text}"),
          ]),
        ]),
        pw.Divider(),
        pw.Row(children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("BILL TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_nameCtrl.text),
            pw.Text(_addrCtrl.text, style: const pw.TextStyle(fontSize: 9)),
            pw.Text("CITY: ${_cityCtrl.text}, PIN: ${_pinCtrl.text}", style: const pw.TextStyle(fontSize: 9)),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("SHIP TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_shipAddrCtrl.text.isEmpty ? "Same as Billing" : _shipAddrCtrl.text, style: const pw.TextStyle(fontSize: 9)),
          ])),
        ]),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
          headers: ['SL', 'PRODUCT', 'HSN', 'UOM', 'QTY', 'RATE', 'GST%', 'TOTAL'],
          data: rows.map((r) => [r.sno, r.productCtrl.text, r.hsnCtrl.text, r.selectedUom, r.qtyCtrl.text, r.rateCtrl.text, "${r.igstPCtrl.text}%", r.lineTotalCtrl.text]).toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("Amt in Words: ${_amtInWordsCtrl.text}", style: const pw.TextStyle(fontSize: 9)),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("Taxable: ${taxableAmt.toStringAsFixed(2)}"),
            pw.Text("GST Total: ${totalTax.toStringAsFixed(2)}"),
            pw.Text("Fwd Charge: ${_fwdChargeCtrl.text}"),
            pw.Text("GRAND TOTAL: ${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ]),
        ]),
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        } else {
          if (state is TransactionSuccess || state is TransactionError) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          if (state is TransactionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Saved Successfully!"), backgroundColor: Colors.green));
            _generatePdf().then((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _resetForm();
              });
            });
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ${state.message}"), backgroundColor: Colors.red));
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A252F),
          toolbarHeight: 120,
          title: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.isSales ? "SALES TERMINAL" : "PURCHASE TERMINAL", style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
                Row(children: [_stat("PCS", totalPcs.toInt().toString()), _stat("TAXABLE", taxableAmt.toStringAsFixed(2)), _stat("GST", totalTax.toStringAsFixed(2))]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("GRAND TOTAL", style: TextStyle(fontSize: 8, color: Colors.white70)),
              ]),
            ]),
            const Divider(color: Colors.white24, height: 10),
            Row(children: [
              Expanded(child: Text("WORDS: ${_amtInWordsCtrl.text}", style: const TextStyle(fontSize: 9, color: Colors.white70, overflow: TextOverflow.ellipsis))),
              _tfAppBar(_fwdChargeCtrl, "FWD CHARGE"),
            ]),
          ]),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            _section("SECTION 1: INVOICE DETAILS", _buildInvoiceSection()),
            _section("SECTION 2: PARTY DETAILS", _buildMasterSection()),
            _section("SECTION 4: PRODUCT ENTRY", _buildProductGrid()),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ]),
        ),
      ),
    );
  }

  Widget _section(String t, Widget c) => Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const Divider(), c])));

  Widget _buildInvoiceSection() => Column(children: [
    Row(children: [Expanded(child: _tf(_billNoCtrl, "BILL NO", isNum: true)), const SizedBox(width: 8), Expanded(child: _tf(_billDateCtrl, "DATE")), const SizedBox(width: 8), Expanded(child: _tf(_dueDaysCtrl, "DUE DAYS", isNum: true))]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: _tf(_poNoCtrl, "PO NO")), const SizedBox(width: 8), Expanded(child: _tf(_poDateCtrl, "PO DATE")), const SizedBox(width: 8), Expanded(child: _tf(_dcNoCtrl, "DC NO")), const SizedBox(width: 8), Expanded(child: _tf(_dcDateCtrl, "DC DATE"))]),
    const SizedBox(height: 8), _tf(_pkgCtrl, "NO OF PACKAGE"),
  ]);

  Widget _buildMasterSection() => Column(children: [
    _masterDropdown(),
    const SizedBox(height: 10),
    Row(children: [Expanded(flex: 2, child: _tf(_addrCtrl, "ADDRESS", readOnly: true)), const SizedBox(width: 8), Expanded(child: _tf(_cityCtrl, "CITY", readOnly: true)), const SizedBox(width: 8), Expanded(child: _tf(_pinCtrl, "PIN", readOnly: true))]),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: _tf(_gstNoCtrl, "GST NUMBER", readOnly: true)), const SizedBox(width: 8), Expanded(child: _tf(_accNoCtrl, "ACCOUNT NUMBER", readOnly: true))]),
    const SizedBox(height: 8), _tf(_shipAddrCtrl, "SHIPPING ADDRESS"),
  ]);

  Widget _buildProductGrid() => Column(children: [
    Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xFF34495E),
        child: const Row(children: [
          SizedBox(width: 25, child: Text("SL", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 3, child: Text("PRODUCT", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("UOM", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("HSN", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("QTY", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("RATE", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("CGST%", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("SGST%", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 1, child: Text("IGST%", style: TextStyle(color: Colors.white, fontSize: 9))),
          Expanded(flex: 2, child: Text("TOTAL", style: TextStyle(color: Colors.white, fontSize: 9))),
          SizedBox(width: 30, child: Text("ACT", style: TextStyle(color: Colors.white, fontSize: 9))),
        ])),
    ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (ctx, i) => _itemRow(i),
    ),
    TextButton.icon(
        onPressed: () => setState(() => rows.add(TransactionRowController(sno: rows.length + 1))),
        icon: const Icon(Icons.add_circle),
        label: const Text("ADD LINE")
    ),
  ]);

  Widget _itemRow(int i) {
    final r = rows[i];
    return Row(children: [
      SizedBox(width: 25, child: Text("${i + 1}", style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)),
      Expanded(flex: 3, child: _gridTf(r.productCtrl, "Item")),
      Expanded(flex: 1, child: _uomDropdown(i)),
      Expanded(flex: 1, child: _gridTf(r.hsnCtrl, "HSN")),
      Expanded(flex: 1, child: _gridTf(r.qtyCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.rateCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.cgstPCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.sgstPCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.igstPCtrl, "0", readOnly: true)),
      Expanded(flex: 2, child: _gridTf(r.lineTotalCtrl, "0", readOnly: true)),
      IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
          onPressed: () {
            setState(() {
              if(rows.length > 1) rows.removeAt(i);
              _calculateTotals();
            });
          }
      ),
    ]);
  }

  Widget _stat(String l, String v) => Padding(padding: const EdgeInsets.only(right: 12), child: Column(children: [Text(l, style: const TextStyle(fontSize: 8, color: Colors.white54)), Text(v, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))]));
  Widget _tfAppBar(TextEditingController c, String l) => SizedBox(width: 100, height: 40, child: TextField(controller: c, onChanged: (v)=>_calculateTotals(), onTap: ()=>c.selection=TextSelection(baseOffset:0, extentOffset:c.text.length), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], style: const TextStyle(color: Colors.yellowAccent, fontSize: 13, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white70, fontSize: 9), filled: true, fillColor: Colors.black, isDense: true, enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.yellowAccent, width: 1), borderRadius: BorderRadius.circular(4)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5), borderRadius: BorderRadius.circular(4)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))));
  Widget _tf(TextEditingController c, String l, {bool isNum = false, bool readOnly = false}) => TextField(controller: c, readOnly: readOnly, onTap: ()=>c.selection=TextSelection(baseOffset:0, extentOffset:c.text.length), keyboardType: isNum ? TextInputType.number : TextInputType.text, inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : [], style: const TextStyle(fontSize: 11), decoration: InputDecoration(labelText: l, border: const OutlineInputBorder(), isDense: true));
  Widget _gridTf(TextEditingController c, String h, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => TextFormField(controller: c, readOnly: readOnly, onChanged: onCh, onTap: ()=>c.selection=TextSelection(baseOffset:0, extentOffset:c.text.length), keyboardType: isNum ? TextInputType.number : TextInputType.text, inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : [], style: const TextStyle(fontSize: 11), decoration: InputDecoration(hintText: h, border: InputBorder.none, isDense: true));
  Widget _buildActionButtons() => Center(child: SizedBox(width: 250, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white), onPressed: _dispatchSave, icon: const Icon(Icons.print), label: const Text("SAVE & PRINT INVOICE"))));

  Widget _masterDropdown() {
    return widget.isSales
        ? BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final List<CustomerEntity> list = (state is CustomerLoaded) ? state.customers : [];
        return DropdownButtonFormField<CustomerEntity>(
          value: _selectedMasterId == null ? null : list.firstWhere((e) => e.id == _selectedMasterId, orElse: () => list.first),
          decoration: const InputDecoration(labelText: "SELECT CUSTOMER", border: OutlineInputBorder(), isDense: true),
          items: list.map<DropdownMenuItem<CustomerEntity>>((CustomerEntity c) {
            return DropdownMenuItem<CustomerEntity>(
              value: c,
              child: Text(c.name, style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
          onChanged: (CustomerEntity? v) {
            if (v != null) {
              setState(() {
                _selectedMasterId = v.id;
                _nameCtrl.text = v.name;
                _addrCtrl.text = v.address ?? "";
                _cityCtrl.text = v.city ?? "";
                _pinCtrl.text = v.pincode ?? "";
                _gstNoCtrl.text = v.gstNo ?? "";
                _accNoCtrl.text = "NA";
              });
            }
          },
        );
      },
    )
        : BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        final List<SupplierEntity> list = (state is SupplierLoaded) ? state.suppliers : [];
        return DropdownButtonFormField<SupplierEntity>(
          value: _selectedMasterId == null ? null : list.firstWhere((e) => e.id == _selectedMasterId, orElse: () => list.first),
          decoration: const InputDecoration(labelText: "SELECT SUPPLIER", border: OutlineInputBorder(), isDense: true),
          items: list.map<DropdownMenuItem<SupplierEntity>>((SupplierEntity s) {
            return DropdownMenuItem<SupplierEntity>(
              value: s,
              child: Text(s.name, style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
          onChanged: (SupplierEntity? v) {
            if (v != null) {
              setState(() {
                _selectedMasterId = v.id;
                _nameCtrl.text = v.name;
                _addrCtrl.text = v.address ?? "";
                _cityCtrl.text = v.city ?? "";
                _pinCtrl.text = v.pinCode ?? "";
                _gstNoCtrl.text = v.gstNumber ?? "";
                _accNoCtrl.text = v.accountNo ?? "";
              });
            }
          },
        );
      },
    );
  }

  Widget _uomDropdown(int i) {
    return BlocBuilder<UomBloc, UomState>(
      builder: (context, state) {
        final List<UomEntity> list = (state is UomLoaded) ? state.uoms : [];
        String? currentValue = rows[i].selectedUom;
        if (currentValue != null && !list.any((u) => u.uomName == currentValue)) {
          currentValue = null;
        }
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            hint: const Text("UOM", style: TextStyle(fontSize: 10)),
            style: const TextStyle(fontSize: 10, color: Colors.black),
            items: list.map<DropdownMenuItem<String>>((UomEntity u) {
              return DropdownMenuItem<String>(
                value: u.uomName,
                child: Text(u.uomName),
              );
            }).toList(),
            onChanged: (String? v) {
              setState(() {
                rows[i].selectedUom = v;
              });
            },
          ),
        );
      },
    );
  }
}*/


class TransactionRowController {
  int sno;
  final productCtrl = TextEditingController();
  final hsnCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "0");
  final rateCtrl = TextEditingController(text: "0");
  final cgstPCtrl = TextEditingController(text: "0");
  final sgstPCtrl = TextEditingController(text: "0");
  final igstPCtrl = TextEditingController(text: "0");
  final lineTotalCtrl = TextEditingController(text: "0.00");
  String? selectedUom;

  TransactionRowController({required this.sno});

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

class TransactionTerminalScreen extends StatefulWidget {
  final bool isSales;
  const TransactionTerminalScreen({super.key, required this.isSales});

  @override
  State<TransactionTerminalScreen> createState() => _TransactionTerminalScreenState();
}

class _TransactionTerminalScreenState extends State<TransactionTerminalScreen> {
  // --- Section 1: Invoice Details ---
  final _billNoCtrl = TextEditingController();
  final _billDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _poNoCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _dcNoCtrl = TextEditingController();
  final _dcDateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _pkgCtrl = TextEditingController();
  final _dueDaysCtrl = TextEditingController(text: "0");

  // --- Section 2: Party Details ---
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();
  final _shipAddrCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();

  // --- Section 3: Totals ---
  final _fwdChargeCtrl = TextEditingController(text: "0");
  final _amtInWordsCtrl = TextEditingController(text: "ZERO RUPEES ONLY");
  double totalPcs = 0, taxableAmt = 0, totalTax = 0, grandTotal = 0, roundOff = 0;
  int? _selectedMasterId;

  List<TransactionRowController> rows = [TransactionRowController(sno: 1)];

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }


  String _numToWords(int n) {
    var units = ["", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN"];
    var tens = ["", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY", "EIGHTY", "NINETY"];

    if (n < 20) return units[n];
    if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " " + units[n % 10] : "");
    if (n < 1000) return units[n ~/ 100] + " HUNDRED" + (n % 100 != 0 ? " AND " + _numToWords(n % 100) : "");
    if (n < 100000) return _numToWords(n ~/ 1000) + " THOUSAND" + (n % 1000 != 0 ? " " + _numToWords(n % 1000) : "");
    if (n < 10000000) return _numToWords(n ~/ 100000) + " LAKH" + (n % 100000 != 0 ? " " + _numToWords(n % 100000) : "");
    return _numToWords(n ~/ 10000000) + " CRORE" + (n % 10000000 != 0 ? " " + _numToWords(n % 10000000) : "");
  }

  void _loadMasters() {
    context.read<UomBloc>().add(LoadUoms());
    if (widget.isSales) context.read<CustomerBloc>().add(LoadCustomers());
    else context.read<SupplierBloc>().add(LoadSuppliers());
  }

  void _calculateTotals() {
    double p = 0, a = 0, tax = 0;
    for (var r in rows) {
      r.calculate();
      double q = double.tryParse(r.qtyCtrl.text) ?? 0;
      double rt = double.tryParse(r.rateCtrl.text) ?? 0;
      p += q; a += (q * rt);
      tax += ((q * rt) * (double.tryParse(r.igstPCtrl.text) ?? 0) / 100);
    }
    double fwd = double.tryParse(_fwdChargeCtrl.text) ?? 0;
    double sub = a + tax + fwd;
    double rounded = sub.roundToDouble();
    setState(() {
      totalPcs = p; taxableAmt = a; totalTax = tax;
      roundOff = rounded - sub; grandTotal = rounded;
      _amtInWordsCtrl.text = _numToWords(grandTotal as int);
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => controller.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _resetForm() {
    setState(() {
      _billNoCtrl.clear();
      _billDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _poNoCtrl.clear();
      _poDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dcNoCtrl.clear();
      _dcDateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _pkgCtrl.clear();
      _dueDaysCtrl.text = "0";
      _selectedMasterId = null;
      _nameCtrl.clear(); _addrCtrl.clear(); _cityCtrl.clear();
      _pinCtrl.clear(); _gstNoCtrl.clear(); _shipAddrCtrl.clear(); _accNoCtrl.clear();
      _fwdChargeCtrl.text = "0"; _amtInWordsCtrl.text = "ZERO RUPEES ONLY";
      rows = [TransactionRowController(sno: 1)];
      totalPcs = 0; taxableAmt = 0; totalTax = 0; grandTotal = 0; roundOff = 0;
    });
  }

  void _dispatchSave() {
    if (_selectedMasterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Party!")));
      return;
    }
    final payload = {
      "billno": int.tryParse(_billNoCtrl.text) ?? 0,
      "billdate": _billDateCtrl.text,
      "purchase_order_no": _poNoCtrl.text,
      "purchase_order_date": _poDateCtrl.text,
      "dc_no": _dcNoCtrl.text,
      "dc_date": _dcDateCtrl.text,
      "no_of_package": _pkgCtrl.text,
      "due_date": int.tryParse(_dueDaysCtrl.text) ?? 0,
      "name": _nameCtrl.text,
      "address": _addrCtrl.text,
      "city": _cityCtrl.text,
      "pin": _pinCtrl.text,
      "gst_number": _gstNoCtrl.text,
      "shipping_address": _shipAddrCtrl.text,
      "total_pcs": totalPcs,
      "totalamount": taxableAmt,
      "forwading_charge": double.tryParse(_fwdChargeCtrl.text) ?? 0,
      "cgst": totalTax / 2,
      "sgst": totalTax / 2,
      "igst": totalTax,
      "round_off": roundOff,
      "grand_totamt": grandTotal,
      "amtin_words": _amtInWordsCtrl.text,
      "accno": _accNoCtrl.text,
      widget.isSales ? "customer" : "supplier": _selectedMasterId,
      "details": rows.map((r) => {
        "sno": r.sno, "product_name": r.productCtrl.text, "uom": r.selectedUom ?? "PCS",
        "hsncode": r.hsnCtrl.text, "qty": double.tryParse(r.qtyCtrl.text) ?? 0,
        "rate": double.tryParse(r.rateCtrl.text) ?? 0, "amount": (double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0),
        "cgst": double.tryParse(r.cgstPCtrl.text) ?? 0, "sgst": double.tryParse(r.sgstPCtrl.text) ?? 0,
        "igst": double.tryParse(r.igstPCtrl.text) ?? 0, "total": double.tryParse(r.lineTotalCtrl.text) ?? 0,
      }).toList(),
    };
    context.read<TransactionBloc>().add(SaveInvoiceEvent(payload, widget.isSales));
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(widget.isSales ? "TAX INVOICE" : "PURCHASE VOUCHER", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text("GSTIN: ${_gstNoCtrl.text}"),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("BILL NO: ${_billNoCtrl.text}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text("DATE: ${_billDateCtrl.text}"),
          ]),
        ]),
        pw.Divider(),
        pw.Row(children: [
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("BILL TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_nameCtrl.text),
            pw.Text(_addrCtrl.text, style: const pw.TextStyle(fontSize: 9)),
            pw.Text("CITY: ${_cityCtrl.text}, PIN: ${_pinCtrl.text}", style: const pw.TextStyle(fontSize: 9)),
          ])),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("SHIP TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_shipAddrCtrl.text.isEmpty ? "Same as Billing" : _shipAddrCtrl.text, style: const pw.TextStyle(fontSize: 9)),
          ])),
        ]),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
          headers: ['SL', 'PRODUCT', 'HSN', 'UOM', 'QTY', 'RATE', 'GST%', 'TOTAL'],
          data: rows.map((r) => [r.sno, r.productCtrl.text, r.hsnCtrl.text, r.selectedUom, r.qtyCtrl.text, r.rateCtrl.text, "${r.igstPCtrl.text}%", r.lineTotalCtrl.text]).toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("Amt in Words: ${_amtInWordsCtrl.text} Rupees only.", style: const pw.TextStyle(fontSize: 9)),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text("Taxable: ${taxableAmt.toStringAsFixed(2)}"),
            pw.Text("GST Total: ${totalTax.toStringAsFixed(2)}"),
            pw.Text("Fwd Charge: ${_fwdChargeCtrl.text}"),
            pw.Text("GRAND TOTAL: ${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ]),
        ]),
      ],
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionLoading) {
          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        } else {
          if (state is TransactionSuccess || state is TransactionError) Navigator.of(context, rootNavigator: true).pop();
          if (state is TransactionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Saved Successfully!"), backgroundColor: Colors.green));
            _generatePdf().then((_) { if (mounted) _resetForm(); });
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ${state.message}"), backgroundColor: Colors.red));
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A252F),
          toolbarHeight: isMobile ? 140 : 110,
          title: Column(children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.isSales ? "SALES TERMINAL" : "PURCHASE TERMINAL", style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
                Row(children: [_stat("PCS", totalPcs.toInt().toString()), _stat("TAXABLE", taxableAmt.toStringAsFixed(2)), _stat("GST", totalTax.toStringAsFixed(2))]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("GRAND TOTAL", style: TextStyle(fontSize: 8, color: Colors.white70)),
              ]),
            ]),
            const Divider(color: Colors.white24, height: 10),
            Row(children: [
              Expanded(child: Text("WORDS: ${_amtInWordsCtrl.text} RUPEES ONLY.", style: const TextStyle(fontSize: 9, color: Colors.white70, overflow: TextOverflow.ellipsis))),
              _tfAppBar(_fwdChargeCtrl, "FWD CHARGE"),
            ]),
          ]),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            _section("SECTION 1: INVOICE DETAILS", _buildInvoiceSection(isMobile)),
            _section("SECTION 2: PARTY DETAILS", _buildMasterSection(isMobile)),
            _section("SECTION 4: PRODUCT ENTRY", _buildProductGrid(isMobile)),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ]),
        ),
      ),
    );
  }

  // --- Sub-Sections with Responsiveness ---
  Widget _buildInvoiceSection(bool isMobile) => Column(children: [
    _row(isMobile, [
      _tf(_billNoCtrl, "BILL NO", isNum: true),
      _dateTf(_billDateCtrl, "ENTER DATE"),
      _tf(_dueDaysCtrl, "DUE DAYS", isNum: true),
    ]),
    const SizedBox(height: 8),
    _row(isMobile, [
      _tf(_poNoCtrl, "PO NO"),
      _dateTf(_poDateCtrl, "ENTER PO DATE"),
      _tf(_dcNoCtrl, "DC NO"),
      _dateTf(_dcDateCtrl, "ENTER DC DATE"),
    ]),
    const SizedBox(height: 8), _tf(_pkgCtrl, "NO OF PACKAGE"),
  ]);

  Widget _buildMasterSection(bool isMobile) => Column(children: [
    _masterDropdown(),
    const SizedBox(height: 10),
    _row(isMobile, [
      _tf(_addrCtrl, "ADDRESS", readOnly: true),
      _tf(_cityCtrl, "CITY", readOnly: true),
      _tf(_pinCtrl, "PIN", readOnly: true),
    ]),
    const SizedBox(height: 10),
    _row(isMobile, [
      _tf(_gstNoCtrl, "GST NUMBER", readOnly: true),
      _tf(_accNoCtrl, "ACCOUNT NUMBER", readOnly: true),
    ]),
    const SizedBox(height: 8), _tf(_shipAddrCtrl, "SHIPPING ADDRESS"),
  ]);

  Widget _buildProductGrid(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        ...rows.asMap().entries.map((e) => _buildMobileProductCard(e.key)),
        _addLineBtn(),
      ]);
    }
    return Column(children: [
      Container(padding: const EdgeInsets.all(8), color: const Color(0xFF34495E), child: const Row(children: [
        SizedBox(width: 25, child: Text("SL", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 3, child: Text("PRODUCT", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("UOM", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("HSN", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("QTY", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("RATE", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("CGST%", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("SGST%", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 1, child: Text("IGST%", style: TextStyle(color: Colors.white, fontSize: 9))),
        Expanded(flex: 2, child: Text("TOTAL", style: TextStyle(color: Colors.white, fontSize: 9))),
        SizedBox(width: 30),
      ])),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        itemBuilder: (ctx, i) => _itemRowDesktop(i),
      ),
      _addLineBtn(),
    ]);
  }

  Widget _buildMobileProductCard(int i) {
    final r = rows[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("ITEM #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => rows.removeAt(i))),
        ]),
        _tf(r.productCtrl, "PRODUCT"),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _uomDropdown(i)), const SizedBox(width: 8), Expanded(child: _tf(r.hsnCtrl, "HSN"))]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _tf(r.qtyCtrl, "QTY", isNum: true, onCh: (v) => _calculateTotals())),
          const SizedBox(width: 8),
          Expanded(child: _tf(r.rateCtrl, "RATE", isNum: true, onCh: (v) => _calculateTotals())),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _tf(r.cgstPCtrl, "CGST%", isNum: true, onCh: (v) => _calculateTotals())),
          const SizedBox(width: 8),
          Expanded(child: _tf(r.sgstPCtrl, "SGST%", isNum: true, onCh: (v) => _calculateTotals())),
          const SizedBox(width: 8),
          Expanded(child: _tf(r.igstPCtrl, "IGST%", readOnly: true)),
        ]),
        const SizedBox(height: 8),
        _tf(r.lineTotalCtrl, "TOTAL AMOUNT", readOnly: true),
      ])),
    );
  }

  Widget _itemRowDesktop(int i) {
    final r = rows[i];
    return Row(children: [
      SizedBox(width: 25, child: Text("${i + 1}", style: const TextStyle(fontSize: 10))),
      Expanded(flex: 3, child: _gridTf(r.productCtrl, "Item")),
      Expanded(flex: 1, child: _uomDropdown(i)),
      Expanded(flex: 1, child: _gridTf(r.hsnCtrl, "HSN")),
      Expanded(flex: 1, child: _gridTf(r.qtyCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.rateCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.cgstPCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.sgstPCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
      Expanded(flex: 1, child: _gridTf(r.igstPCtrl, "0", readOnly: true)),
      Expanded(flex: 2, child: _gridTf(r.lineTotalCtrl, "0", readOnly: true)),
      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
    ]);
  }

  // --- UI Helpers ---
  Widget _row(bool isMobile, List<Widget> children) => isMobile ? Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList()) : Row(children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList());


  Widget _tf(TextEditingController c, String l, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => TextFormField(
    controller: c,
    readOnly: readOnly,
    onChanged: onCh,
    textInputAction: TextInputAction.next,
    onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length),

    // YAHAN CHANGE HAI: Number keyboard aur restrict input
    keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    inputFormatters: isNum ? [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Sirf numbers aur ek decimal allow karega
    ] : null,

    style: const TextStyle(fontSize: 11),
    decoration: InputDecoration(
        labelText: l,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null
    ),
  );

  Widget _dateTf(TextEditingController c, String l) => TextFormField(
    controller: c, readOnly: true, onTap: () => _selectDate(context, c),
    style: const TextStyle(fontSize: 11), decoration: InputDecoration(labelText: l, prefixIcon: const Icon(Icons.calendar_today, size: 14), border: const OutlineInputBorder(), isDense: true),
  );

  Widget _gridTf(TextEditingController c, String h, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => TextFormField(
    controller: c,
    readOnly: readOnly,
    onChanged: onCh,
    textInputAction: TextInputAction.next,
    onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length),

    // Number validation
    keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    inputFormatters: isNum ? [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ] : null,

    style: const TextStyle(fontSize: 11),
    decoration: InputDecoration(hintText: h, border: InputBorder.none, isDense: true),
  );

  Widget _stat(String l, String v) => Padding(padding: const EdgeInsets.only(right: 12), child: Column(children: [Text(l, style: const TextStyle(fontSize: 8, color: Colors.white54)), Text(v, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))]));

  Widget _tfAppBar(TextEditingController c, String l) => SizedBox(width: 100, height: 40, child: TextField(controller: c, onChanged: (v)=>_calculateTotals(), style: const TextStyle(color: Colors.yellowAccent, fontSize: 13), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white70, fontSize: 9), filled: true, fillColor: Colors.black, border: const OutlineInputBorder())));

  Widget _addLineBtn() => TextButton.icon(onPressed: () => setState(() => rows.add(TransactionRowController(sno: rows.length + 1))), icon: const Icon(Icons.add_circle), label: const Text("ADD LINE"));

  Widget _buildActionButtons() => Center(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, minimumSize: const Size(250, 45)), onPressed: _dispatchSave, icon: const Icon(Icons.print), label: const Text("SAVE & PRINT INVOICE")));

  Widget _section(String t, Widget c) => Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const Divider(), c])));

  // --- Keep Original Bloc Dropdowns ---
  Widget _masterDropdown() {
    return widget.isSales
        ? BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final List<CustomerEntity> list = (state is CustomerLoaded) ? state.customers : [];
        return DropdownButtonFormField<CustomerEntity>(
          value: _selectedMasterId == null ? null : list.where((e) => e.id == _selectedMasterId).firstOrNull,
          decoration: const InputDecoration(labelText: "SELECT CUSTOMER", border: OutlineInputBorder(), isDense: true),
          items: list.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: (v) { if (v != null) setState(() { _selectedMasterId = v.id; _nameCtrl.text = v.name; _addrCtrl.text = v.address ?? ""; _cityCtrl.text = v.city ?? ""; _pinCtrl.text = v.pincode ?? ""; _gstNoCtrl.text = v.gstNo ?? ""; _accNoCtrl.text = "NA"; }); },
        );
      },
    ) : BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        final List<SupplierEntity> list = (state is SupplierLoaded) ? state.suppliers : [];
        return DropdownButtonFormField<SupplierEntity>(
          value: _selectedMasterId == null ? null : list.where((e) => e.id == _selectedMasterId).firstOrNull,
          decoration: const InputDecoration(labelText: "SELECT SUPPLIER", border: OutlineInputBorder(), isDense: true),
          items: list.map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: (v) { if (v != null) setState(() { _selectedMasterId = v.id; _nameCtrl.text = v.name; _addrCtrl.text = v.address ?? ""; _cityCtrl.text = v.city ?? ""; _pinCtrl.text = v.pinCode ?? ""; _gstNoCtrl.text = v.gstNumber ?? ""; _accNoCtrl.text = v.accountNo ?? ""; }); },
        );
      },
    );
  }

  Widget _uomDropdown(int i) {
    return BlocBuilder<UomBloc, UomState>(
      builder: (context, state) {
        final List<UomEntity> list = (state is UomLoaded) ? state.uoms : [];
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: rows[i].selectedUom, isExpanded: true, hint: const Text("UOM", style: TextStyle(fontSize: 10)),
            items: list.map((u) => DropdownMenuItem(value: u.uomName, child: Text(u.uomName, style: const TextStyle(fontSize: 10)))).toList(),
            onChanged: (v) => setState(() => rows[i].selectedUom = v),
          ),
        );
      },
    );
  }
}
