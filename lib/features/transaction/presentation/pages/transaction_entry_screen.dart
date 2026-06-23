import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_management/features/transaction/presentation/pages/salse_invoice_pdf_generation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/customer_master_screen.dart';
import '../../../masters/presentation/pages/supplier_master_screen.dart';
import '../../../masters/presentation/pages/uom_master_screen.dart';

// ==========================================================================
// 1. REPOSITORY LAYER (100% Intact)
// ==========================================================================
class TransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> saveTransaction(Map<String, dynamic> data, bool isSales) async {
    final endpoint = isSales
        ? '/api/transactions/salse_transaction/'
        : '/api/transactions/purchase_transaction/';

    final response = await apiClient.post(endpoint, data: data);
    print("transaction response data:$response");
    return response.data as Map<String, dynamic>;
  }
}

// ==========================================================================
// 2. BLOC LAYER (100% Intact)
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
class TransactionSuccess extends TransactionState {
  final Map<String, dynamic> responseData;
  TransactionSuccess(this.responseData);
}
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
        final Map<String, dynamic> savedResponse = await repository.saveTransaction(event.data, event.isSales);
        print("invoice response: $savedResponse");
        if (!isClosed) emit(TransactionSuccess(savedResponse));
      } catch (e) {
        if (!isClosed) emit(TransactionError(e.toString()));
      }
    });
  }
}

// ==========================================================================
// 3. ROW CONTROLLER (100% Intact with Custom Defaults)
// ==========================================================================
class TransactionRowController {
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

// ==========================================================================
// 4. MAIN TERMINAL SCREEN UI (Upgraded with Sequence Counters & String Pointers)
// ==========================================================================
class TransactionTerminalScreen extends StatefulWidget {
  final bool isSales;
  const TransactionTerminalScreen({super.key, required this.isSales});

  @override
  State<TransactionTerminalScreen> createState() => _TransactionTerminalScreenState();
}

class _TransactionTerminalScreenState extends State<TransactionTerminalScreen> {
  final _billNoCtrl = TextEditingController(); // 🌟 Re-mapped targeting controller
  final _billDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _poNoCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _dcNoCtrl = TextEditingController();
  final _dcDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _pkgCtrl = TextEditingController();
  final _dueDaysCtrl = TextEditingController(text: "0");
  final _ewbNoCtrl = TextEditingController();
  final _dispatchCtrl = TextEditingController();
  String? _selectedTaxZone;

  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();
  final _shipAddrCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  final _fwdChargeCtrl = TextEditingController(text: "0");
  final _amtInWordsCtrl = TextEditingController(text: "ZERO RUPEES ONLY");
  double totalPcs = 0, taxableAmt = 0, totalTax = 0, grandTotal = 0, roundOff = 0;

  // Custom unique identifiers matrix tracking
  String? _selectedMasterType;
  int? _selectedMasterId;

  List<TransactionRowController> rows = [TransactionRowController(sno: 1)];

  @override
  void initState() {
    super.initState();
    _loadMasters();
    _fetchNextCommercialNumber(); // 👈 Initial sequence trigger preload
  }

  @override
  void dispose() {
    _billNoCtrl.dispose(); _billDateCtrl.dispose(); _poNoCtrl.dispose(); _poDateCtrl.dispose();
    _dcNoCtrl.dispose(); _dcDateCtrl.dispose(); _pkgCtrl.dispose(); _dueDaysCtrl.dispose();
    _ewbNoCtrl.dispose(); _dispatchCtrl.dispose(); _nameCtrl.dispose(); _addrCtrl.dispose();
    _cityCtrl.dispose(); _pinCtrl.dispose(); _gstNoCtrl.dispose(); _shipAddrCtrl.dispose();
    _accNoCtrl.dispose(); _bankNameCtrl.dispose(); _fwdChargeCtrl.dispose(); _amtInWordsCtrl.dispose();
    super.dispose();
  }

