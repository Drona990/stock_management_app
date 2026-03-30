import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA LAYER (Updated Model as per Image)
// ==========================================================================

class CustomerEntity {
  final int? id;
  final String name, address, mobile, city, pincode, email, gstNo;
  final String shipName, shipAddress, shipMobile, shipCity, shipPincode, shipGst;
  final double openingCr, openingDr;
  final String batchNo, createdBy;

  CustomerEntity({
    this.id, required this.name, required this.address, required this.mobile,
    required this.city, required this.pincode, required this.email, required this.gstNo,
    required this.shipName, required this.shipAddress, required this.shipMobile,
    required this.shipCity, required this.shipPincode, required this.shipGst,
    required this.openingCr, required this.openingDr,
    required this.batchNo, required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    "name": name, "address": address, "mobile_no": mobile, "city": city,
    "pin_code": pincode, "email": email, "gst_number": gstNo,
    "shipping_name": shipName, "shipping_address": shipAddress, "shipping_mobile_no": shipMobile,
    "shipping_city": shipCity, "shipping_pin_code": shipPincode, "shipping_gst_no": shipGst,
    "opening_balance_cr": openingCr, "opening_balance_dr": openingDr,
    "batch_number": batchNo, "created_by": createdBy,
  };

  factory CustomerEntity.fromJson(Map<String, dynamic> json) => CustomerEntity(
    id: json['customer_no'], // Map to primary key from image
    name: json['name'] ?? "",
    address: json['address'] ?? "",
    mobile: json['mobile_no'] ?? "",
    city: json['city'] ?? "",
    pincode: json['pin_code'] ?? "",
    email: json['email'] ?? "",
    gstNo: json['gst_number'] ?? "",
    shipName: json['shipping_name'] ?? "",
    shipAddress: json['shipping_address'] ?? "",
    shipMobile: json['shipping_mobile_no'] ?? "",
    shipCity: json['shipping_city'] ?? "",
    shipPincode: json['shipping_pin_code'] ?? "",
    shipGst: json['shipping_gst_no'] ?? "",
    openingCr: double.tryParse(json['opening_balance_cr'].toString()) ?? 0.0,
    openingDr: double.tryParse(json['opening_balance_dr'].toString()) ?? 0.0,
    batchNo: json['batch_number'] ?? "",
    createdBy: json['created_by'] ?? "ADMIN",
  );
}

class CustomerRepository {
  final ApiClient apiClient = sl<ApiClient>();
  Future<List<CustomerEntity>> fetchCustomers() async {
    final res = await apiClient.get('/api/master/customers/');
    return (res.data as List).map((e) => CustomerEntity.fromJson(e)).toList();
  }
  Future<CustomerEntity> saveCustomer(CustomerEntity entity) async {
    final bool isUpdate = entity.id != null;
    final String path = isUpdate ? '/api/master/customers/${entity.id}/' : '/api/master/customers/';
    final res = isUpdate ? await apiClient.put(path, data: entity.toJson()) : await apiClient.post(path, data: entity.toJson());
    return CustomerEntity.fromJson(res.data);
  }
}

// ==========================================================================
// 2. BLOC LAYER
// ==========================================================================

abstract class CustomerEvent {}
class LoadCustomers extends CustomerEvent {}
class SaveCustomerEvent extends CustomerEvent { final CustomerEntity customer; SaveCustomerEvent(this.customer); }

abstract class CustomerState {}
class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerLoaded extends CustomerState { final List<CustomerEntity> customers; CustomerLoaded(this.customers); }
class CustomerSuccess extends CustomerState { final String message; CustomerSuccess(this.message); }
class CustomerError extends CustomerState { final String error; CustomerError(this.error); }

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repo;
  CustomerBloc(this.repo) : super(CustomerInitial()) {
    on<LoadCustomers>((event, emit) async {
      emit(CustomerLoading());
      try {
        final data = await repo.fetchCustomers();
        emit(CustomerLoaded(data));
      } catch (e) { emit(CustomerError(e.toString())); }
    });
    on<SaveCustomerEvent>((event, emit) async {
      try {
        await repo.saveCustomer(event.customer);
        emit(CustomerSuccess("Process Successful!"));
        final data = await repo.fetchCustomers();
        emit(CustomerLoaded(data));
      } catch (e) { emit(CustomerError(e.toString())); }
    });
  }
}

// ==========================================================================
// 3. UI LAYER
// ==========================================================================

class CustomerMasterScreen extends StatefulWidget {
  const CustomerMasterScreen({super.key});
  @override
  State<CustomerMasterScreen> createState() => _CustomerMasterScreenState();
}

