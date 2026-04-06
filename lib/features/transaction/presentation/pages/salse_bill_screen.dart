
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/bill_printing_service.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/block/login_bloc.dart';

// ==========================================================================
// 1. DATA ENTITY
// ==========================================================================
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

// ==========================================================================
// 2. REPOSITORY
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
        if (response['status'] == 'success') {
          print("bill data:$response");
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

  // Persistence & API Optimization
  String? _activeOperatorId;
  Future<Response>? _staffFuture; // ✅ Store future to prevent infinite loop
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _loadActiveOperator();
    // ✅ Initialize the future only once
    _staffFuture = sl<ApiClient>().get('/api/user/staff/');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  Future<void> _loadActiveOperator() async {
    final idStr = await _storage.read(key: 'user_id');
    if (idStr != null && mounted) {
      setState(() {
        _activeOperatorId = idStr;
      });
    }
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
          _discCtrl.text = "0";
          _freightCtrl.text = "0";
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
        // ✅ 1. Customer Name (Flex 1)
        Expanded(flex: 1, child: _posTextField("Customer", _nameCtrl)),
        const SizedBox(width: 8),

        // ✅ 2. Mobile (Flex 1)
        Expanded(flex: 1, child: _posTextField("Mobile", _mobileCtrl, isNum: true)),
        const SizedBox(width: 8),

        // ✅ 3. Role-Based Switcher (Direct Storage Check)
        Expanded(
          flex: 1,
          child: FutureBuilder<String?>(
            future: _storage.read(key: 'user_role'), // ✅ Direct storage se role uthao
            builder: (context, snapshot) {
              final role = snapshot.data?.toLowerCase() ?? 'staff';

              if (role == 'admin' || role == 'superuser') {
                // Admin/Superuser ke liye Disabled Look
                return Container(
                  height: 35,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    "ADMIN SESSION",
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              }
              // Staff ke liye Dropdown
              return _buildOperatorSwitcher();
            },
          ),
        ),

        const SizedBox(width: 8),

        // ✅ 4. Payment Mode
        SizedBox(width: 85, child: _buildPayDropdown()),
      ],
    ),
  );

  Widget _buildOperatorSwitcher() {
    return FutureBuilder<Response>(
      future: _staffFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 35,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
            child: const Center(child: LinearProgressIndicator()),
          );
        }
        if (!snapshot.hasData) return const SizedBox(height: 35);

        final List staffList = snapshot.data?.data['data'] ?? [];

        return Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: staffList.any((e) => e['id'].toString() == _activeOperatorId) ? _activeOperatorId : null,
              hint: const Text("STAFF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.arrow_drop_down, size: 18),
              items: staffList.map((s) => DropdownMenuItem<String>(
                value: s['id'].toString(),
                child: Text(
                  s['name'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    fontSize: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )).toList(),
              onChanged: (id) {
                if (id != null) {
                  setState(() => _activeOperatorId = id);
                  context.read<LoginBloc>().add(SwitchUserRequested(id));
                }
              },
            ),
          ),
        );
      },
    );
  }


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