  // 🟢 NEW ACCURATE FEATURE: Preloads sequence counters from custom actions routers
  Future<void> _fetchNextCommercialNumber() async {
    try {
      final endpoint = widget.isSales
          ? '/api/transactions/salse_transaction/next_sales_number/'
          : '/api/transactions/purchase_transaction/next_purchase_number/';

      final response = await sl<ApiClient>().get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _billNoCtrl.text = widget.isSales
              ? response.data['next_sales_bill_no'].toString()
              : response.data['next_purchase_bill_no'].toString();
        });
      }
    } catch (e) {
      debugPrint("Commercial sequential numeric pre-load failed matrix block: $e");
    }
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

  void _loadMasters() {
    context.read<UomBloc>().add(LoadUoms());
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<SupplierBloc>().add(LoadSuppliers());
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

    double fwd = double.tryParse(_fwdChargeCtrl.text) ?? 0;
    double sub = a + tax + fwd;
    double roundedTotal = sub.roundToDouble();

    setState(() {
      totalPcs = p;
      taxableAmt = double.parse(a.toStringAsFixed(2));
      totalTax = double.parse(tax.toStringAsFixed(2));
      double rawRoundOff = roundedTotal - sub;
      roundOff = double.parse(rawRoundOff.toStringAsFixed(2));
      grandTotal = roundedTotal;
      _amtInWordsCtrl.text = "${_numToWords(grandTotal.toInt())} RUPEES ONLY";
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
      setState(() => controller.text = DateFormat('dd-MM-yyyy').format(picked));
    }
  }

  void _resetForm() {
    setState(() {
      _billDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _poNoCtrl.clear();
      _poDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _dcNoCtrl.clear();
      _dcDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _pkgCtrl.clear();
      _dueDaysCtrl.text = "0";
      _selectedMasterId = null;
      _selectedMasterType = null;
      _selectedTaxZone = null;
      _ewbNoCtrl.clear();
      _dispatchCtrl.clear();
      _nameCtrl.clear(); _addrCtrl.clear(); _cityCtrl.clear();
      _pinCtrl.clear(); _gstNoCtrl.clear(); _shipAddrCtrl.clear(); _accNoCtrl.clear();
      _bankNameCtrl.clear();
      _fwdChargeCtrl.text = "0"; _amtInWordsCtrl.text = "ZERO RUPEES ONLY";
      rows = [TransactionRowController(sno: 1)];
      totalPcs = 0; taxableAmt = 0; totalTax = 0; grandTotal = 0; roundOff = 0;
    });
    _fetchNextCommercialNumber(); // 👈 Reset counter preload hook
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
    if (_selectedTaxZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Critical Alert: Please specify State / Interstate Zone Selection!"), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedMasterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Party Profile!")));
      return;
    }
    final payload = {
      "billdate": _formatToBackendDate(_billDateCtrl.text),
      "purchase_order_no": _poNoCtrl.text,
      "purchase_order_date": _formatToBackendDate(_poDateCtrl.text),
      "dc_no": _dcNoCtrl.text,
      "dc_date": _formatToBackendDate(_dcDateCtrl.text),
      "no_of_package": _pkgCtrl.text,
      "due_date": int.tryParse(_dueDaysCtrl.text) ?? 0,
      "tax_zone": _selectedTaxZone,
      "name": _nameCtrl.text,
      "address": _addrCtrl.text,
      "ewb_no": _ewbNoCtrl.text,
      "dispatch": _dispatchCtrl.text,
      "city": _cityCtrl.text,
      "pin": _pinCtrl.text,
      "gst_number": _gstNoCtrl.text,
      "shipping_address": _shipAddrCtrl.text,
      "bank_name": _bankNameCtrl.text,
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

  Future<void> _generatePdf(Map<String, dynamic> savedData) async {
    try {
      final Uint8List logoBytes = (await rootBundle.load('assets/images/ultra_logo.jpeg')).buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

      List<String> copyHeadings = [];
      if (widget.isSales) {
        copyHeadings = ["ORIGINAL FOR BUYER", "TRANSPORT COPY", "ACKNOWLEDGEMENT COPY", "EXTRA COPY"];
      } else {
        copyHeadings = ["PURCHASE VOUCHER"];
      }

      final pdf = await InvoicePdfService.generate(
        logoImage: logoImage,
        data: savedData,
        isSales: widget.isSales,
        headings: copyHeadings,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${widget.isSales ? "Sales" : "Purchase"}_${savedData['billno']}.pdf',
      );
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 1000;
    final Color terminalThemeColor = widget.isSales ? const Color(0xFF1A252F) : const Color(0xFF2E4053);

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionLoading) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator())
          );
        } else {
          if (state is TransactionSuccess || state is TransactionError) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          if (state is TransactionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Saved Successfully!"), backgroundColor: Colors.green)
            );
            _generatePdf(state.responseData).then((_) {
              if (mounted) _resetForm();
            });
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ ${state.message}"), backgroundColor: Colors.red)
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: terminalThemeColor,
          toolbarHeight: isMobile ? 140 : 90,
          title: isMobile
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.isSales ? "SALES TERMINAL" : "PURCHASE TERMINAL", style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("GRAND TOTAL", style: TextStyle(fontSize: 7, color: Colors.white70)),
              ]),
            ]),
            const SizedBox(height: 6),
            Row(children: [_stat("PCS", totalPcs.toInt().toString()), _stat("TAXABLE", taxableAmt.toStringAsFixed(2)), _stat("GST", totalTax.toStringAsFixed(2))]),
          ])
              : Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.isSales ? "COMMERCIAL SALES TERMINAL" : "COMMERCIAL PURCHASE TERMINAL", style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [_stat("TOTAL PCS", totalPcs.toInt().toString()), _stat("TAXABLE NET", taxableAmt.toStringAsFixed(2)), _stat("COMPOUND GST", totalTax.toStringAsFixed(2))]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("NET PAYABLE VALUE", style: TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            isMobile
                ? Column(children: [
              _section("SECTION 1: TRANSACTION METADATA", _buildInvoiceSection(true)),
              _section("SECTION 2: ACCOUNT / PARTY CONFIGURATION", _buildMasterSection(true)),
            ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _section("SECTION 1: TRANSACTION METADATA", _buildInvoiceSection(false))),
              const SizedBox(width: 12),
              Expanded(child: _section("SECTION 2: ACCOUNT / PARTY CONFIGURATION", _buildMasterSection(false))),
            ]),
            _section("SECTION 3: QUANTITY MATRIX PRODUCT ENTRY", _buildProductGrid(isMobile)),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: const Color(0xFF1A252F),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Expanded(child: Text("VALUE IN WORDS: ${_amtInWordsCtrl.text}", style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500))),
                  const SizedBox(width: 20),
                  _tfAppBar(_fwdChargeCtrl, "FWD CHARGE"),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ]),
        ),
      ),
    );
  }

  Widget _buildInvoiceSection(bool isMobile) => Column(children: [
    Row(children: [
      // 🌟 PRELOAD INDICATOR ATTACHED: displays tracking integer series cleanly
      Expanded(child: _tf(_billNoCtrl, widget.isSales ? "SALES VOUCHER NO (AUTO)" : "PURCHASE VOUCHER NO (AUTO)", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_billDateCtrl, "TRANSACTION DATE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_poNoCtrl, "PO NO")),
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_poDateCtrl, "PO DATE")),
    ]),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(
      value: _selectedTaxZone,
      decoration: const InputDecoration(labelText: "SELECT STATE ZONE APPLICABILITY", labelStyle: TextStyle(fontSize: 11), border: OutlineInputBorder(), isDense: true, fillColor: Colors.white, filled: true),
      hint: const Text("Choose Option (Mandatory Entry Row)", style: TextStyle(fontSize: 11, color: Colors.redAccent)),
      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
      items: const [
        DropdownMenuItem(value: "STATE", child: Text("INTRASTATE (LOCAL STATE CGST + SGST ROUTING)")),
        DropdownMenuItem(value: "INTERSTATE", child: Text("INTERSTATE (CROSS BORDER IGST ROUTING)")),
      ],
      onChanged: (val) => setState(() => _selectedTaxZone = val),
    ),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_dcNoCtrl, "CHALLAN / DC NO")),
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_dcDateCtrl, "CHALAN / DC DATE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_pkgCtrl, "TOTAL NO OF PACKAGES")),
      const SizedBox(width: 8),
      Expanded(child: _tf(_dispatchCtrl, "VEHICLE NO / DISPATCH MODE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_dueDaysCtrl, "DUE DAYS", isNum: true)),
      const SizedBox(width: 8),
      Expanded(child: _tf(_ewbNoCtrl, "E-WAY BILL NO (EWB NO)", isNum: true)),
    ]),
  ]);

  Widget _buildMasterSection(bool isMobile) => Column(children: [
    _masterDropdown(),
    const SizedBox(height: 10),
    _tf(_addrCtrl, "ADDRESS", readOnly: true),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(flex: 2, child: _tf(_cityCtrl, "CITY", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(flex: 1, child: _tf(_pinCtrl, "POSTAL PINCODE", readOnly: true)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_gstNoCtrl, "PARTY GSTIN NO", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(child: _tf(_bankNameCtrl, "BANK IDENTIFIER NAME", readOnly: true)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_accNoCtrl, "BANK ACCOUNT NO", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(child: _tf(_shipAddrCtrl, "SHIPPING ADDRESS")),
    ]),
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
        SizedBox(width: 30, child: Text("SL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 4, child: Text("MATERIAL PRODUCT DESCRIPTION", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("UOM", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("HSN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("QTY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("RATE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("CGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("SGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("IGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("COMPOUND TOTAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        SizedBox(width: 35),
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
          Text("MATERIAL ROW ITEM #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
        ]),
        _tf(r.productCtrl, "MATERIAL PRODUCT DESCRIPTION"),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _uomDropdown(i)), const SizedBox(width: 8), Expanded(child: _tf(r.hsnCtrl, "HSN CODE"))]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _tf(r.qtyCtrl, "QUANTITY", isNum: true, onCh: (v) => _calculateTotals())),
          const SizedBox(width: 8),
          Expanded(child: _tf(r.rateCtrl, "UNIT RATE", isNum: true, onCh: (v) => _calculateTotals())),
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
        _tf(r.lineTotalCtrl, "ROW NET TOTAL AMOUNT", readOnly: true),
      ])),
    );
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
        Expanded(flex: 2, child: _gridTf(r.lineTotalCtrl, "0.00", readOnly: true)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
      ]),
    );
  }

  Widget _tf(TextEditingController c, String l, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => TextFormField(
    controller: c, readOnly: readOnly, onChanged: onCh, textInputAction: TextInputAction.next,
    onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length),
    keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10), border: const OutlineInputBorder(), isDense: true, filled: readOnly, fillColor: readOnly ? Colors.grey.shade100 : Colors.white),
  );

  Widget _dateTf(TextEditingController c, String l) => TextFormField(
    controller: c, readOnly: true, onTap: () => _selectDate(context, c),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10), prefixIcon: const Icon(Icons.calendar_today, size: 12), border: const OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
  );

  Widget _gridTf(TextEditingController c, String h, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2.0),
    child: TextFormField(
      controller: c, readOnly: readOnly, onChanged: onCh, textInputAction: TextInputAction.next,
      onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length),
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black),
      decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(fontSize: 10), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), isDense: true, filled: readOnly, fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white),
    ),
  );

  Widget _stat(String l, String v) => Padding(padding: const EdgeInsets.only(right: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.w500)), Text(v, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))]));

  Widget _tfAppBar(TextEditingController c, String l) => SizedBox(width: 120, height: 35, child: TextField(controller: c, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))], keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v)=>_calculateTotals(), style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white70, fontSize: 9), filled: true, fillColor: Colors.black26, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8))));

  Widget _addLineBtn() => Padding(
    padding: const EdgeInsets.only(top: 6.0),
    child: ElevatedButton.icon(onPressed: () => setState(() => rows.add(TransactionRowController(sno: rows.length + 1))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), icon: const Icon(Icons.add, size: 14), label: const Text("ADD NEW MATERIAL ROW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
  );

  Widget _buildActionButtons() => Center(
      child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], foregroundColor: Colors.white, minimumSize: const Size(320, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), elevation: 2),
          onPressed: _dispatchSave,
          icon: const Icon(Icons.print_rounded, size: 16),
          label: Text("SAVE & PRINT ${widget.isSales ? 'SALES' : 'PURCHASE'} VOUCHER", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
      )
  );

  Widget _section(String t, Widget c) => Card(elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)), color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))), const Divider(height: 16), c])));

  // 🌟 SAFE UNIQUE POINTER MATCH DROPDOWN
  Widget _masterDropdown() {
    return widget.isSales
        ? BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
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
          decoration: const InputDecoration(labelText: "SELECT CUSTOMER (COMMERCIAL INVOICING) *", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
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
                _accNoCtrl.text = match.accountNo ?? "NA";
                _bankNameCtrl.text = match.bankName ?? "N/A";
                _calculateTotals();
              });
            }
          },
        );
      },
    ) : BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
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
          decoration: const InputDecoration(labelText: "SELECT SUPPLIER (VOUCHERS ORIGIN) *", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
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
                _accNoCtrl.text = match.accountNo ?? "";
                _bankNameCtrl.text = match.bankName ?? "N/A";
                _calculateTotals();
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4), color: Colors.white),
          height: 28,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: rows[i].selectedUom, isExpanded: true, hint: const Text("UOM", style: TextStyle(fontSize: 10)),
              items: list.map((u) => DropdownMenuItem(value: u.uomName, child: Text(u.uomName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)))).toList(),
              onChanged: (v) => setState(() => rows[i].selectedUom = v),
            ),
          ),
        );
      },
    );
  }
}