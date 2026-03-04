import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/bill_printing_service.dart';
import '../../../../injection.dart';

class SaleItemEntity {
  final int bId;
  final String group, hsn, bCode;
  final double rate, amount, cgstAmt, sgstAmt, igstAmt, total;

  SaleItemEntity({
    required this.bId, required this.group, required this.hsn,
    required this.rate, required this.amount, required this.cgstAmt,
    required this.sgstAmt, required this.igstAmt, required this.total, required this.bCode,
  });

  factory SaleItemEntity.fromLookup(Map<String, dynamic> json, bool isInterState, String scannedCode) {
    double r = double.tryParse(json['rate']?.toString() ?? '0') ?? 0;
    double cRate = double.tryParse(json['cgst_rate']?.toString() ?? '0') ?? 0;
    double sRate = double.tryParse(json['sgst_rate']?.toString() ?? '0') ?? 0;

    double iRate = isInterState ? (cRate + sRate) : 0.0;
    if (isInterState) { cRate = 0.0; sRate = 0.0; }

    double taxTotal = cRate + sRate + iRate;
    double baseAmt = r / (1 + (taxTotal / 100));

    return SaleItemEntity(
      bId: json['barcode_id'] ?? 0,
      group: json['group_name'] ?? "Unknown",
      hsn: json['hsn'] ?? "",
      rate: r,
      amount: double.parse(baseAmt.toStringAsFixed(2)),
      cgstAmt: double.parse((baseAmt * (cRate / 100)).toStringAsFixed(2)),
      sgstAmt: double.parse((baseAmt * (sRate / 100)).toStringAsFixed(2)),
      igstAmt: double.parse((baseAmt * (iRate / 100)).toStringAsFixed(2)),
      total: r,
      bCode: scannedCode,
    );
  }
}

class SalesRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> lookupBarcode(String code) async {
    final response = await apiClient.get('/api/inventory/sales/lookup_barcode/', query: {'code': code});
    return response.data;
  }

  Future<Map<String, dynamic>> saveBill(Map<String, dynamic> billData) async {
    final response = await apiClient.post('/api/inventory/sales/', data: billData);
    return response.data;
  }
}

// ==========================================================================
// 3. PRESENTATION LAYER (BLoC)
// ==========================================================================
abstract class SalesEvent {}
class ScanBarcode extends SalesEvent { final String code; ScanBarcode(this.code); }
class RemoveItem extends SalesEvent { final int index; RemoveItem(this.index); }
class ToggleTaxType extends SalesEvent { final bool isInterState; ToggleTaxType(this.isInterState); }
class FinalizeBill extends SalesEvent { final Map<String, dynamic> billData; FinalizeBill(this.billData); }

abstract class SalesState {}
class SalesInitial extends SalesState {}
class SalesUpdated extends SalesState { final List<SaleItemEntity> items; final bool isInterState; SalesUpdated(this.items, this.isInterState); }
class SalesError extends SalesState { final String msg; SalesError(this.msg); }

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesRepository repository;
  List<SaleItemEntity> cart = [];
  bool isInterState = false;

  SalesBloc(this.repository) : super(SalesInitial()) {
    on<ToggleTaxType>((event, emit) {
      isInterState = event.isInterState;
      emit(SalesUpdated(List.from(cart), isInterState));
    });

    on<ScanBarcode>((event, emit) async {
      final code = event.code.trim();
      if (cart.any((e) => e.bCode == code)) {
        emit(SalesError("Item $code already added to bill"));
        return;
      }
      try {
        final data = await repository.lookupBarcode(code);
        cart.add(SaleItemEntity.fromLookup(data, isInterState, code));
        emit(SalesUpdated(List.from(cart), isInterState));
      } catch (e) {
        emit(SalesError("Barcode $code not found or invalid"));
      }
    });

    on<RemoveItem>((event, emit) {
      cart.removeAt(event.index);
      emit(SalesUpdated(List.from(cart), isInterState));
    });

    on<FinalizeBill>((event, emit) async {
      try {
        final response = await repository.saveBill(event.billData);

        // Print logic after success
        if (response['status'] == 'success') {
          await PrintService.generateAndPrint(response['data']);
        }

        cart.clear();
        emit(SalesInitial());
      } catch (e) {
        emit(SalesError("Billing Failed: Check Server Logs"));
      }
    });
  }
}

// ==========================================================================
// 4. UI LAYER
// ==========================================================================
class SalesBillingView extends StatefulWidget {
  const SalesBillingView({super.key});
  @override
  State<SalesBillingView> createState() => _SalesBillingViewState();
}

