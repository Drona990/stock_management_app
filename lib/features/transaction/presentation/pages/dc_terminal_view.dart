
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_management/features/transaction/presentation/pages/dc_invoice_pdf_generator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../masters/presentation/pages/customer_master_screen.dart';
import '../../../masters/presentation/pages/supplier_master_screen.dart';
import '../../../masters/presentation/pages/uom_master_screen.dart';

class UnifiedTransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> saveTransaction({
    required Map<String, dynamic> data,
    required String terminalMode,
  }) async {
    String endpoint = '';
    if (terminalMode == 'PROFORMA') {
      endpoint = '/api/transactions/proforma_invoice/';
    } else {
      endpoint = '/api/transactions/delivery_challan/';
    }

    final response = await apiClient.post(endpoint, data: data);
    print("$terminalMode transaction response data: $response");
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchTransactionHistory({
    required String terminalMode,
    String? search,
  }) async {
    try {
      String endpoint = terminalMode == 'PROFORMA'
          ? '/api/transactions/proforma_invoice/'
          : '/api/transactions/delivery_challan/';

      final Map<String, dynamic> queryParams = {};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (terminalMode != 'PROFORMA') {
        queryParams['dc_type'] = terminalMode;
      }

      final response = await apiClient.get(endpoint, query: queryParams);
      print("History Query Execution Response matrix ($terminalMode): ${response.data}");

      if (response.data == null) return [];

      if (response.data is Map) {
        final Map<String, dynamic> bodyMap = response.data as Map<String, dynamic>;
        if (bodyMap.containsKey('results') && bodyMap['results'] != null) {
          return bodyMap['results'] as List<dynamic>;
        }
        return [];
      }

      if (response.data is List) {
        return response.data as List<dynamic>;
      }

      return [];
    } catch (e) {
      print("Repository caught history fetch error safety interceptor: $e");
      return [];
    }
  }
}

// BLoC Architecture Classes
abstract class UnifiedTxEvent {}
class SaveUnifiedTxEvent extends UnifiedTxEvent {
  final Map<String, dynamic> data;
  final String terminalMode;
  SaveUnifiedTxEvent(this.data, this.terminalMode);
}
class LoadUnifiedHistoryEvent extends UnifiedTxEvent {
  final String terminalMode;
  final String? search;
  LoadUnifiedHistoryEvent({required this.terminalMode, this.search});
}

abstract class UnifiedTxState {}
class UnifiedTxInitial extends UnifiedTxState {}
class UnifiedTxLoading extends UnifiedTxState {}
class UnifiedTxSuccess extends UnifiedTxState {
  final Map<String, dynamic> responseData;
  UnifiedTxSuccess(this.responseData);
}
class UnifiedHistoryLoadedState extends UnifiedTxState {
  final List<dynamic> recordsList;
  UnifiedHistoryLoadedState(this.recordsList);
}
class UnifiedTxError extends UnifiedTxState {
  final String message;
  UnifiedTxError(this.message);
}

class UnifiedTxBloc extends Bloc<UnifiedTxEvent, UnifiedTxState> {
  final UnifiedTransactionRepository repository;

  UnifiedTxBloc(this.repository) : super(UnifiedTxInitial()) {
    on<SaveUnifiedTxEvent>((event, emit) async {
      emit(UnifiedTxLoading());
      try {
        final savedResponse = await repository.saveTransaction(
          data: event.data,
          terminalMode: event.terminalMode,
        );
        if (!isClosed) emit(UnifiedTxSuccess(savedResponse));
      } catch (e) {
        if (!isClosed) emit(UnifiedTxError(e.toString()));
      }
    });

    on<LoadUnifiedHistoryEvent>((event, emit) async {
      emit(UnifiedTxLoading());
      try {
        final List<dynamic> historyData = await repository.fetchTransactionHistory(
          terminalMode: event.terminalMode,
          search: event.search,
        );

        print("dc history data $historyData");
        if (!isClosed) emit(UnifiedHistoryLoadedState(historyData));
      } catch (e) {
        if (!isClosed) emit(UnifiedTxError("Failed to synchronize inventory directory data trail: $e"));
      }
    });
  }
}

