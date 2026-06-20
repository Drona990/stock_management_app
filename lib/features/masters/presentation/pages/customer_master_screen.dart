/*
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
  final String name, address, mobile, city, pincode, email, gstNo,bankName,accountNo, bankAddress, ifscCode;
  final String shipName, shipAddress, shipMobile, shipCity, shipPincode, shipGst;
  final double openingCr, openingDr;
  final String batchNo, createdBy;

  CustomerEntity({
    this.id, required this.name, required this.address, required this.mobile,
    required this.city, required this.pincode, required this.email, required this.gstNo,
    required this.shipName, required this.shipAddress, required this.shipMobile,
    required this.shipCity, required this.shipPincode, required this.shipGst,
    required this.openingCr, required this.openingDr,
    required this.batchNo, required this.createdBy, required this.bankName,required this.bankAddress,required this.accountNo,required this.ifscCode,
  });

  Map<String, dynamic> toJson() => {
    "name": name, "address": address, "mobile_no": mobile, "city": city,
    "pin_code": pincode, "email": email, "gst_number": gstNo,
    "shipping_name": shipName, "shipping_address": shipAddress, "shipping_mobile_no": shipMobile,
    "shipping_city": shipCity, "shipping_pin_code": shipPincode, "shipping_gst_no": shipGst,
    "opening_balance_cr": openingCr, "opening_balance_dr": openingDr,
    "batch_number": batchNo, "created_by": createdBy,
    "bank_name": bankName,
    "bank_address": bankAddress,
    "account_no": accountNo,
    "ifsc_code": ifscCode,
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
    bankName: json['bank_name'] ?? "",
    bankAddress: json['bank_address'] ?? "",
    accountNo: json['account_no'] ?? "",
    ifscCode: json['ifsc_code'] ?? "",
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
    print("customer response $res");

    // ✅ FIX: Paginated response me se 'results' key ko extract kiya
    if (res.data is Map && res.data['results'] != null) {
      final List listData = res.data['results'] as List;
      return listData.map((e) => CustomerEntity.fromJson(e)).toList();
    }

    // Fallback agar direct array bina pagination ke aaye
    if (res.data is List) {
      return (res.data as List).map((e) => CustomerEntity.fromJson(e)).toList();
    }

    return [];
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
      } catch (e) {
        String errorMsg = "Something went wrong";

        if (e.toString().contains("already exists")) {
          errorMsg = "Customer with this name already exists!";
        } else if (e.toString().contains("400")) {
          errorMsg = "Validation Failed: Customer with this name already exists!.";
        } else {
          errorMsg = e.toString();
        }

        emit(CustomerError(errorMsg));
      }
    });  }
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

  // Bank details
  final _bankCtrl = TextEditingController();
  final _bankAddressCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

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
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5)));

    final customer = CustomerEntity(
      id: editingCustomer?.id,
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pinCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstNo: _gstCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      accountNo: _accCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim(),
      bankAddress: _bankAddressCtrl.text.trim(),
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
      _bankCtrl.text = item.bankName; _accCtrl.text = item.accountNo; _ifscCtrl.text = item.ifscCode;_bankAddressCtrl.text = item.bankAddress;
    });
    Navigator.pop(context);
  }

  void _resetForm() {
    setState(() {
      editingCustomer = null;
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl,_bankCtrl,_bankAddressCtrl,_accCtrl,_ifscCtrl]) {
        c.clear();
      }
      _crCtrl.text = "0"; _drCtrl.text = "0";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 11)), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerSuccess || state is CustomerError) {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
        if (state is CustomerSuccess) {
          _showSnackbar(state.message, Colors.green);
          _resetForm();
        }
        if (state is CustomerError) {
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
                child: (state is CustomerLoading && editingCustomer == null)
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
        children: [
          Text(
              (editingCustomer == null ? "CUSTOMER MASTER ENTRY" : "EDIT CUSTOMER").toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: industrialSlate, fontSize: 13, letterSpacing: 0.3)
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
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
              (editingCustomer == null ? "CUSTOMER MASTER ENTRY" : "EDIT CUSTOMER").toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, color: industrialSlate, fontSize: 13, letterSpacing: 0.3)
          ),
          Row(children: _actionButtons(false)),
        ],
      ),
    );
  }

  List<Widget> _actionButtons(bool isMobile) => [
    _badge("BATCH: ${_batchCtrl.text}"),
    if (!isMobile) const SizedBox(width: 4),
    IconButton(
      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      icon: const Icon(Icons.history_rounded, size: 18, color: Colors.blueGrey),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    ),
    const SizedBox(width: 4),
    if (editingCustomer != null)
      IconButton(
        icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18),
        onPressed: _resetForm,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
      ),
    const SizedBox(width: 4),
    ElevatedButton(
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text((editingCustomer == null ? "SAVE" : "UPDATE").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
    ),
  ];

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
          _sectionLabel("BILLING INFORMATION"),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(
                _nameCtrl,
                "Customer Name",
                Icons.person_outline_rounded,
                flex: 2,
                readOnly: editingCustomer != null
            ),
            _tf(_mobileCtrl, "Mobile No", Icons.phone_android_rounded, isNum: true),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: _tf(_addrCtrl, "Address", Icons.location_on_outlined, maxLines: 2),
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
            _tf(_crCtrl, "Balance CR", Icons.add_circle_outline_rounded,
                color: Colors.green,
                isNum: true,
                onCh: (v) {
                  if (v.isNotEmpty && v != "0") {
                    setState(() { _drCtrl.text = "0"; });
                  }
                }
            ),
            _tf(_drCtrl, "Balance DR", Icons.remove_circle_outline_rounded,
                color: Colors.redAccent,
                isNum: true,
                onCh: (v) {
                  if (v.isNotEmpty && v != "0") {
                    setState(() { _crCtrl.text = "0"; });
                  }
                }
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel("BANKING & PAYMENT TERMS"),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_bankCtrl, "Bank Name", Icons.account_balance_rounded),
            _tf(_accCtrl, "Account No", Icons.numbers_outlined, isNum: true, flex: 2),
            _tf(_ifscCtrl, "IFSC Code", Icons.code_rounded),
            _tf(_bankAddressCtrl, "Branch & Address Details", Icons.location_on_outlined),
          ]),
          const SizedBox(height: 20),
          _sectionLabel("SHIPPING INFORMATION"),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_sNameCtrl, "Shipping Name", Icons.local_shipping_outlined, flex: 2),
            _tf(_sMobileCtrl, "Shipping Mobile", Icons.phone_callback_outlined, isNum: true),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: _tf(_sAddrCtrl, "Shipping Address", Icons.map_outlined, maxLines: 2),
          ),
          const SizedBox(height: 12),
          _responsiveRow(width, [
            _tf(_sCityCtrl, "Ship City", Icons.apartment_rounded),
            _tf(_sPinCtrl, "Ship Pincode", Icons.mark_as_unread_outlined, isNum: true),
            _tf(_sGstCtrl, "Ship GST", Icons.verified_outlined),
          ]),
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
                      Icon(Icons.grid_on_outlined, color: Colors.cyanAccent, size: 16),
                      SizedBox(width: 10),
                      Text("CUSTOMER DATABASE DIRECTORY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3))
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
            child: BlocBuilder<CustomerBloc, CustomerState>(builder: (context, state) {
              if (state is CustomerLoaded) {
                final list = state.customers.where((e) => e.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();
                return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: list.length, itemBuilder: (ctx, i) => _buildDetailCard(list[i]));
              }
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
            })
        ),
      ]),
    );
  }

  Widget _buildDetailCard(CustomerEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
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
                  _badge(item.batchNo)
                ]
            )
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          _infoGrid(item),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _infoItem("Billing Address", item.address, Icons.home_outlined),
          const SizedBox(height: 6),
          _infoItem("Shipping Address", item.shipAddress, Icons.local_shipping_outlined),
          const SizedBox(height: 6),
          _infoItem("Bank Address", item.bankAddress, Icons.location_on_outlined),
        ])),
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
      ]),
    );
  }

  Widget _infoGrid(CustomerEntity item) {
    return Wrap(runSpacing: 10, spacing: 12, children: [
      SizedBox(width: 150, child: _infoItem("Mobile", item.mobile, Icons.phone_android_rounded)),
      SizedBox(width: 140, child: _infoItem("City", item.city, Icons.location_city_rounded)),
      SizedBox(width: 150, child: _infoItem("Opening CR", "₹${item.openingCr}", Icons.add_circle_outline_rounded, color: Colors.green)),
      SizedBox(width: 150, child: _infoItem("Bank Name", item.bankName, Icons.account_balance_rounded, color: Colors.black87)),
      SizedBox(width: 150, child: _infoItem("Acc No", item.accountNo, Icons.numbers_outlined, color: Colors.black87)),
    ]);
  }

  Widget _infoItem(String l, String v, IconData i, {Color? color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(i, size: 11, color: Colors.grey),
          const SizedBox(width: 4),
          Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 2),
        Text(v.isEmpty ? "N/A" : v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis)
      ]
  );

  Widget _sectionLabel(String t) => Row(children: [Container(width: 3, height: 12, color: const Color(0xFF00BCD4)), const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.2))]);
  Widget _badge(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(2)), child: Text(t, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 9)));
}

class _FlexWidget extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexWidget({required this.flex, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
*/


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA LAYER (Matches Django BaseMaster Exactly)
// ==========================================================================
class CustomerEntity {
  final int? id;
  final String name, address, mobile, city, pincode, email, gstNo, bankName, accountNo, bankAddress, ifscCode;
  final String shipName, shipAddress, shipMobile, shipCity, shipPincode, shipGst;
  final double openingCr, openingDr;
  final String batchNo, createdBy;