class _SalesBillingViewState extends State<SalesBillingView> {
  final _scanCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: "CASH");
  final _mobileCtrl = TextEditingController();
  final _discCtrl = TextEditingController(text: "0");
  final _freightCtrl = TextEditingController(text: "0");
  String _payMode = "CASH";
  bool _isInterState = false;
  late Timer _timer;
  String _currentDateTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) setState(() => _currentDateTime = "${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute}:${now.second}");
  }

  @override
  void dispose() { _timer.cancel(); _scanCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.msg), backgroundColor: Colors.red));
        }
        if (state is SalesInitial) {
          _mobileCtrl.clear();
          _scanCtrl.clear();
          _nameCtrl.text = "CASH";
          _discCtrl.clear();
          _freightCtrl.clear();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A252F),
          title: const Text("GST BILLING TERMINAL", style: TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            Center(child: Text(_currentDateTime, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
            const SizedBox(width: 20),
          ],
          toolbarHeight: 40,
        ),
        body: Column(
          children: [
            _buildCustomerHeader(),
            _buildScannerBar(),
            Expanded(child: _buildItemTable()),
            _buildCompactFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: [
        Expanded(flex: 3, child: _posTextField("Customer", _nameCtrl)),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: _posTextField("Mobile", _mobileCtrl, isNum: true)),
        const SizedBox(width: 10),
        _buildPayDropdown(),
      ],
    ),
  );

  Widget _buildScannerBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _scanCtrl, autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                  hintText: "SCAN ITEM BARCODE",
                  prefixIcon: Icon(Icons.qr_code_scanner, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.zero
              ),
              onSubmitted: (val) { if(val.isNotEmpty) context.read<SalesBloc>().add(ScanBarcode(val)); _scanCtrl.clear(); },
            ),
          ),
        ),
        const SizedBox(width: 20),
        const Text("Inter-State:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        Switch(value: _isInterState, activeColor: Colors.blue, onChanged: (v) {
          setState(() => _isInterState = v);
          context.read<SalesBloc>().add(ToggleTaxType(v));
        }),
      ],
    ),
  );

  Widget _buildItemTable() => BlocBuilder<SalesBloc, SalesState>(
    builder: (context, state) {
      final items = context.read<SalesBloc>().cart;
      return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 35,
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 48,
                  columnSpacing: 10,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF34495E)),
                  headingTextStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text("SN")),
                    DataColumn(label: Text("BARCODE")),
                    DataColumn(label: Text("GROUP")),
                    DataColumn(label: Text("RATE")),
                    DataColumn(label: Text("BASE AMOUNT")),
                    DataColumn(label: Text("CGST")),
                    DataColumn(label: Text("SGST")),
                    DataColumn(label: Text("IGST")),
                    DataColumn(label: Text("TOTAL")),
                    DataColumn(label: Text("DEL")),
                  ],
                  rows: items.asMap().entries.map((e) => DataRow(cells: [
                    DataCell(Text("${e.key + 1}", style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.bCode, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold))),
                    DataCell(Text(e.value.group, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.rate.toString(), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.amount.toString(), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.cgstAmt.toString(), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.sgstAmt.toString(), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.igstAmt.toString(), style: const TextStyle(fontSize: 11))),
                    DataCell(Text(e.value.total.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () => context.read<SalesBloc>().add(RemoveItem(e.key)),
                    )),
                  ])).toList(),
                ),
              ),
            );
          }
      );
    },
  );

  Widget _buildCompactFooter() => BlocBuilder<SalesBloc, SalesState>(
    builder: (context, state) {
      final cart = context.read<SalesBloc>().cart;
      double subtotal = cart.fold(0, (sum, item) => sum + item.total);
      double disc = double.tryParse(_discCtrl.text) ?? 0;
      double freight = double.tryParse(_freightCtrl.text) ?? 0;
      double finalTotal = (subtotal - (subtotal * disc / 100)) + freight;

      return Container(
        height: 130,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFF1A252F), border: const Border(top: BorderSide(color: Colors.white12))),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _footerSmallInput("DISCOUNT %", _discCtrl),
              const SizedBox(width: 15),
              _footerSmallInput("FREIGHT CHARGE", _freightCtrl),
              const Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹ ${finalTotal.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.yellowAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("NET PAYABLE", style: TextStyle(color: Colors.white70, fontSize: 9)),
                ],
              ),
              const SizedBox(width: 20),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700], foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 15)),
                  icon: const Icon(Icons.print, size: 18),
                  onPressed: () {
                    final payload = {
                      "customer_name": _nameCtrl.text,
                      "customer_mobile": _mobileCtrl.text,
                      "payment_mode": _payMode,
                      "discount": disc,
                      "freight_charge": freight,
                      "total_amount": double.parse(finalTotal.toStringAsFixed(2)),
                      "items": cart.map((e) => {
                        "barcode": e.bId,
                        "rate": e.rate,
                        "cgst_amt": e.cgstAmt,
                        "sgst_amt": e.sgstAmt,
                        "igst_amt": e.igstAmt,
                      }).toList(),
                    };
                    context.read<SalesBloc>().add(FinalizeBill(payload));
                  },
                  label: const Text("SAVE & PRINT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _posTextField(String label, TextEditingController ctrl, {bool isNum = false}) => SizedBox(
    height: 35,
    child: TextField(
      controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(fontSize: 11),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
      ),
    ),
  );

  Widget _buildPayDropdown() => Container(
    height: 35, padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
    child: DropdownButton<String>(
      value: _payMode, underline: const SizedBox(),
      items: ["CASH", "CARD", "UPI"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
      onChanged: (v) => setState(() => _payMode = v!),
    ),
  );

  Widget _footerSmallInput(String label, TextEditingController ctrl) => SizedBox(
    width: 150,
    height: 50,
    child: TextField(
      controller: ctrl,
      onChanged: (v) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        filled: true,
        fillColor: Colors.white10,
        isDense: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.yellowAccent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    ),
  );
}