class _CustomerMasterScreenState extends State<CustomerMasterScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Billing Controllers
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  // Accounting
  final _crCtrl = TextEditingController(text: "0");
  final _drCtrl = TextEditingController(text: "0");

  // Shipping Controllers
  final _sNameCtrl = TextEditingController();
  final _sAddrCtrl = TextEditingController();
  final _sMobileCtrl = TextEditingController();
  final _sCityCtrl = TextEditingController();
  final _sPinCtrl = TextEditingController();
  final _sGstCtrl = TextEditingController();

  final _batchCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  CustomerEntity? editingCustomer;

  @override
  void initState() {
    super.initState();
    _batchCtrl.text = "CUST-${DateFormat('yyyyMMdd').format(DateTime.now())}";
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  void _onSave() {
    if (_nameCtrl.text.isEmpty) { _showSnackbar("Name is required!", Colors.orange); return; }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))));

    final customer = CustomerEntity(
      id: editingCustomer?.id,
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pinCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstNo: _gstCtrl.text.trim(),
      shipName: _sNameCtrl.text.isEmpty ? _nameCtrl.text : _sNameCtrl.text,
      shipAddress: _sAddrCtrl.text.isEmpty ? _addrCtrl.text : _sAddrCtrl.text,
      shipMobile: _sMobileCtrl.text.isEmpty ? _mobileCtrl.text : _sMobileCtrl.text,
      shipCity: _sCityCtrl.text.isEmpty ? _cityCtrl.text : _sCityCtrl.text,
      shipPincode: _sPinCtrl.text.isEmpty ? _pinCtrl.text : _sPinCtrl.text,
      shipGst: _sGstCtrl.text.isEmpty ? _gstCtrl.text : _sGstCtrl.text,
      openingCr: double.tryParse(_crCtrl.text) ?? 0.0,
      openingDr: double.tryParse(_drCtrl.text) ?? 0.0,
      batchNo: _batchCtrl.text,
      createdBy: "ADMIN",
    );
    context.read<CustomerBloc>().add(SaveCustomerEvent(customer));
  }

  void _onEdit(CustomerEntity item) {
    setState(() {
      editingCustomer = item;
      _nameCtrl.text = item.name; _mobileCtrl.text = item.mobile; _addrCtrl.text = item.address;
      _cityCtrl.text = item.city; _pinCtrl.text = item.pincode; _emailCtrl.text = item.email;
      _gstCtrl.text = item.gstNo; _crCtrl.text = item.openingCr.toString(); _drCtrl.text = item.openingDr.toString();
      _sNameCtrl.text = item.shipName; _sAddrCtrl.text = item.shipAddress; _sMobileCtrl.text = item.shipMobile;
      _sCityCtrl.text = item.shipCity; _sPinCtrl.text = item.shipPincode; _sGstCtrl.text = item.shipGst;
    });
    Navigator.pop(context);
  }

  void _resetForm() {
    setState(() {
      editingCustomer = null;
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl]) {
        c.clear();
      }
      _crCtrl.text = "0"; _drCtrl.text = "0";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerSuccess || state is CustomerError) { if (Navigator.of(context, rootNavigator: true).canPop()) Navigator.of(context, rootNavigator: true).pop(); }
        if (state is CustomerSuccess) { _showSnackbar(state.message, Colors.green); _resetForm(); }
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
                child: (state is CustomerLoading && editingCustomer == null)
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
                    : LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                      padding: EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 24),
                      child: Center(
                          child: Container(
                              constraints: const BoxConstraints(maxWidth: 1000),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: isMobile
          ? Column(
        children: [
          Text(
              editingCustomer == null ? "CUSTOMER MASTER ENTRY" : "EDIT CUSTOMER",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C24), fontSize: 14)
          ),
          const SizedBox(height: 12),
          // Wrap use kiya hai taaki buttons mobile pe fit ho jayein bina scroll ke
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10, // Horizontal gap
            runSpacing: 10, // Vertical gap (agar buttons niche wali line mein jayein)
            children: _actionButtons(isMobile),
          )
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              editingCustomer == null ? "CUSTOMER MASTER ENTRY" : "EDIT CUSTOMER",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C24), fontSize: 16)
          ),
          Row(children: _actionButtons(false)),
        ],
      ),
    );
  }

  List<Widget> _actionButtons(bool isMobile) => [
    _badge("BATCH: ${_batchCtrl.text}"),
    // Mobile pe thoda gap manage karne ke liye spacing logic
    if (!isMobile) const SizedBox(width: 15),

    IconButton(
      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      icon: const Icon(Icons.history, size: 22, color: Colors.blueGrey),
      visualDensity: VisualDensity.compact, // Space bachane ke liye
    ),

    if (editingCustomer != null)
      IconButton(
        icon: const Icon(Icons.cancel, color: Colors.red),
        onPressed: _resetForm,
        visualDensity: VisualDensity.compact,
      ),

    if (!isMobile) const SizedBox(width: 10),

    ElevatedButton(
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          padding: isMobile ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(editingCustomer == null ? "SAVE" : "UPDATE")
    ),
  ];

  Widget _buildFormCard(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("BILLING INFORMATION"),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_nameCtrl, "Customer Name", Icons.person, flex: 2),
            _tf(_mobileCtrl, "Mobile No", Icons.phone_android, isNum: true),
          ]),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _tf(_addrCtrl, "Address", Icons.location_on, maxLines: 2),
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
            _tf(_crCtrl, "Balance CR", Icons.add_circle, color: Colors.green, isNum: true),
            _tf(_drCtrl, "Balance DR", Icons.remove_circle, color: Colors.red, isNum: true),
          ]),
          const SizedBox(height: 30),
          _sectionLabel("SHIPPING INFORMATION"),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_sNameCtrl, "Shipping Name", Icons.local_shipping, flex: 2),
            _tf(_sMobileCtrl, "Shipping Mobile", Icons.phone_callback, isNum: true),
          ]),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(right:12),
            child: _tf(_sAddrCtrl, "Shipping Address", Icons.map, maxLines: 2),
          ),
          const SizedBox(height: 15),
          _responsiveRow(width, [
            _tf(_sCityCtrl, "Ship City", Icons.apartment),
            _tf(_sPinCtrl, "Ship Pincode", Icons.mark_as_unread, isNum: true),
            _tf(_sGstCtrl, "Ship GST", Icons.verified),
          ]),
        ],
      ),
    );
  }

  // --- RESPONSIVE HELPER ---
  Widget _responsiveRow(double width, List<Widget> children) {
    if (width < 600) {
      return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 15), child: c)).toList());
    }
    return Row(children: children.map((c) => Expanded(flex: (c is _FlexWidget) ? c.flex : 1, child: Padding(padding: const EdgeInsets.only(right: 15), child: c))).toList());
  }

  // --- REPLACED _tf TO HANDLE NUMBERS & FLEX ---
  Widget _tf(TextEditingController c, String l, IconData i, {int maxLines = 1, Color? color, bool isNum = false, int flex = 1}) {
    return _FlexWidget(
      flex: flex,
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        style: TextStyle(color: color, fontSize: 13),
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: isNum ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, size: 19),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildRightHistoryDrawer() {
    double w = MediaQuery.of(context).size.width;
    return Drawer(
      width: w > 850 ? 850 : w * 0.9,
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), color: const Color(0xFF1A1C24), child: const SafeArea(child: Row(children: [Icon(Icons.grid_on, color: Colors.white), SizedBox(width: 15), Text("CUSTOMER DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]))),
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchCtrl, onChanged: (v) => setState(() {}), decoration: InputDecoration(hintText: "Search...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        Expanded(child: BlocBuilder<CustomerBloc, CustomerState>(builder: (context, state) {
          if (state is CustomerLoaded) {
            final list = state.customers.where((e) => e.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();
            return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: list.length, itemBuilder: (ctx, i) => _buildDetailCard(list[i]));
          }
          return const Center(child: CircularProgressIndicator());
        })),
      ]),
    );
  }

  Widget _buildDetailCard(CustomerEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12), color: Colors.grey.shade50, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 12)), _badge(item.batchNo)])),
        Padding(padding: const EdgeInsets.all(15), child: Column(children: [
          _infoGrid(item),
          const Divider(height: 25),
          _infoItem("Billing Address", item.address, Icons.home),
          const SizedBox(height: 10),
          _infoItem("Shipping Address", item.shipAddress, Icons.local_shipping),
        ])),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _onEdit(item), icon: const Icon(Icons.edit, size: 18), label: const Text("EDIT"))),
      ]),
    );
  }

  Widget _infoGrid(CustomerEntity item) {
    return Wrap(runSpacing: 10, children: [
      SizedBox(width: 150, child: _infoItem("Mobile", item.mobile, Icons.phone)),
      SizedBox(width: 150, child: _infoItem("City", item.city, Icons.location_city)),
      SizedBox(width: 150, child: _infoItem("Opening CR", "₹${item.openingCr}", Icons.add_circle, color: Colors.green)),
    ]);
  }

  Widget _infoItem(String l, String v, IconData i, {Color? color}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(i, size: 12, color: Colors.grey), const SizedBox(width: 5), Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))]), const SizedBox(height: 4), Text(v.isEmpty ? "N/A" : v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.black87))]);
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