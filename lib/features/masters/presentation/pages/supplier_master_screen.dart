/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA LAYER (Matches Django BaseMaster Exactly)
// ==========================================================================
class SupplierEntity {
  final int? id;
  final String name, address, mobileNo, city, pinCode, email, gstNumber;
  final String bankName, accountNo, bankAddress, ifscCode, panNo;
  final String sName, sAddr, sMobile, sCity, sPin, sGst;
  final double openingCr, openingDr;
  final int creditDays;
  final String batchNumber, mop, createdBy;

  SupplierEntity({
    this.id, required this.name, required this.address, required this.mobileNo,
    required this.city, required this.pinCode, required this.email, required this.gstNumber,
    required this.bankName, required this.accountNo, required this.ifscCode, required this.panNo,
    required this.sName, required this.sAddr, required this.sMobile, required this.sCity,
    required this.sPin, required this.sGst,
    required this.openingCr, required this.openingDr, required this.creditDays,
    required this.batchNumber, required this.mop, required this.createdBy, required this.bankAddress,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "address": address,
    "mobile_no": mobileNo,
    "city": city,
    "pin_code": pinCode,
    "email": email,
    "gst_number": gstNumber,
    "pan_no": panNo,
    "bank_name": bankName,
    "bank_address": bankAddress,
    "account_no": accountNo,
    "ifsc_code": ifscCode,
    "shipping_name": sName,
    "shipping_address": sAddr,
    "shipping_mobile_no": sMobile,
    "shipping_city": sCity,
    "shipping_pin_code": sPin,
    "shipping_gst_no": sGst,
    "opening_balance_cr": openingCr,
    "opening_balance_dr": openingDr,
    "credit_days": creditDays,
    "batch_number": batchNumber,
    "mop": mop,
    "created_by": createdBy,
  };

  factory SupplierEntity.fromJson(Map<String, dynamic> json) => SupplierEntity(
    id: json['supplier_no'] ?? json['id'],
    name: json['name'] ?? "",
    address: json['address'] ?? "",
    mobileNo: json['mobile_no'] ?? "",
    city: json['city'] ?? "",
    pinCode: json['pin_code'] ?? "",
    email: json['email'] ?? "",
    gstNumber: json['gst_number'] ?? "",
    panNo: json['pan_no'] ?? "",
    bankName: json['bank_name'] ?? "",
    bankAddress: json['bank_address'] ?? "",
    accountNo: json['account_no'] ?? "",
    ifscCode: json['ifsc_code'] ?? "",
    sName: json['shipping_name'] ?? "",
    sAddr: json['shipping_address'] ?? "",
    sMobile: json['shipping_mobile_no'] ?? "",
    sCity: json['shipping_city'] ?? "",
    sPin: json['shipping_pin_code'] ?? "",
    sGst: json['shipping_gst_no'] ?? "",
    openingCr: double.tryParse(json['opening_balance_cr'].toString()) ?? 0.0,
    openingDr: double.tryParse(json['opening_balance_dr'].toString()) ?? 0.0,
    creditDays: json['credit_days'] ?? 30,
    batchNumber: json['batch_number'] ?? "",
    mop: json['mop'] ?? "CASH",
    createdBy: json['created_by'] ?? "ADMIN",
  );
}

class SupplierRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<SupplierEntity>> fetchAll() async {
    final res = await apiClient.get('/api/master/suppliers/');
    if (res.data is Map && res.data['results'] != null) {
      final List listData = res.data['results'] as List;
      return listData.map((e) => SupplierEntity.fromJson(e)).toList();
    }
    if (res.data is List) {
      return (res.data as List).map((e) => SupplierEntity.fromJson(e)).toList();
    }
    return [];
  }

  Future<SupplierEntity> save(SupplierEntity entity) async {
    final bool isUpdate = entity.id != null;
    final String path = isUpdate ? '/api/master/suppliers/${entity.id}/' : '/api/master/suppliers/';
    final res = isUpdate ? await apiClient.put(path, data: entity.toJson()) : await apiClient.post(path, data: entity.toJson());
    return SupplierEntity.fromJson(res.data);
  }
}

// ==========================================================================
// 2. BLOC LAYER
// ==========================================================================
abstract class SupplierEvent {}
class LoadSuppliers extends SupplierEvent {}
class SaveSupplierEvent extends SupplierEvent { final SupplierEntity supplier; SaveSupplierEvent(this.supplier); }