class UnifiedRowController {
  int sno;
  final productCtrl = TextEditingController();
  final hsnCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "0");
  final rateCtrl = TextEditingController(text: "0");
  final cgstPCtrl = TextEditingController(text: "0");
  final sgstPCtrl = TextEditingController(text: "0");
  final igstPCtrl = TextEditingController(text: "0");
  final lineTotalCtrl = TextEditingController(text: "0.00");
  final remarksCtrl = TextEditingController(text: "");
  String? selectedUom;

  UnifiedRowController({required this.sno});

  void calculate({required bool isProformaMode}) {
    double q = double.tryParse(qtyCtrl.text) ?? 0;
    double r = double.tryParse(rateCtrl.text) ?? 0;
    double baseAmt = q * r;

    if (isProformaMode) {
      double cP = double.tryParse(cgstPCtrl.text) ?? 0;
      double sP = double.tryParse(sgstPCtrl.text) ?? 0;
      double iP = cP + sP;
      igstPCtrl.text = iP.toStringAsFixed(0);

      double taxAmt = (baseAmt * iP / 100);
      lineTotalCtrl.text = (baseAmt + taxAmt).toStringAsFixed(2);
    } else {
      cgstPCtrl.text = "0";
      sgstPCtrl.text = "0";
      igstPCtrl.text = "0";
      lineTotalCtrl.text = baseAmt.toStringAsFixed(2);
    }
  }
}

// ==========================================================================
// 💻 MAIN TERMINAL INTERFACE UI (DUAL COPY CAPABILITY LOADED)
// ==========================================================================
class DynamicTerminalScreen extends StatefulWidget {
  const DynamicTerminalScreen({super.key});

  @override
  State<DynamicTerminalScreen> createState() => _DynamicTerminalScreenState();
}

class _DynamicTerminalScreenState extends State<DynamicTerminalScreen> {
  String _terminalMode = "INWARD";

  final _docNoCtrl = TextEditingController();
  final _docDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _poNoCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  final _pkgCtrl = TextEditingController();
  final _dueDaysCtrl = TextEditingController(text: "0");
  final _ewbNoCtrl = TextEditingController();
  final _dispatchCtrl = TextEditingController();

  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _gstNoCtrl = TextEditingController();
  final _shipAddrCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();

  final _fwdChargeCtrl = TextEditingController(text: "0");
  final _amtInWordsCtrl = TextEditingController(text: "ZERO RUPEES ONLY");
  double totalPcs = 0, taxableAmt = 0, totalTax = 0, grandTotal = 0, roundOff = 0;

  String? _selectedMasterType;
  int? _selectedMasterId;

  List<UnifiedRowController> rows = [UnifiedRowController(sno: 1)];

  @override
  void initState() {
    super.initState();
    _loadMasters();
    _fetchNextVoucherNumber(); // 👈 Initial serial preload matrix trigger
  }

  @override
  void dispose() {
    _docNoCtrl.dispose(); _docDateCtrl.dispose(); _poNoCtrl.dispose(); _poDateCtrl.dispose();
    _pkgCtrl.dispose(); _dueDaysCtrl.dispose(); _ewbNoCtrl.dispose(); _dispatchCtrl.dispose();
    _nameCtrl.dispose(); _addrCtrl.dispose(); _cityCtrl.dispose(); _pinCtrl.dispose();
    _gstNoCtrl.dispose(); _shipAddrCtrl.dispose(); _accNoCtrl.dispose(); _fwdChargeCtrl.dispose();
    _amtInWordsCtrl.dispose();
    super.dispose();
  }

