import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/supplier_master_screen.dart';
import '../../../masters/presentation/pages/uom_master_screen.dart';
import '../../../reports/presentation/pages/purchase_order_history_page.dart';
import 'dc_invoice_pdf_generator.dart';

// =============================================================================
// REPOSITORY LAYER
// =============================================================================
class PurchaseOrderRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> savePurchaseOrder(Map<String, dynamic> data) async {
    final response = await apiClient.post('/api/transactions/purchase_order/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<int> fetchNextPoCounter() async {
    try {
      final response = await apiClient.get('/api/transactions/purchase_order/next_po_number/');
      if (response.statusCode == 200 && response.data != null) {
        return int.tryParse(response.data['next_po_bill_no'].toString()) ?? 1;
      }
      return 1;
    } catch (_) {
      return 1;
    }
  }

  Future<List<dynamic>> fetchPoHistoryRegistry({String? search}) async {
    try {
      final response = await apiClient.get('/api/transactions/purchase_order/', query: {
        if (search != null && search.isNotEmpty) 'search': search,
      });

      print("purchase order data $response");

      if (response.data is Map && response.data['results'] != null) {
        return response.data['results'] as List<dynamic>;
      }
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

// =============================================================================
// BLOC LAYER
// =============================================================================
abstract class PurchaseOrderEvent {}
class PreloadNextPoNumber extends PurchaseOrderEvent {}
class CommitPoSave extends PurchaseOrderEvent { final Map<String, dynamic> payload; CommitPoSave(this.payload); }
class LoadPoHistoryEvent extends PurchaseOrderEvent { final String? query; LoadPoHistoryEvent({this.query}); }

abstract class PurchaseOrderState {}
class PoInitial extends PurchaseOrderState {}
class PoLoading extends PurchaseOrderState {}
class PoPreloadingCounter extends PurchaseOrderState {}
class PoSavingInProgress extends PurchaseOrderState {}
class PoCounterLoaded extends PurchaseOrderState { final int nextPoNo; PoCounterLoaded(this.nextPoNo); }
class PoSaveSuccess extends PurchaseOrderState { final Map<String, dynamic> resData; PoSaveSuccess(this.resData); }
class PoHistoryLoadedState extends PurchaseOrderState { final List<dynamic> poList; PoHistoryLoadedState(this.poList); }
class PoFailure extends PurchaseOrderState { final String errorMsg; PoFailure(this.errorMsg); }

class PurchaseOrderBloc extends Bloc<PurchaseOrderEvent, PurchaseOrderState> {
  final PurchaseOrderRepository repo;

  PurchaseOrderBloc(this.repo) : super(PoInitial()) {
    on<PreloadNextPoNumber>((event, emit) async {
      emit(PoPreloadingCounter());
      try {
        final counter = await repo.fetchNextPoCounter();
        emit(PoCounterLoaded(counter));
      } catch (e) {
        emit(PoFailure(e.toString()));
      }
    });

    on<CommitPoSave>((event, emit) async {
      emit(PoSavingInProgress());
      try {
        final data = await repo.savePurchaseOrder(event.payload);
        emit(PoSaveSuccess(data));
      } catch (e) {
        emit(PoFailure(e.toString()));
      }
    });

    on<LoadPoHistoryEvent>((event, emit) async {
      emit(PoLoading());
      try {
        final history = await repo.fetchPoHistoryRegistry(search: event.query);
        emit(PoHistoryLoadedState(history));
      } catch (e) {
        emit(PoFailure(e.toString()));
      }
    });
  }
}

// =============================================================================
// ROW CONTROL LOGIC MATRIX
// =============================================================================
class PoRowController {
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

  PoRowController({required this.sno});

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

// =============================================================================
// INTERFACE CONTAINER ROOT
// =============================================================================
class PurchaseOrderTerminalScreen extends StatelessWidget {
  const PurchaseOrderTerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PurchaseOrderBloc>(
      create: (context) => PurchaseOrderBloc(sl<PurchaseOrderRepository>())..add(PreloadNextPoNumber()),
      child: const _PurchaseOrderTerminalFormView(),
    );
  }
}

class _PurchaseOrderTerminalFormView extends StatefulWidget {
  const _PurchaseOrderTerminalFormView();

  @override
  State<_PurchaseOrderTerminalFormView> createState() => _PurchaseOrderTerminalFormViewState();
}

class _PurchaseOrderTerminalFormViewState extends State<_PurchaseOrderTerminalFormView> {
  final _poNoCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _dueDaysCtrl = TextEditingController(text: "0");
  final _pkgCtrl = TextEditingController();
  final _dispatchCtrl = TextEditingController();
  String? _selectedTaxZone;

  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  final _fwdChargeCtrl = TextEditingController(text: "0");
  final _amtInWordsCtrl = TextEditingController(text: "ZERO RUPEES ONLY");
  double totalPcs = 0, taxableAmt = 0, totalTax = 0, grandTotal = 0, roundOff = 0;
  int? _selectedSupplierId;
  List<PoRowController> rows = [PoRowController(sno: 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UomBloc>().add(LoadUoms());
        context.read<SupplierBloc>().add(LoadSuppliers());
      }
    });
  }

  @override
  void dispose() {
    _poNoCtrl.dispose(); _poDateCtrl.dispose(); _dueDaysCtrl.dispose(); _pkgCtrl.dispose();
    _dispatchCtrl.dispose(); _nameCtrl.dispose(); _addrCtrl.dispose(); _cityCtrl.dispose();
    _pinCtrl.dispose(); _gstNoCtrl.dispose(); _termsCtrl.dispose(); _fwdChargeCtrl.dispose();
    _amtInWordsCtrl.dispose();
    super.dispose();
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
      totalPcs = p;
      taxableAmt = double.parse(a.toStringAsFixed(2));
      totalTax = double.parse(tax.toStringAsFixed(2));
      roundOff = double.parse((rounded - sub).toStringAsFixed(2));
      grandTotal = rounded;
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
      _poDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _dueDaysCtrl.text = "0"; _pkgCtrl.clear(); _dispatchCtrl.clear();
      _selectedSupplierId = null; _selectedTaxZone = null;
      _nameCtrl.clear(); _addrCtrl.clear(); _cityCtrl.clear(); _pinCtrl.clear(); _gstNoCtrl.clear(); _termsCtrl.clear();
      _fwdChargeCtrl.text = "0"; _amtInWordsCtrl.text = "ZERO RUPEES ONLY";
      rows = [PoRowController(sno: 1)];
      totalPcs = 0; taxableAmt = 0; totalTax = 0; grandTotal = 0; roundOff = 0;
    });
    context.read<PurchaseOrderBloc>().add(PreloadNextPoNumber());
  }

  void _onCommitSave() {
    if (_selectedTaxZone == null || _selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill Mandatory Supplier & Tax Fields!"), backgroundColor: Colors.orange));
      return;
    }
    final payload = {
      "billdate": DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(_poDateCtrl.text)),
      "due_date": int.tryParse(_dueDaysCtrl.text) ?? 0,
      "tax_zone": _selectedTaxZone,
      "name": _nameCtrl.text, "address": _addrCtrl.text, "city": _cityCtrl.text, "pin": _pinCtrl.text,
      "gst_number": _gstNoCtrl.text, "no_of_package": _pkgCtrl.text, "dispatch": _dispatchCtrl.text,
      "terms_conditions": _termsCtrl.text, "total_pcs": totalPcs, "totalamount": taxableAmt,
      "forwading_charge": double.tryParse(_fwdChargeCtrl.text) ?? 0,
      "cgst": totalTax / 2, "sgst": totalTax / 2, "igst": totalTax,
      "round_off": roundOff, "grand_totamt": grandTotal, "amtin_words": _amtInWordsCtrl.text,
      "supplier": _selectedSupplierId,
      "details": rows.map((r) => {
        "sno": r.sno, "product_name": r.productCtrl.text, "uom": r.selectedUom ?? "PCS", "hsncode": r.hsnCtrl.text,
        "qty": double.tryParse(r.qtyCtrl.text) ?? 0, "rate": double.tryParse(r.rateCtrl.text) ?? 0,
        "amount": (double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.rateCtrl.text) ?? 0),
        "cgst": double.tryParse(r.cgstPCtrl.text) ?? 0, "sgst": double.tryParse(r.sgstPCtrl.text) ?? 0,
        "igst": double.tryParse(r.igstPCtrl.text) ?? 0, "total": double.tryParse(r.lineTotalCtrl.text) ?? 0,
      }).toList(),
    };
    context.read<PurchaseOrderBloc>().add(CommitPoSave(payload));
  }

  Future<void> _triggerInstantPrint(Map<String, dynamic> generatedPo) async {
    try {
      final ByteData rawLogo = await rootBundle.load('assets/images/ultra_logo.jpeg');
      final pw.ImageProvider logoImage = pw.MemoryImage(rawLogo.buffer.asUint8List());

      final pdfDoc = await InvoiceDCPdfService.generate(
        logoImage: logoImage,
        data: generatedPo,
        terminalMode: "PO",
        headings: ["ORIGINAL HEAD OFFICE COPY", "VENDOR DUPLICATE TRACK REF", "ACCOUNTS EXTRA ARCHIVE"],
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfDoc.save(),
        name: 'PO_${generatedPo['po_bill_no'] ?? generatedPo['billno'] ?? 'VOUCHER'}.pdf',
      );
    } catch (e) {
      debugPrint("Printing Engine Matrix Runtime Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 1000;
    const Color poThemeColor = Color(0xFF111827);

    return BlocListener<PurchaseOrderBloc, PurchaseOrderState>(
      listener: (context, state) {
        if (state is PoSavingInProgress) {
          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(strokeWidth: 1.5)));
        } else {
          if (state is PoSaveSuccess || state is PoFailure) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          if (state is PoCounterLoaded) {
            setState(() => _poNoCtrl.text = state.nextPoNo.toString());
          }
          if (state is PoSaveSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Purchase Order Committed Successfully!"), backgroundColor: Colors.green));
            _triggerInstantPrint(state.resData).then((_) {
              if (mounted) _resetForm();
            });
          } else if (state is PoFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Operation Blocked: ${state.errorMsg}"), backgroundColor: Colors.red));
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: poThemeColor,
          toolbarHeight: isMobile ? 120 : 72,
          title: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("PURCHASE ORDER PLACEMENT ENGINE", style: TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [_statLabel("TOTAL QTY", totalPcs.toInt().toString()), _statLabel("TAXABLE VAL", taxableAmt.toStringAsFixed(2)), _statLabel("GST TOTAL", totalTax.toStringAsFixed(2))]),
            ])),
            ElevatedButton.icon(
              icon: const Icon(Icons.history_edu_sharp, size: 12),
              label: const Text("VIEW PO DIRECTORY HISTORY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white, shape: const RoundedRectangleBorder()),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseOrderHistoryPage())),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("ESTIMATED PROCUREMENT COST", style: TextStyle(fontSize: 7.5, color: Colors.white60, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            isMobile
                ? Column(children: [_section("SECTION 1: ORDER METADATA", _buildInvoiceSection()), _section("SECTION 2: SUPPLIER ALLOCATION", _buildMasterSection())])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _section("SECTION 1: ORDER METADATA", _buildInvoiceSection())),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: _section("SECTION 2: SUPPLIER ALLOCATION", _buildMasterSection())),
            ]),
            _section("SECTION 3: MATERIAL SPECIFICATION MATRIX ENTRY GRID", _buildProductGrid(isMobile)),
            Card(
              elevation: 1, color: const Color(0xFF1F2937),
              child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
                Expanded(child: _tfGrid(_termsCtrl, "Enter PO delivery clauses, specifications or logistics handling notes...", colorText: Colors.yellowAccent)),
                const SizedBox(width: 16),
                _tfAppBar(_fwdChargeCtrl, "ESTIMATED FREIGHT")
              ])),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white, minimumSize: const Size(360, 46), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              onPressed: _onCommitSave,
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
              label: const Text("GENERATE & COMMIT PURCHASE ORDER VOUCHER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildInvoiceSection() => Column(children: [
    Row(children: [
      Expanded(child: _tf(_poNoCtrl, "PO NUMERIC SERIAL NO (AUTO)", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(child: _tfDate(_poDateCtrl, "ORDER PLACEMENT DATE")),
    ]),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(
      value: _selectedTaxZone,
      decoration: const InputDecoration(labelText: "TAX MATRIX PREFERENCE APPLICABILITY *", border: OutlineInputBorder(borderRadius: BorderRadius.zero), isDense: true, filled: true, fillColor: Colors.white),
      style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
      items: const [
        DropdownMenuItem(value: "STATE", child: Text("INTRASTATE (LOCAL STATE CGST + SGST ROUTING)")),
        DropdownMenuItem(value: "INTERSTATE", child: Text("INTERSTATE (CROSS BORDER IGST ROUTING)")),
      ],
      onChanged: (val) => setState(() => _selectedTaxZone = val),
    ),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_dueDaysCtrl, "DELIVERY TIMELINE VALIDITY (DAYS)", isNum: true)),
      const SizedBox(width: 8),
      Expanded(child: _tf(_pkgCtrl, "EXPECTED LOGISTICS PACKAGES")),
    ]),
    const SizedBox(height: 10),
    _tf(_dispatchCtrl, "RECOMMENDED TRANSPORT ROUTING / VEHICLE SPEED TRANSIT MODE"),
  ]);

  Widget _buildMasterSection() => Column(children: [
    _supplierDropdownOnly(),
    const SizedBox(height: 10),
    _tf(_addrCtrl, "OFFICIAL BILLING HEADQUARTERS ADDRESS", readOnly: true),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(flex: 2, child: _tf(_cityCtrl, "CITY", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(flex: 1, child: _tf(_pinCtrl, "PINCODE", readOnly: true)),
    ]),
    const SizedBox(height: 10),
    _tf(_gstNoCtrl, "VENDOR COMPLIANCE REGISTERED GSTIN REFERENCE", readOnly: true),
  ]);

  Widget _supplierDropdownOnly() {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, supplierState) {
        List<SupplierEntity> itemsList = [];
        if (supplierState is SupplierLoaded) {
          itemsList = supplierState.suppliers;
        }
        return Container(
          height: 38,
          child: DropdownSearch<SupplierEntity>(
            items: (filter, loadProps) => itemsList,
            compareFn: (i, s) => i != null && s != null && i.id == s.id,
            itemAsString: (item) => item == null ? "" : item.name.toUpperCase(),
            onChanged: (v) {
              if (mounted && v != null) {
                setState(() {
                  _selectedSupplierId = v.id;
                  _nameCtrl.text = v.name;
                  _addrCtrl.text = v.address ?? "";
                  _cityCtrl.text = v.city ?? "";
                  _pinCtrl.text = v.pinCode ?? "";
                  _gstNoCtrl.text = v.gstNumber ?? "N/A";
                  _calculateTotals();
                });
              }
            },
            filterFn: (item, filter) => item != null && item.name.toLowerCase().contains(filter.toLowerCase()),
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(style: TextStyle(fontSize: 11), decoration: InputDecoration(hintText: "Search Registered Suppliers...", hintStyle: TextStyle(fontSize: 11), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.zero))),
              itemBuilder: (context, item, isSelected, isHovered) => ListTile(dense: true, title: Text(item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), subtitle: Text("GSTIN: ${item.gstNumber ?? 'N/A'}", style: const TextStyle(fontSize: 9, color: Colors.grey))),
            ),
            decoratorProps: const DropDownDecoratorProps(baseStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange), decoration: InputDecoration(labelText: "TARGET SYSTEM REGISTERED SUPPLIER PROFILES *", labelStyle: TextStyle(fontSize: 10), border: OutlineInputBorder(borderRadius: BorderRadius.zero), isDense: true, fillColor: Colors.white, filled: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8))),
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        ...rows.asMap().entries.map((e) => _buildMobileProductCard(e.key)),
        _addLineRowBtn(),
      ]);
    }
    return Column(children: [
      Container(padding: const EdgeInsets.all(6), color: const Color(0xFF374151), child: const Row(children: [
        SizedBox(width: 25, child: Text("SL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 4, child: Text("MATERIAL PROCUREMENT DESCRIPTION", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("UOM", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("HSN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("REQ QTY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("AGREED RATE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("CGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("SGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 1, child: Text("IGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("COMPOUND ROW VALUE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        SizedBox(width: 35),
      ])),
      ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: rows.length, itemBuilder: (ctx, i) => _itemRowDesktop(i)),
      _addLineRowBtn(),
    ]);
  }

  Widget _itemRowDesktop(int i) {
    final r = rows[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(children: [
        SizedBox(width: 25, child: Text("${i + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        Expanded(flex: 4, child: _tfGrid(r.productCtrl, "Enter Description")),
        Expanded(flex: 1, child: _uomDropdown(i)),
        Expanded(flex: 1, child: _tfGrid(r.hsnCtrl, "HSN")),
        Expanded(flex: 1, child: _tfGrid(r.qtyCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _tfGrid(r.rateCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _tfGrid(r.cgstPCtrl, "9", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _tfGrid(r.sgstPCtrl, "9", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _tfGrid(r.igstPCtrl, "18", readOnly: true)),
        Expanded(flex: 2, child: _tfGrid(r.lineTotalCtrl, "0.00", readOnly: true)),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
      ]),
    );
  }

  Widget _buildMobileProductCard(int i) {
    final r = rows[i];
    return Card(
      margin: const EdgeInsets.only(bottom: 8), color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("PO ROW ENTRY LINE #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 16), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
        ]),
        _tf(r.productCtrl, "Material Item Nomenclature particulars"),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: _uomDropdown(i)), const SizedBox(width: 6), Expanded(child: _tf(r.hsnCtrl, "HSN CODE"))]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _tf(r.qtyCtrl, "Procurement Quantity", isNum: true, onCh: (v)=>_calculateTotals())),
          const SizedBox(width: 6),
          Expanded(child: _tf(r.rateCtrl, "Negotiated Unit Rate", isNum: true, onCh: (v)=>_calculateTotals())),
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
        _tf(r.lineTotalCtrl, "Net Compound Matrix Value", readOnly: true),
      ])),
    );
  }

  Widget _uomDropdown(int i) {
    return BlocBuilder<UomBloc, UomState>(
      builder: (context, state) {
        final List<UomEntity> list = (state is UomLoaded) ? state.uoms : [];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.zero, color: Colors.white), height: 28,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: rows[i].selectedUom, isExpanded: true, hint: const Text("UOM", style: TextStyle(fontSize: 9)),
              items: list.map((u) => DropdownMenuItem(value: u.uomName, child: Text(u.uomName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)))).toList(),
              onChanged: (v) => setState(() => rows[i].selectedUom = v),
            ),
          ),
        );
      },
    );
  }

  Widget _tf(TextEditingController c, String l, {bool isNum = false, bool readOnly = false, Function(String)? onCh}) => TextFormField(controller: c, readOnly: readOnly, onChanged: onCh, textInputAction: TextInputAction.next, onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length), keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10), border: const OutlineInputBorder(borderRadius: BorderRadius.zero), isDense: true, filled: readOnly, fillColor: readOnly ? Colors.grey.shade100 : Colors.white));
  Widget _tfGrid(TextEditingController c, String h, {bool isNum = false, bool readOnly = false, Function(String)? onCh, Color colorText = Colors.black}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 1.0), child: TextFormField(controller: c, readOnly: readOnly, onChanged: onCh, textInputAction: TextInputAction.next, onTap: () => c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length), keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorText), decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(fontSize: 9, color: Colors.grey), border: const OutlineInputBorder(borderRadius: BorderRadius.zero), contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), isDense: true, filled: readOnly, fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white)));
  Widget _tfDate(TextEditingController c, String l) => TextFormField(controller: c, readOnly: true, onTap: () async { DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101)); if (p != null) setState(() => c.text = DateFormat('dd-MM-yyyy').format(p)); }, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), decoration: InputDecoration(labelText: l, labelStyle: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10), prefixIcon: const Icon(Icons.calendar_today, size: 11), border: const OutlineInputBorder(borderRadius: BorderRadius.zero), isDense: true, filled: true, fillColor: Colors.white));
  Widget _tfAppBar(TextEditingController c, String l) => SizedBox(width: 120, height: 35, child: TextField(controller: c, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))], keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v)=>_calculateTotals(), style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white70, fontSize: 9), filled: true, fillColor: Colors.black26, border: const OutlineInputBorder(borderRadius: BorderRadius.zero), contentPadding: const EdgeInsets.symmetric(horizontal: 8))));
  Widget _addLineRowBtn() => Padding(padding: const EdgeInsets.only(top: 4.0), child: ElevatedButton.icon(onPressed: () => setState(() => rows.add(PoRowController(sno: rows.length + 1))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)), icon: const Icon(Icons.add, size: 12), label: const Text("ADD NEW MATRIX MATERIAL ROW", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))));
  Widget _section(String t, Widget c) => Card(elevation: 1, margin: const EdgeInsets.only(bottom: 12), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))), const Divider(height: 14), c])));

  Widget _statLabel(String l, String v) => Padding(padding: const EdgeInsets.only(right: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 8, color: Colors.white70)), Text(v, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold))]));
}