abstract class SupplierState {}
class SupplierInitial extends SupplierState {}
class SupplierLoading extends SupplierState {}
class SupplierLoaded extends SupplierState { final List<SupplierEntity> suppliers; SupplierLoaded(this.suppliers); }
class SupplierSuccess extends SupplierState { final String message; SupplierSuccess(this.message); }
class SupplierError extends SupplierState { final String error; SupplierError(this.error); }

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepository repo;
  SupplierBloc(this.repo) : super(SupplierInitial()) {
    on<LoadSuppliers>((event, emit) async {
      emit(SupplierLoading());
      try {
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      } catch (e) { emit(SupplierError(e.toString())); }
    });
    on<SaveSupplierEvent>((event, emit) async {
      try {
        await repo.save(event.supplier);
        emit(SupplierSuccess("Supplier Processed Successfully!"));
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      } catch (e) {
        String errorMsg = "Something went wrong";
        if (e.toString().contains("already exists")) {
          errorMsg = "A record with this name already exists (Duplicate Name)!";
        } else if (e.toString().contains("400")) {
          errorMsg = "Validation Error: Please check all fields.";
        } else {
          errorMsg = e.toString();
        }
        emit(SupplierError(errorMsg));
      }
    });
  }
}

// ==========================================================================
// 3. UI LAYER (High Density Split Canvas Surface)
// ==========================================================================
class SupplierMasterScreen extends StatefulWidget {
  const SupplierMasterScreen({super.key});
  @override
  State<SupplierMasterScreen> createState() => _SupplierMasterScreenState();
}