  // 🟢 NEW FEATURE METHOD: Fetches next tracking counter dynamically across dynamic terminals states
  Future<void> _fetchNextVoucherNumber() async {
    try {
      if (_terminalMode == "PROFORMA") {
        final response = await sl<ApiClient>().get('/api/transactions/proforma_invoice/next_proforma_number/');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _docNoCtrl.text = response.data['next_pi_bill_no'].toString();
          });
        }
      } else {
        final response = await sl<ApiClient>().get(
          '/api/transactions/delivery_challan/next_dc_number/',
          query: {'dc_type': _terminalMode},
        );
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _docNoCtrl.text = response.data['next_dc_bill_no'].toString();
          });
        }
      }
    } catch (e) {
      debugPrint("Error pipeline syncing next sequence number parameter token: $e");
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
    context.read<SupplierBloc>().add(LoadSuppliers());
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  void _calculateTotals() {
    double p = 0, a = 0, tax = 0;
    bool isProformaMode = _terminalMode == "PROFORMA";

    for (var r in rows) {
      r.calculate(isProformaMode: isProformaMode);
      double q = double.tryParse(r.qtyCtrl.text) ?? 0;
      double rt = double.tryParse(r.rateCtrl.text) ?? 0;

      p += q;
      a += (q * rt);

      if (isProformaMode) {
        double rowTaxable = q * rt;
        double rowTaxPercent = double.tryParse(r.igstPCtrl.text) ?? 0;
        tax += (rowTaxable * rowTaxPercent / 100);
      }
    }

    double fwd = double.tryParse(_fwdChargeCtrl.text) ?? 0;
    double sub = a + tax + fwd;
    double roundedTotal = sub.roundToDouble();

    setState(() {
      totalPcs = p;
      taxableAmt = double.parse(a.toStringAsFixed(2));
      totalTax = isProformaMode ? double.parse(tax.toStringAsFixed(2)) : 0.0;
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
      _docNoCtrl.clear();
      _docDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _poNoCtrl.clear();
      _poDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
      _pkgCtrl.clear();
      _dueDaysCtrl.text = "0";
      _ewbNoCtrl.clear();
      _dispatchCtrl.clear();
      _selectedMasterId = null;
      _selectedMasterType = null;
      _nameCtrl.clear(); _addrCtrl.clear(); _cityCtrl.clear();
      _pinCtrl.clear(); _gstNoCtrl.clear(); _shipAddrCtrl.clear(); _accNoCtrl.clear();
      _fwdChargeCtrl.text = "0"; _amtInWordsCtrl.text = "ZERO RUPEES ONLY";
      rows = [UnifiedRowController(sno: 1)];
      totalPcs = 0; taxableAmt = 0; totalTax = 0; grandTotal = 0; roundOff = 0;
    });
    _fetchNextVoucherNumber(); // 👈 Re-fetches current sequential count after clearing form matrix
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Party Profile!")));
      return;
    }

    final payload = {
      "billdate": _formatToBackendDate(_docDateCtrl.text),
      "purchase_order_no": _poNoCtrl.text,
      "purchase_order_date": _formatToBackendDate(_poDateCtrl.text),
      "dc_no": _terminalMode != "PROFORMA" ? _docNoCtrl.text : "",
      "dc_date": _terminalMode != "PROFORMA" ? _formatToBackendDate(_docDateCtrl.text) : null,
      "ewb_no": _ewbNoCtrl.text,
      "dispatch": _dispatchCtrl.text,
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

      if (_selectedMasterType == "CUSTOMER") "customer": _selectedMasterId,
      if (_selectedMasterType == "SUPPLIER") "supplier": _selectedMasterId,
      if (_terminalMode != "PROFORMA") "dc_type": _terminalMode,

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
        "remarks": _terminalMode != "PROFORMA" ? r.remarksCtrl.text : "",
      }).toList(),
    };
    context.read<UnifiedTxBloc>().add(SaveUnifiedTxEvent(payload, _terminalMode));
  }

  Future<void> _generatePdf(Map<String, dynamic> savedData) async {
    try {
      final Uint8List logoBytes = (await rootBundle.load('assets/images/ultra_logo.jpeg')).buffer.asUint8List();
      final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

      List<String> printingCopiesHeadings = [];

      if (_terminalMode == 'PROFORMA') {
        printingCopiesHeadings = ["PROFORMA VOUCHER"];
      } else if (_terminalMode == 'INWARD') {
        printingCopiesHeadings = ["RETURNABLE", "NON RETURNABLE"];
      } else if (_terminalMode == 'OUTWARD') {
        printingCopiesHeadings = ["RETURNABLE", "NON RETURNABLE"];
      }

      final pdf = await InvoiceDCPdfService.generate(
        logoImage: logoImage,
        data: savedData,
        terminalMode: _terminalMode,
        headings: printingCopiesHeadings,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${_terminalMode}_${savedData['billno'] ?? savedData['dc_no'] ?? 'DOC'}.pdf',
      );
    } catch (e) {
      debugPrint("PDF Engine Runtime Error context execution safety breach: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 1000;
    bool isProformaMode = _terminalMode == "PROFORMA";

    Color screenHeaderColor = const Color(0xFF2C3E50);
    if (_terminalMode == "OUTWARD") screenHeaderColor = const Color(0xFFD97706);
    if (_terminalMode == "PROFORMA") screenHeaderColor = const Color(0xFF0F4C81);

    return BlocListener<UnifiedTxBloc, UnifiedTxState>(
      listener: (context, state) {
        if (state is UnifiedTxLoading) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator())
          );
        } else {
          if (state is UnifiedTxSuccess || state is UnifiedTxError) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (state is UnifiedTxSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Document Saved Successfully!"), backgroundColor: Colors.green)
            );
            _generatePdf(state.responseData).then((_) {
              if (mounted) _resetForm();
            });
          } else if (state is UnifiedTxError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ Error: ${state.message}"), backgroundColor: Colors.red)
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: screenHeaderColor,
          toolbarHeight: isMobile ? 120 : 70,
          title: isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_terminalMode == 'PROFORMA' ? 'PROFORMA' : 'DC'} TERMINAL",
                    style: const TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text("NET VALUE", style: TextStyle(fontSize: 7, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _terminalMode,
                    dropdownColor: screenHeaderColor,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: "INWARD", child: Text("DC INWARD")),
                      DropdownMenuItem(value: "OUTWARD", child: Text("DC OUTWARD")),
                      DropdownMenuItem(value: "PROFORMA", child: Text("PROFORMA INVOICE")),
                    ],
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          _terminalMode = val;
                          _selectedMasterId = null;
                          _resetForm();
                          _loadMasters();
                        });
                        _fetchNextVoucherNumber(); // 👈 Refetches upcoming series count on state mutate
                      }
                    },
                  ),
                ),
              ),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_terminalMode == 'PROFORMA' ? 'PROFORMA INVOICE' : 'DELIVERY CHALLAN'} ENGINE TERMINAL",
                      style: const TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      _stat("TOTAL PCS", totalPcs.toInt().toString()),
                      _stat("BASE VALUE", taxableAmt.toStringAsFixed(2)),
                      if (isProformaMode) _stat("TOTAL TAX", totalTax.toStringAsFixed(2))
                    ]),
                  ],
                ),
              ),
              ToggleButtons(
                isSelected: [_terminalMode == "INWARD", _terminalMode == "OUTWARD", _terminalMode == "PROFORMA"],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) _terminalMode = "INWARD";
                    if (index == 1) _terminalMode = "OUTWARD";
                    if (index == 2) _terminalMode = "PROFORMA";
                    _selectedMasterId = null;
                    _resetForm();
                    _loadMasters();
                  });
                  _fetchNextVoucherNumber(); // 👈 Refetches upcoming series count on state mutate
                },
                borderRadius: BorderRadius.circular(4),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 100),
                selectedColor: Colors.white,
                fillColor: Colors.white24,
                children: const [
                  Text("DC INWARD", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("DC OUTWARD", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("PROFORMA", style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹ ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text("NET GRAND VALUE", style: TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            isMobile
                ? Column(children: [
              _section("SECTION 1: CONSIGNMENT METADATA", _buildInvoiceSection(true)),
              _section("SECTION 2: ACCOUNT / PARTY INFORMATION", _buildMasterSection(true)),
            ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _section("SECTION 1: CONSIGNMENT METADATA", _buildInvoiceSection(false))),
              const SizedBox(width: 12),
              Expanded(child: _section("SECTION 2: ACCOUNT / PARTY INFORMATION", _buildMasterSection(false))),
            ]),
            _section("SECTION 3: MATERIAL MATRIX GRID ENTRY", _buildProductGrid(isMobile)),

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
      // 🌟 DYNAMIC HEADER BINDING: Swaps text safely while pre-loading tracking integer counts
      Expanded(child: _tf(_docNoCtrl, _terminalMode == "PROFORMA" ? "PROFORMA SERIAL NO (AUTO)" : "CHALLAN / DC NUMERIC NO *", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_docDateCtrl, "DOCUMENT DATE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_poNoCtrl, "PO REFERENCE NO")),
      const SizedBox(width: 8),
      Expanded(child: _dateTf(_poDateCtrl, "PO REFERENCE DATE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_pkgCtrl, "TOTAL NO OF PACKAGES")),
      const SizedBox(width: 8),
      Expanded(child: _tf(_dispatchCtrl, "VEHICLE NO / DISPATCH MODE")),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_dueDaysCtrl, _terminalMode == "PROFORMA" ? "VALIDITY DAYS" : "CREDIT DUE DAYS", isNum: true)),
      const SizedBox(width: 8),
      Expanded(child: _terminalMode != "PROFORMA" ? _tf(_ewbNoCtrl, "E-WAY BILL NO (EWB)", isNum: true) : const SizedBox()),
    ]),
  ]);

  Widget _buildMasterSection(bool isMobile) => Column(children: [
    _masterDropdown(),
    const SizedBox(height: 10),
    _tf(_addrCtrl, "OFFICIAL BILLING ADDRESS", readOnly: true),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(flex: 2, child: _tf(_cityCtrl, "CITY", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(flex: 1, child: _tf(_pinCtrl, "POSTAL PINCODE", readOnly: true)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _tf(_gstNoCtrl, "PARTY GSTIN REFERENCE", readOnly: true)),
      const SizedBox(width: 8),
      Expanded(child: _tf(_accNoCtrl, "ACCOUNT REFERENCE NO", readOnly: true)),
    ]),
    const SizedBox(height: 10),
    _tf(_shipAddrCtrl, "DELIVERY SITE DESTINATION ADDRESS"),
  ]);

  Widget _buildProductGrid(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        ...rows.asMap().entries.map((e) => _buildMobileProductCard(e.key)),
        _addLineBtn(),
      ]);
    }

    bool isProformaMode = _terminalMode == "PROFORMA";

    return Column(children: [
      Container(padding: const EdgeInsets.all(8), color: const Color(0xFF34495E), child: Row(children: [
        const SizedBox(width: 30, child: Text("SL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        const Expanded(flex: 4, child: Text("MATERIAL DESCRIPTION", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        const Expanded(flex: 1, child: Text("UOM", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        const Expanded(flex: 1, child: Text("HSN", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        const Expanded(flex: 1, child: Text("QTY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        const Expanded(flex: 1, child: Text("RATE/VAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),

        if (isProformaMode) ...[
          const Expanded(flex: 1, child: Text("CGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
          const Expanded(flex: 1, child: Text("SGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
          const Expanded(flex: 1, child: Text("IGST%", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        ],

        const Expanded(flex: 2, child: Text("EXTENDED VAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        if (!isProformaMode) const Expanded(flex: 3, child: Text("REMARKS / DELIVERY PURPOSE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        const SizedBox(width: 35),
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
    bool isProformaMode = _terminalMode == "PROFORMA";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("LINE ITEM #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => setState(() { if(rows.length > 1) rows.removeAt(i); _calculateTotals(); })),
        ]),
        _tf(r.productCtrl, "MATERIAL DESCRIPTION"),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _uomDropdown(i)), const SizedBox(width: 8), Expanded(child: _tf(r.hsnCtrl, "HSN CODE"))]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _tf(r.qtyCtrl, "QUANTITY", isNum: true, onCh: (v) => _calculateTotals())),
          const SizedBox(width: 8),
          Expanded(child: _tf(r.rateCtrl, "UNIT VALUE", isNum: true, onCh: (v) => _calculateTotals())),
        ]),

        if (isProformaMode) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _tf(r.cgstPCtrl, "CGST %", isNum: true, onCh: (v) => _calculateTotals())),
            const SizedBox(width: 8),
            Expanded(child: _tf(r.sgstPCtrl, "SGST %", isNum: true, onCh: (v) => _calculateTotals())),
            const SizedBox(width: 8),
            Expanded(child: _tf(r.igstPCtrl, "IGST %", readOnly: true)),
          ]),
        ],
        if (!isProformaMode) ...[
          const SizedBox(height: 8),
          _tf(r.remarksCtrl, "REMARKS / CONSIGNMENT PURPOSE"),
        ],
        const SizedBox(height: 8),
        _tf(r.lineTotalCtrl, "TOTAL VALUE", readOnly: true),
      ])),
    );
  }

  Widget _itemRowDesktop(int i) {
    final r = rows[i];
    bool isProformaMode = _terminalMode == "PROFORMA";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(children: [
        SizedBox(width: 30, child: Text("${i + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        Expanded(flex: 4, child: _gridTf(r.productCtrl, "Item Description")),
        Expanded(flex: 1, child: _uomDropdown(i)),
        Expanded(flex: 1, child: _gridTf(r.hsnCtrl, "HSN")),
        Expanded(flex: 1, child: _gridTf(r.qtyCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),
        Expanded(flex: 1, child: _gridTf(r.rateCtrl, "0", isNum: true, onCh: (v)=>_calculateTotals())),

        if (isProformaMode) ...[
          Expanded(flex: 1, child: _gridTf(r.cgstPCtrl, "9", isNum: true, onCh: (v)=>_calculateTotals())),
          Expanded(flex: 1, child: _gridTf(r.sgstPCtrl, "9", isNum: true, onCh: (v)=>_calculateTotals())),
          Expanded(flex: 1, child: _gridTf(r.igstPCtrl, "18", readOnly: true)),
        ],

        Expanded(flex: 2, child: _gridTf(r.lineTotalCtrl, "0", readOnly: true)),
        if (!isProformaMode) Expanded(flex: 3, child: _gridTf(r.remarksCtrl, "Delivery Purpose")),
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
    child: ElevatedButton.icon(onPressed: () => setState(() => rows.add(UnifiedRowController(sno: rows.length + 1))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), icon: const Icon(Icons.add, size: 14), label: const Text("ADD NEW MATERIAL ROW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
  );

  Widget _buildActionButtons() {
    Color btnColor = const Color(0xFF16A085);
    if (_terminalMode == "PROFORMA") btnColor = const Color(0xFF2980B9);

    return Center(
        child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, minimumSize: const Size(320, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), elevation: 2),
            onPressed: _dispatchSave,
            icon: const Icon(Icons.print_rounded, size: 16),
            label: Text("SAVE & PRINT ${_terminalMode.toUpperCase()} VOUCHER", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        )
    );
  }

  Widget _section(String t, Widget c) => Card(elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)), color: Colors.white, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))), const Divider(height: 16), c])));