  CustomerEntity({
    this.id, required this.name, required this.address, required this.mobile,
    required this.city, required this.pincode, required this.email, required this.gstNo,
    required this.shipName, required this.shipAddress, required this.shipMobile,
    required this.shipCity, required this.shipPincode, required this.shipGst,
    required this.openingCr, required this.openingDr,
    required this.batchNo, required this.createdBy, required this.bankName, required this.bankAddress, required this.accountNo, required this.ifscCode,
  });

  Map<String, dynamic> toJson() => {
    "name": name, "address": address, "mobile_no": mobile, "city": city,
    "pin_code": pincode, "email": email, "gst_number": gstNo,
    "shipping_name": shipName, "shipping_address": shipAddress, "shipping_mobile_no": shipMobile,
    "shipping_city": shipCity, "shipping_pin_code": shipPincode, "shipping_gst_no": shipGst,
    "opening_balance_cr": openingCr, "opening_balance_dr": openingDr,
    "batch_number": batchNo, "created_by": createdBy,
    "bank_name": bankName,
    "bank_address": bankAddress,
    "account_no": accountNo,
    "ifsc_code": ifscCode,
  };

  factory CustomerEntity.fromJson(Map<String, dynamic> json) => CustomerEntity(
    id: json['customer_no'] ?? json['id'],
    name: json['name'] ?? "",
    address: json['address'] ?? "",
    mobile: json['mobile_no'] ?? "",
    city: json['city'] ?? "",
    pincode: json['pin_code'] ?? "",
    email: json['email'] ?? "",
    gstNo: json['gst_number'] ?? "",
    bankName: json['bank_name'] ?? "",
    bankAddress: json['bank_address'] ?? "",
    accountNo: json['account_no'] ?? "",
    ifscCode: json['ifsc_code'] ?? "",
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
    if (res.data is Map && res.data['results'] != null) {
      final List listData = res.data['results'] as List;
      return listData.map((e) => CustomerEntity.fromJson(e)).toList();
    }
    if (res.data is List) {
      return (res.data as List).map((e) => CustomerEntity.fromJson(e)).toList();
    }
    return [];
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
        emit(CustomerSuccess("Customer Data Synced Successfully!"));
        final data = await repo.fetchCustomers();
        emit(CustomerLoaded(data));
      } catch (e) {
        String errorMsg = "Something went wrong";
        if (e.toString().contains("already exists")) {
          errorMsg = "Customer with this name already exists!";
        } else if (e.toString().contains("400")) {
          errorMsg = "Validation Failed: Customer with this name already exists!";
        } else {
          errorMsg = e.toString();
        }
        emit(CustomerError(errorMsg));
      }
    });
  }
}

