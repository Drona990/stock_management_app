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
  final int? id; // supplier_no in DB
  final String name, address, mobileNo, city, pinCode, email, gstNumber;
  final String bankName, accountNo, ifscCode, panNo;
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
    required this.batchNumber, required this.mop, required this.createdBy,
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
    return (res.data as List).map((e) => SupplierEntity.fromJson(e)).toList();
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
        emit(SupplierSuccess("Supplier Processed!"));
        final data = await repo.fetchAll();
        emit(SupplierLoaded(data));
      } catch (e) { emit(SupplierError(e.toString())); }
    });
  }
}

// ==========================================================================
// 3. UI LAYER (Presentation)
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

  // --- Logic ---
  void _onSave() {
    if (_nameCtrl.text.isEmpty) { _showSnackbar("Vendor Name is required!", Colors.orange); return; }

    // Validations (As per your original code)
    String mobile = _mobileCtrl.text.trim();
    if (mobile.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      _showSnackbar("Enter a valid 10-digit Mobile Number!", Colors.red); return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))));

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
      _bankCtrl.text = item.bankName; _accCtrl.text = item.accountNo; _ifscCtrl.text = item.ifscCode;
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
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _panCtrl, _bankCtrl, _accCtrl, _ifscCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl]) { c.clear(); }
      _crCtrl.text = "0"; _drCtrl.text = "0"; _daysCtrl.text = "30";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierSuccess || state is SupplierError) { if (Navigator.of(context, rootNavigator: true).canPop()) Navigator.of(context, rootNavigator: true).pop(); }
        if (state is SupplierSuccess) { _showSnackbar(state.message, Colors.green); _resetForm(); }
        if (state is SupplierError) { _showSnackbar(state.error, Colors.red); }
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
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                    : LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                      padding: EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 24),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Mobile ke liye padding thodi kam ki hai
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
              editingSupplier == null ? "SUPPLIER MASTER" : "EDIT SUPPLIER",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C24), fontSize: 14)
          ),
          const SizedBox(height: 12),
          // Wrap use karne se buttons niche wali line mein aa jayenge, scroll nahi honge
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, // Buttons ke beech ka gap
            runSpacing: 8, // Lines ke beech ka gap
            children: _actionButtons(isMobile),
          )
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              editingSupplier == null ? "SUPPLIER MASTER" : "EDIT SUPPLIER",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C24), fontSize: 16)
          ),
          Row(children: _actionButtons(false)),
        ],
      ),
    );
  }

  List<Widget> _actionButtons(bool isMobile) {
    return [
      _badge("BATCH: ${_batchCtrl.text}"),
      SizedBox(width: 5,),

      // View Database Button
      OutlinedButton.icon(
        onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        icon: const Icon(Icons.history, size: 16),
        label: const Text("DATABASE", style: TextStyle(fontSize: 11)), // Chhota text mobile ke liye
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      SizedBox(width: 5,),


      if (editingSupplier != null)
        IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
            onPressed: _resetForm
        ),

      // Save Button
      ElevatedButton.icon(
        onPressed: _onSave,
        icon: Icon(editingSupplier == null ? Icons.save : Icons.update, size: 16),
        label: Text(editingSupplier == null ? "SAVE MASTER" : "UPDATE MASTER", style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1C24),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    ];
  }

  Widget _buildFormCard(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("VENDOR PRIMARY INFORMATION"),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_nameCtrl, "Vendor Name", Icons.storefront, flex: 2),
            _tf(_mobileCtrl, "Contact No", Icons.phone, isNum: true),
          ]),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _tf(_addrCtrl, "Billing Address", Icons.location_on, maxLines: 2),
          ),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_cityCtrl, "City", Icons.location_city),
            _tf(_pinCtrl, "Pin Code", Icons.pin_drop, isNum: true),
            _tf(_emailCtrl, "Email Address", Icons.email, flex: 2),
          ]),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_gstCtrl, "GST Number", Icons.receipt),
            _tf(_panCtrl, "PAN Number", Icons.badge),
          ]),
          const SizedBox(height: 30),
          _sectionLabel("BANKING & PAYMENT TERMS"),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_bankCtrl, "Bank Name", Icons.account_balance),
            _tf(_accCtrl, "Account No", Icons.numbers, isNum: true, flex: 2),
            _tf(_ifscCtrl, "IFSC Code", Icons.code),
          ]),
          const SizedBox(height: 30),
          _sectionLabel("ACCOUNTS & LEDGER"),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_daysCtrl, "Credit Period (Days)", Icons.timer, isNum: true),
            _tf(_crCtrl, "Opening CR", Icons.add_circle, color: Colors.green, isNum: true),
            _tf(_drCtrl, "Opening DR", Icons.remove_circle, color: Colors.red, isNum: true),
          ]),
          const SizedBox(height: 30),
          ExpansionTile(
            title: const Text("SHIPPING / RETURN WAREHOUSE (OPTIONAL)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            tilePadding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 15),
              _tf(_sNameCtrl, "Consignee Name", Icons.person_pin),
              const SizedBox(height: 15),
              _tf(_sAddrCtrl, "Shipping Address", Icons.map, maxLines: 2),
              const SizedBox(height: 15),
              _responsiveRow(width, [
                _tf(_sCityCtrl, "Ship City", Icons.apartment),
                _tf(_sPinCtrl, "Ship Pin", Icons.pin, isNum: true),
                _tf(_sGstCtrl, "Ship GST", Icons.verified),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // --- RESPONSIVE & ENTER KEY HELPER ---
  Widget _responsiveRow(double width, List<Widget> children) {
    if (width < 600) {
      return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 15), child: c)).toList());
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((c) => Expanded(flex: (c is _FlexWidget) ? c.flex : 1, child: Padding(padding: const EdgeInsets.only(right: 15), child: c))).toList());
  }

  Widget _tf(TextEditingController c, String l, IconData i, {int maxLines = 1, Color? color, bool isNum = false, int flex = 1}) {
    return _FlexWidget(
      flex: flex,
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        style: TextStyle(color: color, fontSize: 13),
        // ENTER KEY NAVIGATION:
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        // NUMERIC HANDLING:
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, size: 18),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  // --- REST OF UI (DRAWER & CARDS) ---
  Widget _buildRightHistoryDrawer() {
    double w = MediaQuery.of(context).size.width;
    return Drawer(
      width: w > 850 ? 850 : w * 0.9,
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), color: const Color(0xFF1A1C24), child: const SafeArea(child: Row(children: [Icon(Icons.inventory_2, color: Colors.white), SizedBox(width: 15), Text("SUPPLIER DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]))),
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() {}), decoration: InputDecoration(hintText: "Search...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        Expanded(child: BlocBuilder<SupplierBloc, SupplierState>(builder: (context, state) {
          if (state is SupplierLoaded) {
            final list = state.suppliers.where((e) => e.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) || e.mobileNo.contains(_searchCtrl.text)).toList();
            return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: list.length, itemBuilder: (ctx, i) => _buildDetailCard(list[i]));
          }
          return const Center(child: CircularProgressIndicator());
        })),
      ]),
    );
  }
  Widget _buildDetailCard(SupplierEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        children: [
          // Header Section (First Version Style)
          Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade50,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                          item.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        )
                    ),
                    _badge(item.batchNumber)
                  ]
              )
          ),
          // Body Section with Info Items
          Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  // Row 1: Contact, City, Bank
                  Wrap(
                    runSpacing: 12,
                    spacing: 10,
                    children: [
                      SizedBox(width: 160, child: _infoItem("Contact", item.mobileNo, Icons.phone)),
                      SizedBox(width: 140, child: _infoItem("City", item.city, Icons.location_city)),
                      SizedBox(width: 160, child: _infoItem("Bank", item.bankName, Icons.account_balance)),
                    ],
                  ),
                  const Divider(height: 25),
                  // Row 2: Opening CR, Opening DR, GST
                  Wrap(
                    runSpacing: 12,
                    spacing: 10,
                    children: [
                      SizedBox(width: 160, child: _infoItem("Opening CR", "₹${item.openingCr}", Icons.add_circle, color: Colors.green)),
                      SizedBox(width: 140, child: _infoItem("Opening DR", "₹${item.openingDr}", Icons.remove_circle, color: Colors.red)),
                      SizedBox(width: 160, child: _infoItem("GST", item.gstNumber, Icons.receipt)),
                    ],
                  ),
                  const Divider(height: 25),
                  // Row 3: Addresses
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _infoItem("Billing Address", item.address, Icons.home)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoItem("Shipping Address", item.sAddr, Icons.local_shipping)),
                    ],
                  ),
                ],
              )
          ),
          const Divider(height: 1),
          // Action Button
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: () => _onEdit(item),
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: const Text("EDIT RECORD", style: TextStyle(fontWeight: FontWeight.bold))
              )
          ),
        ],
      ),
    );
  }

  // --- infoItem also updated for Enter/Responsive support ---
  Widget _infoItem(String l, String v, IconData i, {Color? color}) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
                Icon(i, size: 12, color: Colors.grey),
                const SizedBox(width: 5),
                Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))
              ]
          ),
          const SizedBox(height: 4),
          Text(
              v.isEmpty ? "N/A" : v,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis
          )
        ]
    );
  }


  Widget _sectionLabel(String t) => Row(children: [Container(width: 4, height: 16, color: const Color(0xFF00BCD4)), const SizedBox(width: 10), Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey))]);
  Widget _badge(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text(t, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)));
}

class _FlexWidget extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexWidget({required this.flex, required this.child});
  @override
  Widget build(BuildContext context) => child;
}