class _SupplierMasterScreenState extends State<SupplierMasterScreen> {
  // Billing Controllers
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  // Bank & Terms
  final _bankCtrl = TextEditingController();
  final _bankAddressCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: "30");

  // Shipping
  final _sNameCtrl = TextEditingController();
  final _sAddrCtrl = TextEditingController();
  final _sMobileCtrl = TextEditingController();
  final _sCityCtrl = TextEditingController();
  final _sPinCtrl = TextEditingController();
  final _sGstCtrl = TextEditingController();

  // Accounting
  final _crCtrl = TextEditingController(text: "0");
  final _drCtrl = TextEditingController(text: "0");

  final _batchCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String selectedMop = "CASH";
  SupplierEntity? editingSupplier;

  @override
  void initState() {
    super.initState();
    _batchCtrl.text = "SUPP-${DateFormat('yyyyMMdd').format(DateTime.now())}";
    context.read<SupplierBloc>().add(LoadSuppliers());
  }

  void _onSave() {
    if (_nameCtrl.text.trim().isEmpty) { _showSnackbar("Vendor Name is required!", Colors.orange); return; }

    String mobile = _mobileCtrl.text.trim();
    // 🟢 OPTIONAL LOGIC MATRIX: Agar mobile number khali nahi he, tabhi 10-digit regex check hoga
    if (mobile.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      _showSnackbar("Enter a valid 10-digit Mobile Number or leave it blank!", Colors.red); return;
    }

    final supplier = SupplierEntity(
      id: editingSupplier?.id,
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      mobileNo: mobile, // Automatically maps blank value safely
      city: _cityCtrl.text.trim(),
      pinCode: _pinCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim().toUpperCase(),
      panNo: _panCtrl.text.trim().toUpperCase(),
      bankName: _bankCtrl.text.trim().toUpperCase(),
      accountNo: _accCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      bankAddress: _bankAddressCtrl.text.trim(),
      sName: _sNameCtrl.text.trim(),
      sAddr: _sAddrCtrl.text.trim(),
      sMobile: _sMobileCtrl.text.trim(),
      sCity: _sCityCtrl.text.trim(),
      sPin: _sPinCtrl.text.trim(),
      sGst: _sGstCtrl.text.trim().toUpperCase(),
      openingCr: double.tryParse(_crCtrl.text) ?? 0.0,
      openingDr: double.tryParse(_drCtrl.text) ?? 0.0,
      creditDays: int.tryParse(_daysCtrl.text) ?? 30,
      batchNumber: _batchCtrl.text,
      mop: selectedMop,
      createdBy: "ADMIN",
    );
    context.read<SupplierBloc>().add(SaveSupplierEvent(supplier));
  }

  void _populateForm(SupplierEntity item) {
    setState(() {
      editingSupplier = item;
      _nameCtrl.text = item.name; _mobileCtrl.text = item.mobileNo; _addrCtrl.text = item.address;
      _cityCtrl.text = item.city; _pinCtrl.text = item.pinCode; _emailCtrl.text = item.email;
      _gstCtrl.text = item.gstNumber; _panCtrl.text = item.panNo;
      _bankCtrl.text = item.bankName; _accCtrl.text = item.accountNo; _ifscCtrl.text = item.ifscCode; _bankAddressCtrl.text = item.bankAddress;
      _sNameCtrl.text = item.sName; _sAddrCtrl.text = item.sAddr; _sMobileCtrl.text = item.sMobile;
      _sCityCtrl.text = item.sCity; _sPinCtrl.text = item.sPin; _sGstCtrl.text = item.sGst;
      _crCtrl.text = item.openingCr.toString(); _drCtrl.text = item.openingDr.toString();
      _daysCtrl.text = item.creditDays.toString(); selectedMop = item.mop;
    });
  }

  void _resetForm() {
    setState(() {
      editingSupplier = null;
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _panCtrl, _bankCtrl, _accCtrl, _ifscCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl, _bankAddressCtrl]) { c.clear(); }
      _crCtrl.text = "0"; _drCtrl.text = "0"; _daysCtrl.text = "30"; selectedMop = "CASH";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool useSplitView = screenWidth > 900;

    return BlocConsumer<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierSuccess) {
          _showSnackbar(state.message, Colors.green);
          _resetForm();
        }
        if (state is SupplierError) {
          _showSnackbar(state.error, Colors.redAccent);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ➡️ LEFT SIDE: DIRECTORY BAR (Only visible on wide layouts, or collapses safely)
              if (useSplitView) _buildLeftDirectoryPane(),

              // ➡️ RIGHT SIDE: MAIN CORE FORM WORKSPACE
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildTopActionBar(useSplitView),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!useSplitView) ...[
                                _buildMobileDirectoryButton(),
                                const SizedBox(height: 12),
                              ],
                              _buildFormCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftDirectoryPane() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: const Color(0xFF1E293B),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent, size: 16),
                SizedBox(width: 10),
                Text("SUPPLIER DIRECTORY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5))
              ],
            ),
          ),
          // Clean Search Frame
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white, // White background box
                border: Border.all(color: Colors.grey.shade700, width: 0.5),
                borderRadius: BorderRadius.zero,
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold), // Black text
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Search Suppliers records...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SupplierBloc, SupplierState>(
              builder: (context, state) {
                if (state is SupplierLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent));
                }
                if (state is SupplierLoaded) {
                  final filteredList = state.suppliers.where((e) {
                    final query = _searchCtrl.text.toLowerCase();
                    return e.name.toLowerCase().contains(query) || e.mobileNo.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text("No records found", style: TextStyle(color: Colors.grey, fontSize: 11)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, idx) {
                      final item = filteredList[idx];
                      bool isSelected = editingSupplier?.id == item.id;
                      return GestureDetector(
                        onTap: () => _populateForm(item),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                            borderRadius: BorderRadius.zero, // Fits industrial sharp styling matrix
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.name.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isSelected ? Colors.cyanAccent : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Phone: ${item.mobileNo} | GST: ${item.gstNumber.isEmpty ? 'N/A' : item.gstNumber}",
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: isSelected ? Colors.cyanAccent : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );                }
                return const Center(child: Text("Directory Sync Error", style: TextStyle(color: Colors.red)));
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTopActionBar(bool splitView) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                (editingSupplier == null ? "NEW SUPPLIER ENTRY MATRIX" : "MODIFY SUPPLIER RECORD").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
              ),
              if (editingSupplier != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.orange.shade100,
                  child: Text("EDITING ID: ${editingSupplier!.id}", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 9)),
                )
              ]
            ],
          ),
          Row(
            children: [
              if (editingSupplier != null)
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.red),
                  label: const Text("CANCEL", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _onSave,
                icon: Icon(editingSupplier == null ? Icons.save_outlined : Icons.done_all_rounded, size: 14),
                label: Text((editingSupplier == null ? "SAVE VENDOR" : "UPDATE SNAPS").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(), // Sharp edges standard
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("1. VENDOR REGISTRATION PRIMARY SCHEMA"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _sharpTextField(
                _nameCtrl,
                "Vendor / Corporate Master Name *",
                readOnly: editingSupplier != null,
              ),
            ),            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_mobileCtrl, "Contact Number", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_emailCtrl, "Email Address")),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _sharpTextField(_addrCtrl, "Registered Billing Address")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_cityCtrl, "City")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_pinCtrl, "Pin Code", isNum: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_gstCtrl, "GSTIN Number")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_panCtrl, "Corporate PAN Card No")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_batchCtrl, "System Batch Profile", readOnly: true)),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("2. FINANCIAL SETTLEMENT & BANKING CREDENTIALS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_bankCtrl, "Bank Name")),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _sharpTextField(_accCtrl, "Bank Account Number", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_ifscCtrl, "IFSC Clearance Code")),
          ],
        ),
        const SizedBox(height: 12),
        _sharpTextField(_bankAddressCtrl, "Branch Location & Address Details"),

        const SizedBox(height: 24),
        _buildSectionHeader("3. LEDGER BALANCES & RISK CONTROL PROFILE"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_daysCtrl, "Allowed Credit Period (Days)", isNum: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _sharpTextField(
                  _crCtrl, "Opening Balance (CR)",
                  isNum: true,
                  color: Colors.green,
                  onCh: (v) { if (v.isNotEmpty && v != "0") _drCtrl.text = "0"; },
                )
            ),
            const SizedBox(width: 12),
            Expanded(
                child: _sharpTextField(
                  _drCtrl, "Opening Balance (DR)",
                  isNum: true,
                  color: Colors.redAccent,
                  onCh: (v) { if (v.isNotEmpty && v != "0") _crCtrl.text = "0"; },
                )
            ),
          ],
        ),

        const SizedBox(height: 24),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text("4. LOGISTICS & SHIPPING WAREHOUSE ALTERNATES (OPTIONAL)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F4C81))),
            tilePadding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 8),
              _sharpTextField(_sNameCtrl, "Consignee Consignment Receiver Name"),
              const SizedBox(height: 12),
              _sharpTextField(_sAddrCtrl, "Consignment Delivery Shipping Address"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sharpTextField(_sCityCtrl, "Shipping City")),
                  const SizedBox(width: 12),
                  Expanded(child: _sharpTextField(_sPinCtrl, "Shipping Pin Code", isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _sharpTextField(_sGstCtrl, "Shipping Alternate GSTIN")),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sharpTextField(TextEditingController ctrl, String label, {
    bool isNum = false,
    bool readOnly = false,
    Color? color,
    Function(String)? onCh,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      onChanged: onCh,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.black87),
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        // ✅ NATIVE INDUSTRIAL STANDARD: Pure Sharp borders matrix
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: const Color(0xFFF1F5F9),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
    );
  }

  Widget _buildMobileDirectoryButton() {
    return ElevatedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: _buildLeftDirectoryPane(),
          ),
        );
      },
      icon: const Icon(Icons.list_alt_rounded, size: 14),
      label: const Text("VIEW SUPPLIER REGISTRY DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA LAYER (Matches Django BaseMaster Exactly)
// ==========================================================================
class SupplierEntity {
  final int? id;
  final String name, address, mobileNo, city, pinCode, email, gstNumber;
  final String bankName, accountNo, bankAddress, ifscCode, panNo;
  final String sName, sAddr, sMobile, sCity, sPin, sGst;
  final double openingCr, openingDr;
  final int creditDays;
  final String batchNumber, mop, createdBy;

  SupplierEntity({
    this.id, required this.name, required this.address, required this.mobileNo,
    required this.city, required this.pinCode, required this.email, required this.gstNumber,
    required this.bankName, required this.accountNo, required this.ifscCode, required this.panNo,
    required this.sName, required this.sAddr, required this.sMobile, required this.sCity,
    required this.sPin, required this.sGst,
    required this.openingCr, required this.openingDr, required this.creditDays,
    required this.batchNumber, required this.mop, required this.createdBy, required this.bankAddress,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "address": address,
    "mobile_no": mobileNo,
    "city": city,
    "pin_code": pinCode,
    "email": email,
    "gst_number": gstNumber,
    "pan_no": panNo,
    "bank_name": bankName,
    "bank_address": bankAddress,
    "account_no": accountNo,
    "ifsc_code": ifscCode,
    "shipping_name": sName,
    "shipping_address": sAddr,
    "shipping_mobile_no": sMobile,
    "shipping_city": sCity,
    "shipping_pin_code": sPin,
    "shipping_gst_no": sGst,
    "opening_balance_cr": openingCr,
    "opening_balance_dr": openingDr,
    "credit_days": creditDays,
    "batch_number": batchNumber,
    "mop": mop,
    "created_by": createdBy,
  };

  factory SupplierEntity.fromJson(Map<String, dynamic> json) => SupplierEntity(
    id: json['supplier_no'] ?? json['id'],
    name: json['name'] ?? "",
    address: json['address'] ?? "",
    mobileNo: json['mobile_no'] ?? "",
    city: json['city'] ?? "",
    pinCode: json['pin_code'] ?? "",
    email: json['email'] ?? "",
    gstNumber: json['gst_number'] ?? "",
    panNo: json['pan_no'] ?? "",
    bankName: json['bank_name'] ?? "",
    bankAddress: json['bank_address'] ?? "",
    accountNo: json['account_no'] ?? "",
    ifscCode: json['ifsc_code'] ?? "",
    sName: json['shipping_name'] ?? "",
    sAddr: json['shipping_address'] ?? "",
    sMobile: json['shipping_mobile_no'] ?? "",
    sCity: json['shipping_city'] ?? "",
    sPin: json['shipping_pin_code'] ?? "",
    sGst: json['shipping_gst_no'] ?? "",
    openingCr: double.tryParse(json['opening_balance_cr'].toString()) ?? 0.0,
    openingDr: double.tryParse(json['opening_balance_dr'].toString()) ?? 0.0,
    creditDays: json['credit_days'] ?? 30,
    batchNumber: json['batch_number'] ?? "",
    mop: json['mop'] ?? "CASH",
    createdBy: json['created_by'] ?? "ADMIN",
  );
}

class SupplierRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<SupplierEntity>> fetchAll() async {
    final res = await apiClient.get('/api/master/suppliers/');
    if (res.data is Map && res.data['results'] != null) {
      final List listData = res.data['results'] as List;
      return listData.map((e) => SupplierEntity.fromJson(e)).toList();
    }
    if (res.data is List) {
      return (res.data as List).map((e) => SupplierEntity.fromJson(e)).toList();
    }
    return [];
  }

  Future<SupplierEntity> save(SupplierEntity entity) async {
    final bool isUpdate = entity.id != null;
    final String path = isUpdate ? '/api/master/suppliers/${entity.id}/' : '/api/master/suppliers/';
    final res = isUpdate ? await apiClient.put(path, data: entity.toJson()) : await apiClient.post(path, data: entity.toJson());
    return SupplierEntity.fromJson(res.data);
  }

  // 🟢 Dedicated Supplier Bulk Upload API Call
  Future<Map<String, dynamic>> uploadBulkFile(PlatformFile file) async {
    MultipartFile multipartFile;
    if (file.bytes != null) {
      multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else {
      multipartFile = await MultipartFile.fromFile(file.path!, filename: file.name);
    }

    final formData = FormData.fromMap({"file": multipartFile});
    final res = await apiClient.post('/api/master/suppliers/bulk-upload/', data: formData);
    return res.data as Map<String, dynamic>;
  }
}

// ==========================================================================
// 2. BLOC LAYER
// ==========================================================================
abstract class SupplierEvent {}
class LoadSuppliers extends SupplierEvent {}
class SaveSupplierEvent extends SupplierEvent { final SupplierEntity supplier; SaveSupplierEvent(this.supplier); }
class SupplierBulkUploadEvent extends SupplierEvent { final PlatformFile file; SupplierBulkUploadEvent(this.file); }

abstract class SupplierState {}
class SupplierInitial extends SupplierState {}
class SupplierLoading extends SupplierState {}
class SupplierLoaded extends SupplierState { final List<SupplierEntity> suppliers; SupplierLoaded(this.suppliers); }
class SupplierSuccess extends SupplierState { final String message; SupplierSuccess(this.message); }
class SupplierError extends SupplierState { final String error; SupplierError(this.error); }

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepository repo;
  SupplierBloc(this.repo) : super(SupplierInitial()) {
    on<LoadSuppliers>((event, emit) async {
      emit(SupplierLoading());
      try {
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      } catch (e) { emit(SupplierError(e.toString())); }
    });

    on<SaveSupplierEvent>((event, emit) async {
      try {
        await repo.save(event.supplier);
        emit(SupplierSuccess("Supplier Processed Successfully!"));
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      } catch (e) {
        String errorMsg = "Something went wrong";
        if (e.toString().contains("already exists")) {
          errorMsg = "A record with this name already exists (Duplicate Name)!";
        } else if (e.toString().contains("400")) {
          errorMsg = "Validation Error: Please check all fields.";
        } else {
          errorMsg = e.toString();
        }
        emit(SupplierError(errorMsg));
      }
    });

    // 🟢 Handle Bulk Upload Event
    on<SupplierBulkUploadEvent>((event, emit) async {
      emit(SupplierLoading());
      try {
        final res = await repo.uploadBulkFile(event.file);
        emit(SupplierSuccess(res['message'] ?? "Suppliers imported successfully!"));
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      } catch (e) {
        emit(SupplierError("Supplier Bulk Upload Failed: ${e.toString()}"));
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      }
    });
  }
}

// ==========================================================================
// 3. UI LAYER (High Density Split Canvas Surface)
// ==========================================================================
class SupplierMasterScreen extends StatefulWidget {
  const SupplierMasterScreen({super.key});
  @override
  State<SupplierMasterScreen> createState() => _SupplierMasterScreenState();
}

class _SupplierMasterScreenState extends State<SupplierMasterScreen> {
  final ScrollController _directoryScrollCtrl = ScrollController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  final _bankCtrl = TextEditingController();
  final _bankAddressCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: "30");

  final _sNameCtrl = TextEditingController();
  final _sAddrCtrl = TextEditingController();
  final _sMobileCtrl = TextEditingController();
  final _sCityCtrl = TextEditingController();
  final _sPinCtrl = TextEditingController();
  final _sGstCtrl = TextEditingController();

  final _crCtrl = TextEditingController(text: "0");
  final _drCtrl = TextEditingController(text: "0");

  final _batchCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String selectedMop = "CASH";
  SupplierEntity? editingSupplier;

  @override
  void initState() {
    super.initState();
    _batchCtrl.text = "SUPP-${DateFormat('yyyyMMdd').format(DateTime.now())}";
    context.read<SupplierBloc>().add(LoadSuppliers());
  }

  @override
  void dispose() {
    // Scroll Controller
    _directoryScrollCtrl.dispose();

    // Primary & Billing Controllers
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    _pinCtrl.dispose();
    _emailCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();

    // Banking & Terms Controllers
    _bankCtrl.dispose();
    _bankAddressCtrl.dispose();
    _accCtrl.dispose();
    _ifscCtrl.dispose();
    _daysCtrl.dispose();

    // Accounting Controllers
    _crCtrl.dispose();
    _drCtrl.dispose();

    // Shipping Controllers
    _sNameCtrl.dispose();
    _sAddrCtrl.dispose();
    _sMobileCtrl.dispose();
    _sCityCtrl.dispose();
    _sPinCtrl.dispose();
    _sGstCtrl.dispose();

    // Batch & Search Controllers
    _batchCtrl.dispose();
    _searchCtrl.dispose();

    super.dispose();
  }

  // 🟢 Trigger File Picker for Supplier Bulk Import
  Future<void> _pickAndUploadExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (mounted) {
          context.read<SupplierBloc>().add(SupplierBulkUploadEvent(file));
        }
      }
    } catch (e) {
      _showSnackbar("File selection failed: $e", Colors.red);
    }
  }

  void _onSave() {
    if (_nameCtrl.text.trim().isEmpty) { _showSnackbar("Vendor Name is required!", Colors.orange); return; }

    String mobile = _mobileCtrl.text.trim();
    if (mobile.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      _showSnackbar("Enter a valid 10-digit Mobile Number or leave it blank!", Colors.red); return;
    }

    final supplier = SupplierEntity(
      id: editingSupplier?.id,
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      mobileNo: mobile,
      city: _cityCtrl.text.trim(),
      pinCode: _pinCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim().toUpperCase(),
      panNo: _panCtrl.text.trim().toUpperCase(),
      bankName: _bankCtrl.text.trim().toUpperCase(),
      accountNo: _accCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      bankAddress: _bankAddressCtrl.text.trim(),
      sName: _sNameCtrl.text.trim(),
      sAddr: _sAddrCtrl.text.trim(),
      sMobile: _sMobileCtrl.text.trim(),
      sCity: _sCityCtrl.text.trim(),
      sPin: _sPinCtrl.text.trim(),
      sGst: _sGstCtrl.text.trim().toUpperCase(),
      openingCr: double.tryParse(_crCtrl.text) ?? 0.0,
      openingDr: double.tryParse(_drCtrl.text) ?? 0.0,
      creditDays: int.tryParse(_daysCtrl.text) ?? 30,
      batchNumber: _batchCtrl.text,
      mop: selectedMop,
      createdBy: "ADMIN",
    );
    context.read<SupplierBloc>().add(SaveSupplierEvent(supplier));
  }

  void _populateForm(SupplierEntity item) {
    setState(() {
      editingSupplier = item;
      _nameCtrl.text = item.name; _mobileCtrl.text = item.mobileNo; _addrCtrl.text = item.address;
      _cityCtrl.text = item.city; _pinCtrl.text = item.pinCode; _emailCtrl.text = item.email;
      _gstCtrl.text = item.gstNumber; _panCtrl.text = item.panNo;
      _bankCtrl.text = item.bankName; _accCtrl.text = item.accountNo; _ifscCtrl.text = item.ifscCode; _bankAddressCtrl.text = item.bankAddress;
      _sNameCtrl.text = item.sName; _sAddrCtrl.text = item.sAddr; _sMobileCtrl.text = item.sMobile;
      _sCityCtrl.text = item.sCity; _sPinCtrl.text = item.sPin; _sGstCtrl.text = item.sGst;
      _crCtrl.text = item.openingCr.toString(); _drCtrl.text = item.openingDr.toString();
      _daysCtrl.text = item.creditDays.toString(); selectedMop = item.mop;
    });
  }

  void _resetForm() {
    setState(() {
      editingSupplier = null;
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _panCtrl, _bankCtrl, _accCtrl, _ifscCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl, _bankAddressCtrl]) { c.clear(); }
      _crCtrl.text = "0"; _drCtrl.text = "0"; _daysCtrl.text = "30"; selectedMop = "CASH";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool useSplitView = screenWidth > 900;

    return BlocConsumer<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierSuccess) {
          _showSnackbar(state.message, Colors.green);
          _resetForm();
        }
        if (state is SupplierError) {
          _showSnackbar(state.error, Colors.redAccent);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 🟢 MUST BE STRETCH (Full height boundary for Left Directory)
            children: [
              if (useSplitView) _buildLeftDirectoryPane(),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildTopActionBar(useSplitView),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!useSplitView) ...[
                                _buildMobileDirectoryButton(),
                                const SizedBox(height: 12),
                              ],
                              _buildFormCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftDirectoryPane() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: const Color(0xFF1E293B),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent, size: 16),
                SizedBox(width: 10),
                Text(
                  "SUPPLIER DIRECTORY",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                )
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade700, width: 0.5),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                onChanged: (v) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Search Suppliers records...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),

          // Scrollable List Area
          Expanded(
            child: BlocBuilder<SupplierBloc, SupplierState>(
              builder: (context, state) {
                if (state is SupplierLoading) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent),
                  );
                }

                if (state is SupplierLoaded) {
                  final filteredList = state.suppliers.where((e) {
                    final query = _searchCtrl.text.toLowerCase();
                    return e.name.toLowerCase().contains(query) || e.mobileNo.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(
                      child: Text("No records found", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    );
                  }

                  // Dedicated ScrollController for Scrollbar + ListView
                  return Scrollbar(
                    controller: _directoryScrollCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: _directoryScrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemCount: filteredList.length,
                      itemBuilder: (context, idx) {
                        final item = filteredList[idx];
                        bool isSelected = editingSupplier?.id == item.id;

                        return Material(
                          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                          child: InkWell(
                            onTap: () => _populateForm(item),
                            hoverColor: Colors.white10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade900, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${idx + 1}. ${item.name.toUpperCase()}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: isSelected ? Colors.cyanAccent : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          "Phone: ${item.mobileNo.isEmpty ? 'N/A' : item.mobileNo} | GST: ${item.gstNumber.isEmpty ? 'N/A' : item.gstNumber}",
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: isSelected ? Colors.cyanAccent : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const Center(child: Text("Directory Sync Error", style: TextStyle(color: Colors.red)));
              },
            ),
          ),
        ],
      ),
    );
  }
  // ==========================================================================
  // TOP ACTION BAR (With Integrated BULK IMPORT Button)
  // ==========================================================================
  Widget _buildTopActionBar(bool splitView) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Title & Editing Status
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 16, color: const Color(0xFF0F172A)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    (editingSupplier == null ? "SUPPLIER SETUP MATRIX" : "MODIFY RECORD").toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (editingSupplier != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.orange.shade100,
                    child: Text(
                      "ID: ${editingSupplier!.id}",
                      style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Action Buttons (Wrapped to avoid renderflex overflow)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            children: [
              _badge("BATCH: ${_batchCtrl.text}"),

              // 🟢 Bulk Import button hides during editing
              if (editingSupplier == null)
                OutlinedButton.icon(
                  onPressed: _pickAndUploadExcel,
                  icon: const Icon(Icons.upload_file_rounded, size: 13, color: Color(0xFF0284C7)),
                  label: const Text(
                    "IMPORT",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    backgroundColor: const Color(0xFFF0F9FF),
                  ),
                ),

              // Cancel Button (Edit Mode Only)
              if (editingSupplier != null)
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.clear_rounded, size: 13, color: Colors.red),
                  label: const Text("CANCEL", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),

              // Save / Update Button
              ElevatedButton.icon(
                onPressed: _onSave,
                icon: Icon(editingSupplier == null ? Icons.save_outlined : Icons.done_all_rounded, size: 13),
                label: Text(
                  (editingSupplier == null ? "SAVE" : "UPDATE").toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("1. VENDOR REGISTRATION PRIMARY SCHEMA"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _sharpTextField(
                _nameCtrl,
                "Vendor / Corporate Master Name *",
                readOnly: editingSupplier != null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_mobileCtrl, "Contact Number", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_emailCtrl, "Email Address")),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _sharpTextField(_addrCtrl, "Registered Billing Address")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_cityCtrl, "City")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_pinCtrl, "Pin Code", isNum: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_gstCtrl, "GSTIN Number")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_panCtrl, "Corporate PAN Card No")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_batchCtrl, "System Batch Profile", readOnly: true)),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader("2. FINANCIAL SETTLEMENT & BANKING CREDENTIALS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_bankCtrl, "Bank Name")),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _sharpTextField(_accCtrl, "Bank Account Number", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_ifscCtrl, "IFSC Clearance Code")),
          ],
        ),
        const SizedBox(height: 12),
        _sharpTextField(_bankAddressCtrl, "Branch Location & Address Details"),

        const SizedBox(height: 24),
        _buildSectionHeader("3. LEDGER BALANCES & RISK CONTROL PROFILE"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_daysCtrl, "Allowed Credit Period (Days)", isNum: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _sharpTextField(
                  _crCtrl, "Opening Balance (CR)",
                  isNum: true,
                  color: Colors.green,
                  onCh: (v) { if (v.isNotEmpty && v != "0") _drCtrl.text = "0"; },
                )
            ),
            const SizedBox(width: 12),
            Expanded(
                child: _sharpTextField(
                  _drCtrl, "Opening Balance (DR)",
                  isNum: true,
                  color: Colors.redAccent,
                  onCh: (v) { if (v.isNotEmpty && v != "0") _crCtrl.text = "0"; },
                )
            ),
          ],
        ),

        const SizedBox(height: 24),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text("4. LOGISTICS & SHIPPING WAREHOUSE ALTERNATES (OPTIONAL)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F4C81))),
            tilePadding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 8),
              _sharpTextField(_sNameCtrl, "Consignee Consignment Receiver Name"),
              const SizedBox(height: 12),
              _sharpTextField(_sAddrCtrl, "Consignment Delivery Shipping Address"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sharpTextField(_sCityCtrl, "Shipping City")),
                  const SizedBox(width: 12),
                  Expanded(child: _sharpTextField(_sPinCtrl, "Shipping Pin Code", isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _sharpTextField(_sGstCtrl, "Shipping Alternate GSTIN")),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sharpTextField(TextEditingController ctrl, String label, {
    bool isNum = false,
    bool readOnly = false,
    Color? color,
    Function(String)? onCh,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      onChanged: onCh,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.black87),
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.3),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF0F172A), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: const Color(0xFFF1F5F9),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3)),
    );
  }

  Widget _buildMobileDirectoryButton() {
    return ElevatedButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: _buildLeftDirectoryPane(),
          ),
        );
      },
      icon: const Icon(Icons.list_alt_rounded, size: 14),
      label: const Text("VIEW SUPPLIER REGISTRY DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

Widget _badge(String t) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.zero,
    ),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 9,
      ),
    ),
  );
}