// ==========================================================================
// 3. UI LAYER (High Density Split Canvas Surface)
// ==========================================================================
class CustomerMasterScreen extends StatefulWidget {
  const CustomerMasterScreen({super.key});
  @override
  State<CustomerMasterScreen> createState() => _CustomerMasterScreenState();
}

class _CustomerMasterScreenState extends State<CustomerMasterScreen> {
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

  // Bank details
  final _bankCtrl = TextEditingController();
  final _bankAddressCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

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
    if (_nameCtrl.text.trim().isEmpty) { _showSnackbar("Customer Name is required!", Colors.orange); return; }
    String mobile = _mobileCtrl.text.trim();
    if (mobile.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      _showSnackbar("Enter a valid 10-digit Mobile Number!", Colors.red); return;
    }

    final customer = CustomerEntity(
      id: editingCustomer?.id,
      name: _nameCtrl.text.trim(),
      mobile: mobile,
      address: _addrCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pinCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      gstNo: _gstCtrl.text.trim().toUpperCase(),
      bankName: _bankCtrl.text.trim().toUpperCase(),
      accountNo: _accCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      bankAddress: _bankAddressCtrl.text.trim(),
      shipName: _sNameCtrl.text.isEmpty ? _nameCtrl.text.trim() : _sNameCtrl.text.trim(),
      shipAddress: _sAddrCtrl.text.isEmpty ? _addrCtrl.text.trim() : _sAddrCtrl.text.trim(),
      shipMobile: _sMobileCtrl.text.isEmpty ? mobile : _sMobileCtrl.text.trim(),
      shipCity: _sCityCtrl.text.isEmpty ? _cityCtrl.text.trim() : _sCityCtrl.text.trim(),
      shipPincode: _sPinCtrl.text.isEmpty ? _pinCtrl.text.trim() : _sPinCtrl.text.trim(),
      shipGst: _sGstCtrl.text.isEmpty ? _gstCtrl.text.trim().toUpperCase() : _sGstCtrl.text.trim().toUpperCase(),
      openingCr: double.tryParse(_crCtrl.text) ?? 0.0,
      openingDr: double.tryParse(_drCtrl.text) ?? 0.0,
      batchNo: _batchCtrl.text,
      createdBy: "ADMIN",
    );
    context.read<CustomerBloc>().add(SaveCustomerEvent(customer));
  }

  void _populateForm(CustomerEntity item) {
    setState(() {
      editingCustomer = item;
      _nameCtrl.text = item.name; _mobileCtrl.text = item.mobile; _addrCtrl.text = item.address;
      _cityCtrl.text = item.city; _pinCtrl.text = item.pincode; _emailCtrl.text = item.email;
      _gstCtrl.text = item.gstNo; _crCtrl.text = item.openingCr.toString(); _drCtrl.text = item.openingDr.toString();
      _sNameCtrl.text = item.shipName; _sAddrCtrl.text = item.shipAddress; _sMobileCtrl.text = item.shipMobile;
      _sCityCtrl.text = item.shipCity; _sPinCtrl.text = item.shipPincode; _sGstCtrl.text = item.shipGst;
      _bankCtrl.text = item.bankName; _accCtrl.text = item.accountNo; _ifscCtrl.text = item.ifscCode; _bankAddressCtrl.text = item.bankAddress;
    });
  }

  void _resetForm() {
    setState(() {
      editingCustomer = null;
      for (var c in [_nameCtrl, _mobileCtrl, _addrCtrl, _cityCtrl, _pinCtrl, _emailCtrl, _gstCtrl, _sNameCtrl, _sAddrCtrl, _sMobileCtrl, _sCityCtrl, _sPinCtrl, _sGstCtrl, _bankCtrl, _bankAddressCtrl, _accCtrl, _ifscCtrl]) {
        c.clear();
      }
      _crCtrl.text = "0"; _drCtrl.text = "0";
    });
  }

  void _showSnackbar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool useSplitView = screenWidth > 900;

    return BlocConsumer<CustomerBloc, CustomerState>(
      listener: (context, state) {
        if (state is CustomerSuccess) {
          _showSnackbar(state.message, Colors.green);
          _resetForm();
        }
        if (state is CustomerError) {
          _showSnackbar(state.error, Colors.redAccent);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ➡️ LEFT SIDE: DIRECTORY PANE
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
                Icon(Icons.grid_on_outlined, color: Colors.cyanAccent, size: 16),
                SizedBox(width: 10),
                Text("CUSTOMER DIRECTORY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5))
              ],
            ),
          ),
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
                  hintText: "Search customer records...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent));
                }
                if (state is CustomerLoaded) {
                  final filteredList = state.customers.where((e) {
                    final query = _searchCtrl.text.toLowerCase();
                    return e.name.toLowerCase().contains(query) || e.mobile.contains(query);
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text("No records found", style: TextStyle(color: Colors.grey, fontSize: 11)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, idx) {
                      final item = filteredList[idx];
                      bool isSelected = editingCustomer?.id == item.id;
                      return ListTile(
                        onTap: () => _populateForm(item),
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF1E293B),
                        title: Text(item.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? Colors.cyanAccent : Colors.white)),
                        subtitle: Text("Mob: ${item.mobile} | GST: ${item.gstNo.isEmpty ? 'N/A' : item.gstNo}", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
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
                (editingCustomer == null ? "CUSTOMER MASTER SETUP DATA" : "MODIFY CUSTOMER SNAPSHOT").toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
              ),
              if (editingCustomer != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.orange.shade100,
                  child: Text("EDITING REG: ${editingCustomer!.id}", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 9)),
                )
              ]
            ],
          ),
          Row(
            children: [
              _badge("BATCH: ${_batchCtrl.text}"),
              const SizedBox(width: 12),
              if (editingCustomer != null)
                TextButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.red),
                  label: const Text("CANCEL", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _onSave,
                icon: Icon(editingCustomer == null ? Icons.save_outlined : Icons.done_all_rounded, size: 14),
                label: Text((editingCustomer == null ? "SAVE CLIENT" : "UPDATE PROFILE").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(),
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
        _buildSectionHeader("1. CLIENT REGISTRATION SCHEMA DETAILS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _sharpTextField(_nameCtrl, "Customer / Company Name *")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_mobileCtrl, "Primary Mobile No *", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_emailCtrl, "Email Workspace Address")),
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
            Expanded(child: _sharpTextField(_gstCtrl, "GSTIN Compliance Number")),
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
        _buildSectionHeader("2. CLIENT BANKING ACCOUNT CREDENTIALS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_bankCtrl, "Bank Name")),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _sharpTextField(_accCtrl, "Bank Account Number", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_ifscCtrl, "IFSC Remittance Code")),
          ],
        ),
        const SizedBox(height: 12),
        _sharpTextField(_bankAddressCtrl, "Branch Location & Address Details"),

        const SizedBox(height: 24),
        _buildSectionHeader("3. CORE LOGISTICS & SHIPPING DESTINATIONS"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _sharpTextField(_sNameCtrl, "Shipping Consignee Name")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_sMobileCtrl, "Shipping Contact Mobile", isNum: true)),
          ],
        ),
        const SizedBox(height: 12),
        _sharpTextField(_sAddrCtrl, "Consignment Delivery Shipping Address"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _sharpTextField(_sCityCtrl, "Shipping Destination City")),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_sPinCtrl, "Shipping Terminal Pincode", isNum: true)),
            const SizedBox(width: 12),
            Expanded(child: _sharpTextField(_sGstCtrl, "Shipping Location GSTIN")),
          ],
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
      label: const Text("VIEW CUSTOMER REGISTRY DIRECTORY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 36),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

// ✅ FIXED: Added missing _badge helper widget method
Widget _badge(String t) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.zero, // Pure sharp edge as per industrial rules
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

class _FlexWidget extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexWidget({required this.flex, required this.child});
  @override
  Widget build(BuildContext context) => child;
}