// 🌟 FIXED & FILTERED DROPDOWN ENGINE: Proforma mode locks to Customers only
  Widget _masterDropdown() {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, supplierState) {
        return BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, customerState) {
            final List<SupplierEntity> suppliers = (supplierState is SupplierLoaded) ? supplierState.suppliers : [];
            final List<CustomerEntity> customers = (customerState is CustomerLoaded) ? customerState.customers : [];

            final List<DropdownMenuItem<String>> masterItemsList = [];

            // 🟢 CONDITION APPLIED: Suppliers will be skipped completely if mode is PROFORMA
            if (_terminalMode != "PROFORMA") {
              for (var s in suppliers) {
                masterItemsList.add(DropdownMenuItem(
                  value: "SUPPLIER_${s.id}",
                  child: Text("[SUPPLIER] ${s.name.toUpperCase()}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ));
              }
            }

            // Customers always populate across all terminal modes matrix
            for (var c in customers) {
              masterItemsList.add(DropdownMenuItem(
                value: "CUSTOMER_${c.id}",
                child: Text("[CUSTOMER] ${c.name.toUpperCase()}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
              ));
            }

            // Compute safe matching String value
            String? selectedItemValueKey;
            if (_selectedMasterId != null && _selectedMasterType != null) {
              // Reset current selection safely if user switches to Proforma while a Supplier was selected
              if (_terminalMode == "PROFORMA" && _selectedMasterType == "SUPPLIER") {
                _selectedMasterId = null;
                _selectedMasterType = null;
                _nameCtrl.clear(); _addrCtrl.clear(); _cityCtrl.clear();
                _pinCtrl.clear(); _gstNoCtrl.clear(); _accNoCtrl.clear();
              } else {
                selectedItemValueKey = "${_selectedMasterType}_$_selectedMasterId";
              }
            }

            return DropdownButtonFormField<String>(
              value: selectedItemValueKey,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "SELECT TRANS-PARTY PROFILE (SUPPLIER / CUSTOMER) *", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.white),
              items: masterItemsList,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    final parts = v.split("_");
                    _selectedMasterType = parts[0];
                    _selectedMasterId = int.tryParse(parts[1]);

                    if (_selectedMasterType == "SUPPLIER") {
                      final s = suppliers.firstWhere((e) => e.id == _selectedMasterId);
                      _nameCtrl.text = s.name;
                      _addrCtrl.text = s.address ?? "";
                      _cityCtrl.text = s.city ?? "";
                      _pinCtrl.text = s.pinCode ?? "";
                      _gstNoCtrl.text = s.gstNumber ?? "";
                      _accNoCtrl.text = s.accountNo ?? "";
                    } else {
                      final c = customers.firstWhere((e) => e.id == _selectedMasterId);
                      _nameCtrl.text = c.name;
                      _addrCtrl.text = c.address;
                      _cityCtrl.text = c.city;
                      _pinCtrl.text = c.pincode;
                      _gstNoCtrl.text = c.gstNo;
                      _accNoCtrl.text = "NA";
                    }
                    _calculateTotals();
                  });
                }
              },
            );
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