/*

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA LAYER (Models)
// ==========================================================================

class SaleItemEntity {
  final int bId;
  final String group, bCode;
  final double rate, amount, cgstAmt, sgstAmt, igstAmt, total;

  SaleItemEntity({
    required this.bId, required this.group, required this.bCode,
    required this.rate, required this.amount, required this.cgstAmt,
    required this.sgstAmt, required this.igstAmt, required this.total,
  });

  factory SaleItemEntity.fromLookup(Map<String, dynamic> json, bool isInterState, String scannedCode) {
    double r = double.tryParse(json['rate']?.toString() ?? '0') ?? 0;
    double cRate = double.tryParse(json['cgst_rate']?.toString() ?? '0') ?? 0;
    double sRate = double.tryParse(json['sgst_rate']?.toString() ?? '0') ?? 0;
    double iRate = isInterState ? (cRate + sRate) : 0.0;
    if (isInterState) { cRate = 0.0; sRate = 0.0; }

    double taxTotal = cRate + sRate + iRate;
    double baseAmt = r / (1 + (taxTotal / 100));

    return SaleItemEntity(
      bId: json['barcode_id'] ?? 0,
      group: json['group_name'] ?? "Unknown",
      rate: r,
      amount: double.parse(baseAmt.toStringAsFixed(2)),
      cgstAmt: double.parse((baseAmt * (cRate / 100)).toStringAsFixed(2)),
      sgstAmt: double.parse((baseAmt * (sRate / 100)).toStringAsFixed(2)),
      igstAmt: double.parse((baseAmt * (iRate / 100)).toStringAsFixed(2)),
      total: r,
      bCode: scannedCode,
    );
  }
}

// ==========================================================================
// 2. REPOSITORY LAYER
// ==========================================================================

class SalesRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> lookupBarcode(String code) async {
    final response = await apiClient.get('/api/inventory/sales/lookup_barcode/', query: {'code': code});
    return response.data;
  }

  Future<Map<String, dynamic>> saveBill(Map<String, dynamic> billData) async {
    final response = await apiClient.post('/api/inventory/sales/', data: billData);
    return response.data;
  }

  Future<Map<String, dynamic>> processReturn(Map<String, dynamic> data) async {
    final response = await apiClient.post('/api/inventory/returns/process/', data: data);
    return response.data;
  }
}

// ==========================================================================
// 3. SERVICE LAYER (Detailed Print - FIXED 0.0 & Barcode)
// ==========================================================================

class PrintService {
  static Future<void> generateAndPrint(Map<String, dynamic> billData, {String title = "TAX INVOICE"}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          double subtotal = 0;
          List items = billData['items'] ?? [];
          for (var item in items) {
            subtotal += double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
          }

          double discPercent = double.tryParse(billData['discount']?.toString() ?? '0') ?? 0;
          double discAmt = subtotal * (discPercent / 100);
          double freight = double.tryParse(billData['freight_charge']?.toString() ?? '0') ?? 0;

          return pw.Container(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13))),
                pw.SizedBox(height: 5),
                pw.Text("Bill No : ${billData['bill_no']}", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Date    : ${billData['bill_date']}", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Cust    : ${billData['customer_name']}", style: pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 0.5),

                pw.Row(children: [
                  pw.Expanded(flex: 4, child: pw.Text("ITEM / BARCODE", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text("TAXABLE", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text("TOTAL", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                ]),
                pw.Divider(thickness: 0.5),

                ...items.map((item) {
                  double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
                  double cgst = double.tryParse(item['cgst_amt']?.toString() ?? '0') ?? 0;
                  double sgst = double.tryParse(item['sgst_amt']?.toString() ?? '0') ?? 0;
                  double taxable = rate - (cgst + sgst);

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(children: [
                      pw.Expanded(flex: 4, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text("${item['group_name'] ?? 'Item'}", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        // ✅ FIXED: Printing Barcode Value
                        pw.Text("BC: ${item['barcode_value'] ?? 'N/A'}", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ])),
                      pw.Expanded(flex: 3, child: pw.Text(taxable.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7))),
                      pw.Expanded(flex: 3, child: pw.Text(rate.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                    ]),
                  );
                }).toList(),

                pw.Divider(thickness: 0.5),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("Sub-Total:", style: pw.TextStyle(fontSize: 8)),
                  pw.Text("Rs. ${subtotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 8)),
                ]),
                if (discPercent > 0)
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text("Discount ($discPercent%):", style: pw.TextStyle(fontSize: 8, color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                    pw.Text("- Rs. ${discAmt.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 8, color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                  ]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("Freight Charge:", style: pw.TextStyle(fontSize: 8)),
                  pw.Text("+ Rs. ${freight.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 8)),
                ]),
                pw.SizedBox(height: 2),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text("Rs. ${billData['total_amount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ]),
                pw.SizedBox(height: 5),
                pw.Text("Words: ${billData['amount_in_words'] ?? ''}", style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
                pw.Divider(thickness: 0.5),
                pw.Center(child: pw.Text("--- THANK YOU! ---", style: pw.TextStyle(fontSize: 8))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Bill_${billData['bill_no']}');
  }
}

// ==========================================================================
// 4. PRESENTATION LAYER (BLoC)
// ==========================================================================

abstract class SalesEvent {}
class ScanBarcode extends SalesEvent { final String code; ScanBarcode(this.code); }
class RemoveItem extends SalesEvent { final int index; RemoveItem(this.index); }
class ToggleTaxType extends SalesEvent { final bool isInterState; ToggleTaxType(this.isInterState); }
class FinalizeBill extends SalesEvent { final Map<String, dynamic> billData; FinalizeBill(this.billData); }
class ProcessReturnEvent extends SalesEvent {
  final String oldB; final bool isEx; final String? newB;
  ProcessReturnEvent(this.oldB, this.isEx, this.newB);
}

abstract class SalesState {}
class SalesInitial extends SalesState {}
class SalesLoading extends SalesState {}
class SalesUpdated extends SalesState { final List<SaleItemEntity> items; final bool isInterState; SalesUpdated(this.items, this.isInterState); }
class SalesError extends SalesState { final String msg; SalesError(this.msg); }
class SalesSuccess extends SalesState { final String msg; SalesSuccess(this.msg); }

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesRepository repository;
  List<SaleItemEntity> cart = [];
  bool isInterState = false;

  SalesBloc(this.repository) : super(SalesInitial()) {
    on<ToggleTaxType>((event, emit) { isInterState = event.isInterState; emit(SalesUpdated(List.from(cart), isInterState)); });

    on<ScanBarcode>((event, emit) async {
      try {
        final data = await repository.lookupBarcode(event.code);
        cart.add(SaleItemEntity.fromLookup(data, isInterState, event.code));
        emit(SalesUpdated(List.from(cart), isInterState));
      } catch (e) { emit(SalesError("Barcode not found")); }
    });

    on<RemoveItem>((event, emit) {
      cart.removeAt(event.index);
      emit(SalesUpdated(List.from(cart), isInterState));
    });

    on<ProcessReturnEvent>((event, emit) async {
      emit(SalesLoading());
      try {
        final payload = {"old_barcode": event.oldB, "is_exchange": event.isEx, "new_barcode": event.newB};
        final response = await repository.processReturn(payload);
        if (response['status'] == 'success') {
          // ✅ AUTO PRINT AFTER EXCHANGE/RETURN
          if (response['data'] != null) {
            await PrintService.generateAndPrint(response['data'], title: event.isEx ? "EXCHANGE VOUCHER" : "RETURN VOUCHER");
          }
          emit(SalesSuccess(response['message'] ?? "Successful"));
          cart.clear(); emit(SalesInitial());
        }
      } catch (e) { emit(SalesError("Failed: Role Permissions Required")); }
    });

    on<FinalizeBill>((event, emit) async {
      emit(SalesLoading());
      try {
        final res = await repository.saveBill(event.billData);
        if (res['status'] == 'success') {
          await PrintService.generateAndPrint(res['data']);
          cart.clear(); emit(SalesInitial()); emit(SalesSuccess("Bill Printed"));
        }
      } catch (e) { emit(SalesError("Billing Failed")); }
    });
  }
}

// ==========================================================================
// 5. UI LAYER (Billing View)
// ==========================================================================

class SalesBillingView extends StatefulWidget {
  const SalesBillingView({super.key});
  @override State<SalesBillingView> createState() => _SalesBillingViewState();
}

class _SalesBillingViewState extends State<SalesBillingView> {
  final _scanCtrl = TextEditingController(), _nameCtrl = TextEditingController(text: "CASH"), _mobileCtrl = TextEditingController();
  final _discCtrl = TextEditingController(text: "0"), _freightCtrl = TextEditingController(text: "0");
  final _storage = const FlutterSecureStorage();
  String _payMode = "CASH", _userRole = "staff", _currentDateTime = "";
  bool _isInterState = false;
  late Timer _timer;

  @override void initState() { super.initState(); _loadUserRole(); _updateTime(); _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime()); }
  Future<void> _loadUserRole() async { final r = await _storage.read(key: 'user_role'); if (mounted) setState(() => _userRole = r ?? "staff"); }
  void _updateTime() { final n = DateTime.now(); if (mounted) setState(() => _currentDateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(n)); }
  @override void dispose() { _timer.cancel(); _scanCtrl.dispose(); super.dispose(); }

  void _showReturnDialog() {
    final oldC = TextEditingController(), newC = TextEditingController();
    bool isEx = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setMState) => AlertDialog(
      backgroundColor: const Color(0xFF2C3E50), title: const Text("RETURN / EXCHANGE CENTER", style: TextStyle(color: Colors.white, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [ _posTextField("Old Barcode", oldC), Row(children: [ const Text("Exchange?", style: TextStyle(color: Colors.white70)), Switch(value: isEx, activeColor: Colors.orange, onChanged: (v) => setMState(() => isEx = v)), ]), if (isEx) _posTextField("New Barcode", newC), ]),
      actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: () { context.read<SalesBloc>().add(ProcessReturnEvent(oldC.text, isEx, isEx ? newC.text : null)); Navigator.pop(ctx); }, child: const Text("PROCESS & PRINT")) ],
    )));
  }

  @override Widget build(BuildContext context) {
    return BlocConsumer<SalesBloc, SalesState>(
      listener: (context, state) { if (state is SalesError) _showSnackBar(state.msg, Colors.red); if (state is SalesSuccess) _showSnackBar(state.msg, Colors.green); },
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: const Color(0xFF1A252F), toolbarHeight: 40, title: const Text("GST BILLING TERMINAL", style: TextStyle(color: Colors.white, fontSize: 16)), actions: [ if (_userRole != 'staff') Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent), onPressed: _showReturnDialog, icon: const Icon(Icons.print, size: 16, color: Colors.black), label: const Text("RETURN/EXCH", style: TextStyle(fontSize: 11, color: Colors.black)))), const SizedBox(width: 20), Center(child: Text(_currentDateTime, style: const TextStyle(color: Colors.greenAccent, fontSize: 12))), const SizedBox(width: 15), ]),
        body: Column(children: [ _buildCustomerHeader(), _buildScannerBar(), Expanded(child: _buildItemTable()), if (state is SalesLoading) const LinearProgressIndicator(), _buildCompactFooter() ]),
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  Widget _buildCustomerHeader() => Container(padding: const EdgeInsets.all(8), child: Row(children: [ Expanded(flex: 3, child: _posTextField("Customer", _nameCtrl)), const SizedBox(width: 8), Expanded(flex: 2, child: _posTextField("Mobile", _mobileCtrl, isNum: true)), const SizedBox(width: 8), _buildPayDropdown() ]));

  Widget _buildScannerBar() => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))), child: Row(children: [ Expanded(child: SizedBox(height: 40, child: TextField(controller: _scanCtrl, autofocus: true, decoration: const InputDecoration(hintText: "SCAN BARCODE", prefixIcon: Icon(Icons.qr_code_scanner, size: 18), border: OutlineInputBorder()), onSubmitted: (v) { if(v.isNotEmpty) context.read<SalesBloc>().add(ScanBarcode(v)); _scanCtrl.clear(); }))), const SizedBox(width: 15), Switch(value: _isInterState, activeColor: Colors.blue, onChanged: (v) { setState(() => _isInterState = v); context.read<SalesBloc>().add(ToggleTaxType(v)); }), ]));

  Widget _buildItemTable() => LayoutBuilder(builder: (context, c) => SingleChildScrollView(child: ConstrainedBox(constraints: BoxConstraints(minWidth: c.maxWidth), child: DataTable(headingRowHeight: 35, headingRowColor: WidgetStateProperty.all(const Color(0xFF34495E)), headingTextStyle: const TextStyle(color: Colors.white, fontSize: 11), border: TableBorder.all(color: Colors.grey.shade300), columns: const [ DataColumn(label: Text("SN")), DataColumn(label: Text("BARCODE")), DataColumn(label: Text("GROUP")), DataColumn(label: Text("RATE")), DataColumn(label: Text("CGST")), DataColumn(label: Text("SGST")), DataColumn(label: Text("TOTAL")), DataColumn(label: Text("DEL")) ], rows: context.read<SalesBloc>().cart.asMap().entries.map((e) => DataRow(cells: [ DataCell(Text("${e.key + 1}")), DataCell(Text(e.value.bCode, style: const TextStyle(fontWeight: FontWeight.bold))), DataCell(Text(e.value.group)), DataCell(Text(e.value.rate.toString())), DataCell(Text(e.value.cgstAmt.toString())), DataCell(Text(e.value.sgstAmt.toString())), DataCell(Text(e.value.total.toString())), DataCell(IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => context.read<SalesBloc>().add(RemoveItem(e.key)))) ])).toList()))));

  Widget _buildCompactFooter() {
    final c = context.read<SalesBloc>().cart;
    double st = c.fold(0, (s, i) => s + i.total), d = double.tryParse(_discCtrl.text) ?? 0, f = double.tryParse(_freightCtrl.text) ?? 0, ft = (st - (st * d / 100)) + f;
    return Container(height: 130, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: const BoxDecoration(color: Color(0xFF1A252F), border: Border(top: BorderSide(color: Colors.white12))), child: Padding(padding: const EdgeInsets.only(bottom: 40), child: Row(children: [ _footerSmallInput("DISC %", _discCtrl), const SizedBox(width: 15), _footerSmallInput("FREIGHT", _freightCtrl), const Spacer(), Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Text("₹ ${ft.toStringAsFixed(2)}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 24, fontWeight: FontWeight.bold)), const Text("NET PAYABLE", style: TextStyle(color: Colors.white70, fontSize: 9)) ]), const SizedBox(width: 20), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700], minimumSize: const Size(150, 45)), onPressed: () { if (c.isEmpty) return; final p = { "customer_name": _nameCtrl.text, "customer_mobile": _mobileCtrl.text, "payment_mode": _payMode, "discount": d, "freight_charge": f, "total_amount": double.parse(ft.toStringAsFixed(2)), "items": c.map((e) => {"barcode": e.bId, "rate": e.rate, "cgst_amt": e.cgstAmt, "sgst_amt": e.sgstAmt, "igst_amt": e.igstAmt}).toList() }; context.read<SalesBloc>().add(FinalizeBill(p)); }, icon: const Icon(Icons.print, color: Colors.black), label: const Text("SAVE & PRINT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) ])));
  }

  Widget _posTextField(String l, TextEditingController c, {bool isNum = false}) => SizedBox(height: 35, child: TextField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, style: const TextStyle(fontSize: 12), decoration: InputDecoration(labelText: l, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 8))));
  Widget _buildPayDropdown() => Container(height: 35, padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)), child: DropdownButton<String>(value: _payMode, underline: const SizedBox(), items: ["CASH", "CARD", "UPI"].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(), onChanged: (v) => setState(() => _payMode = v!)));
  Widget _footerSmallInput(String l, TextEditingController c) => SizedBox(width: 150, height: 50, child: TextField(controller: c, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white70, fontSize: 14), filled: true, fillColor: Colors.white10, border: const OutlineInputBorder()), onChanged: (v) => setState(() {})));
}*/
