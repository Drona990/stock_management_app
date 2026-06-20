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
    id: json['supplier_no'],
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

    // ✅ FIX: Django DRF Paginated metadata se list extract ki
    if (res.data is Map && res.data['results'] != null) {
      final List listData = res.data['results'] as List;
      return listData.map((e) => SupplierEntity.fromJson(e)).toList();
    }

    // Fallback Matrix: Agar kisi corner case me direct list aa jaye
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
// 3. UI LAYER (Presentation High Density Re-engineered Canvas)
// ==========================================================================
class SupplierMasterScreen extends StatefulWidget {
  const SupplierMasterScreen({super.key});
  @override
  State<SupplierMasterScreen> createState() => _SupplierMasterScreenState();
}

class _SupplierMasterScreenState extends State<SupplierMasterScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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

  // Shipping (Optional)
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
    if (_nameCtrl.text.isEmpty) { _showSnackbar("Vendor Name is required!", Colors.orange); return; }

    String mobile = _mobileCtrl.text.trim();
    if (mobile.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      _showSnackbar("Enter a valid 10-digit Mobile Number!", Colors.red); return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5)));

    final supplier = SupplierEntity(
      id: editingSupplier?.id,
      name: _nameCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      mobileNo: mobile,
      city: _cityCtrl.text.trim(),
      pinCode: _pinCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim(),
      panNo: _panCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      accountNo: _accCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim(),
      bankAddress: _bankAddressCtrl.text.trim(),
      sName: _sNameCtrl.text.trim(),
      sAddr: _sAddrCtrl.text.trim(),
      sMobile: _sMobileCtrl.text.trim(),
      sCity: _sCityCtrl.text.trim(),
      sPin: _sPinCtrl.text.trim(),
      sGst: _sGstCtrl.text.trim(),
      openingCr: double.tryParse(_crCtrl.text) ?? 0.0,
      openingDr: double.tryParse(_drCtrl.text) ?? 0.0,
      creditDays: int.tryParse(_daysCtrl.text) ?? 30,
      batchNumber: _batchCtrl.text,
      mop: selectedMop,
      createdBy: "ADMIN",
    );
    context.read<SupplierBloc>().add(SaveSupplierEvent(supplier));
  }

  void _onEdit(SupplierEntity item) {
    setState(() {
      editingSupplier = item;
      _nameCtrl.text = item.name; _mobileCtrl.text = item.mobileNo; _addrCtrl.text = item.address;
      _cityCtrl.text = item.city; _pinCtrl.text = item.pinCode; _emailCtrl.text = item.email;
      _gstCtrl.text = item.gstNumber; _panCtrl.text = item.panNo;
      _bankCtrl.text = item.bankName; _accCtrl.text = item.accountNo; _ifscCtrl.text = item.ifscCode;_bankAddressCtrl.text = item.bankAddress;
      _sNameCtrl.text = item.sName; _sAddrCtrl.text = item.sAddr; _sMobileCtrl.text = item.sMobile;
      _sCityCtrl.text = item.sCity; _sPinCtrl.text = item.sPin; _sGstCtrl.text = item.sGst;
      _crCtrl.text = item.openingCr.toString(); _drCtrl.text = item.openingDr.toString();
      _daysCtrl.text = item.creditDays.toString(); selectedMop = item.mop;
    });
    Navigator.pop(context);
  }

  void _resetForm() {
    setState(() {
      editingSupplier = null;
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _panCtrl, _bankCtrl, _accCtrl, _ifscCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl,_bankAddressCtrl]) { c.clear(); }
      _crCtrl.text = "0"; _drCtrl.text = "0"; _daysCtrl.text = "30";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 11)), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierSuccess || state is SupplierError) {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
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
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFB),
          endDrawer: _buildRightHistoryDrawer(),
          body: Column(
            children: [
              _buildTopActionBar(),
              Expanded(
                child: (state is SupplierLoading && editingSupplier == null)
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5))
                    : LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                      padding: EdgeInsets.all(constraints.maxWidth < 600 ? 10 : 16),
                      child: Center(
                          child: Container(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: _buildFormCard(constraints.maxWidth)
                          )
                      )
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopActionBar() {
    bool isMobile = MediaQuery.of(context).size.width < 700;
    const Color industrialSlate = Color(0xFF1E293B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
              (editingSupplier == null ? "SUPPLIER MASTER" : "EDIT SUPPLIER").toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: industrialSlate, fontSize: 13, letterSpacing: 0.3)
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: _actionButtons(isMobile),
          )
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              (editingSupplier == null ? "SUPPLIER MASTER" : "EDIT SUPPLIER").toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: industrialSlate, fontSize: 13, letterSpacing: 0.3)
          ),
          Row(children: _actionButtons(false)),
        ],
      ),
    );
  }

  List<Widget> _actionButtons(bool isMobile) {
    return [
      _badge("BATCH: ${_batchCtrl.text}"),
      const SizedBox(width: 4),
      OutlinedButton.icon(
        onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        icon: const Icon(Icons.history_rounded, size: 14),
        label: const Text("DATABASE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      const SizedBox(width: 4),
      if (editingSupplier != null)
        IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
            onPressed: _resetForm
        ),
      const SizedBox(width: 4),
      ElevatedButton.icon(
        onPressed: _onSave,
        icon: Icon(editingSupplier == null ? Icons.save_outlined : Icons.update_rounded, size: 14),
        label: Text((editingSupplier == null ? "SAVE MASTER" : "UPDATE MASTER").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    ];
  }

  Widget _buildFormCard(double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("VENDOR PRIMARY INFORMATION"),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(
                _nameCtrl,
                "Vendor Name",
                Icons.storefront_rounded,
                flex: 2,
                readOnly: editingSupplier != null
            ),
            _tf(_mobileCtrl, "Contact No", Icons.phone_android_rounded, isNum: true),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: _tf(_addrCtrl, "Billing Address", Icons.location_on_outlined, maxLines: 2),
          ),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_cityCtrl, "City", Icons.location_city_rounded),
            _tf(_pinCtrl, "Pin Code", Icons.pin_drop_outlined, isNum: true),
            _tf(_emailCtrl, "Email Address", Icons.email_outlined, flex: 2),
          ]),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_gstCtrl, "GST Number", Icons.receipt_long_outlined),
            _tf(_panCtrl, "PAN Number", Icons.badge_outlined),
          ]),
          const SizedBox(height: 20),
          _sectionLabel("BANKING & PAYMENT TERMS"),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_bankCtrl, "Bank Name", Icons.account_balance_rounded),
            _tf(_accCtrl, "Account No", Icons.numbers_outlined, isNum: true, flex: 2),
            _tf(_ifscCtrl, "IFSC Code", Icons.code_rounded),
            _tf(_bankAddressCtrl, "Branch & Address Details", Icons.account_balance_outlined),
          ]),
          const SizedBox(height: 20),
          _sectionLabel("ACCOUNTS & LEDGER"),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_daysCtrl, "Credit Period (Days)", Icons.timer_outlined, isNum: true),
            _tf(_crCtrl, "Opening CR", Icons.add_circle_outline_rounded,
                color: Colors.green,
                isNum: true,
                onCh: (v) {
                  if (v.isNotEmpty && v != "0") {
                    setState(() => _drCtrl.text = "0");
                  }
                }
            ),
            _tf(_drCtrl, "Opening DR", Icons.remove_circle_outline_rounded,
                color: Colors.redAccent,
                isNum: true,
                onCh: (v) {
                  if (v.isNotEmpty && v != "0") {
                    setState(() => _crCtrl.text = "0");
                  }
                }
            ),
          ]),
          const SizedBox(height: 20),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text("SHIPPING / RETURN WAREHOUSE (OPTIONAL)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.2)),
              tilePadding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 12),
                _tf(_sNameCtrl, "Consignee Name", Icons.person_pin_outlined),
                const SizedBox(height: 12),
                _tf(_sAddrCtrl, "Shipping Address", Icons.map_outlined, maxLines: 2),
                const SizedBox(height: 12),
                _responsiveRow(width, [
                  _tf(_sCityCtrl, "Ship City", Icons.apartment_rounded),
                  _tf(_sPinCtrl, "Ship Pin", Icons.pin_drop_outlined, isNum: true),
                  _tf(_sGstCtrl, "Ship GST", Icons.verified_outlined),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsiveRow(double width, List<Widget> children) {
    if (width < 600) {
      return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((c) => Expanded(
            flex: (c is _FlexWidget) ? c.flex : 1,
            child: Padding(padding: const EdgeInsets.only(right: 12), child: c)
        )).toList()
    );
  }

  Widget _tf(TextEditingController c, String l, IconData i, {
    int maxLines = 1,
    Color? color,
    bool isNum = false,
    bool readOnly = false,
    int flex = 1,
    Function(String)? onCh,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onCh,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        prefixIcon: Icon(i, size: 14, color: const Color(0xFF00BCD4)),
        isDense: true,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      ),
    );
  }

  Widget _buildRightHistoryDrawer() {
    double w = MediaQuery.of(context).size.width;
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      width: w > 800 ? 800 : w * 0.9,
      child: Column(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: const Color(0xFF0F172A),
            child: const SafeArea(
                child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent, size: 16),
                      SizedBox(width: 10),
                      Text("SUPPLIER DATABASE DIRECTORY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3))
                    ]
                )
            )
        ),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 11),
                  onChanged: (v) => setState(() {}),
                  decoration: const InputDecoration(hintText: "Filter directory by keyword...", hintStyle: TextStyle(fontSize: 11), prefixIcon: Icon(Icons.search_rounded, size: 14), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12))
              ),
            )
        ),
        Expanded(
            child: BlocBuilder<SupplierBloc, SupplierState>(builder: (context, state) {
              if (state is SupplierLoaded) {
                final list = state.suppliers.where((e) => e.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) || e.mobileNo.contains(_searchCtrl.text)).toList();
                return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: list.length, itemBuilder: (ctx, i) => _buildDetailCard(list[i]));
              }
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
            })
        ),
      ]),
    );
  }

  Widget _buildDetailCard(SupplierEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF8FAFC),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                          item.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F4C81), fontSize: 11, letterSpacing: 0.2),
                          overflow: TextOverflow.ellipsis,
                        )
                    ),
                    _badge(item.batchNumber)
                  ]
              )
          ),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Wrap(
                    runSpacing: 10,
                    spacing: 12,
                    children: [
                      SizedBox(width: 160, child: _infoItem("Contact", item.mobileNo, Icons.phone_android_rounded)),
                      SizedBox(width: 140, child: _infoItem("City", item.city, Icons.location_city_rounded)),
                      SizedBox(width: 160, child: _infoItem("Bank", item.bankName, Icons.account_balance_rounded)),
                      SizedBox(width: 160, child: _infoItem("Bank/Branch Address", item.bankAddress, Icons.map_outlined)),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  Wrap(
                    runSpacing: 10,
                    spacing: 12,
                    children: [
                      SizedBox(width: 160, child: _infoItem("Opening CR", "₹${item.openingCr}", Icons.add_circle_outline_rounded, color: Colors.green)),
                      SizedBox(width: 140, child: _infoItem("Opening DR", "₹${item.openingDr}", Icons.remove_circle_outline_rounded, color: Colors.redAccent)),
                      SizedBox(width: 160, child: _infoItem("GST", item.gstNumber, Icons.receipt_long_outlined)),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _infoItem("Billing Address", item.address, Icons.home_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoItem("Shipping Address", item.sAddr, Icons.local_shipping_outlined)),
                    ],
                  ),
                ],
              )
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: () => _onEdit(item),
                    icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.orange),
                    label: const Text("EDIT RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange))
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String l, String v, IconData i, {Color? color}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
                Icon(i, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold))
              ]
          ),
          const SizedBox(height: 2),
          Text(
              v.isEmpty ? "N/A" : v,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF1E293B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis
          )
        ]
    );
  }

  Widget _sectionLabel(String t) => Row(children: [Container(width: 3, height: 12, color: const Color(0xFF00BCD4)), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.2))]);
  Widget _badge(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(2)), child: Text(t, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 9)));
}

class _FlexWidget extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexWidget({required this.flex, required this.child});
  @override
  Widget build(BuildContext context) => child;
}*/


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
    if (mobile.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      _showSnackbar("Enter a valid 10-digit Mobile Number!", Colors.red); return;
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
// 💡 ALTERNATIVE: Light Background Search bar with Black Text
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
          ),          Expanded(
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
                      return ListTile(
                        onTap: () => _populateForm(item),
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF1E293B),
                        title: Text(item.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.cyanAccent : Colors.white)),
                        subtitle: Text("Phone: ${item.mobileNo} | GST: ${item.gstNumber.isEmpty ? 'N/A' : item.gstNumber}", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey),
                      );
                    },
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
            Expanded(flex: 2, child: _sharpTextField(_nameCtrl, "Vendor / Corporate Master Name *")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_mobileCtrl, "Contact Number *", isNum: true)),
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
}