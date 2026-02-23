import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. DATA LAYER (Model & Repository)
// ==========================================================================

class DiscountModel {
  final int? id;
  final String name;
  final String discountType;
  final String valueType;
  final double value;
  final String? code;
  final double minPurchase;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validTo;

  DiscountModel({
    this.id,
    required this.name,
    required this.discountType,
    required this.valueType,
    required this.value,
    this.code,
    required this.minPurchase,
    required this.isActive,
    this.validFrom,
    this.validTo,
  });

  // Helper for partial UI updates
  DiscountModel copyWith({bool? isActive}) {
    return DiscountModel(
      id: id,
      name: name,
      discountType: discountType,
      valueType: valueType,
      value: value,
      code: code,
      minPurchase: minPurchase,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  factory DiscountModel.fromJson(Map<String, dynamic> json) => DiscountModel(
    id: json['id'],
    name: json['name'],
    discountType: json['discount_type'],
    valueType: json['value_type'],
    value: double.parse(json['value'].toString()),
    code: json['code'],
    minPurchase: double.parse(json['min_purchase'].toString()),
    isActive: json['is_active'] ?? true,
    validFrom: json['valid_from'] != null ? DateTime.parse(json['valid_from']) : null,
    validTo: json['valid_to'] != null ? DateTime.parse(json['valid_to']) : null,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "discount_type": discountType,
    "value_type": valueType,
    "value": value,
    "code": (code == null || code!.isEmpty) ? null : code,
    "min_purchase": minPurchase,
    "is_active": isActive,
    "valid_from": validFrom?.toIso8601String(),
    "valid_to": validTo?.toIso8601String(),
  };
}

class DiscountRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<DiscountModel>> getDiscounts() async {
    final response = await apiClient.get('/api/discounts/');
    // Handling Django Pagination 'results' key
    if (response.data is Map && response.data.containsKey('results')) {
      return (response.data['results'] as List).map((x) => DiscountModel.fromJson(x)).toList();
    }
    return (response.data as List).map((x) => DiscountModel.fromJson(x)).toList();
  }

  Future<void> createDiscount(DiscountModel discount) async {
    await apiClient.post('/api/discounts/', data: discount.toJson());
  }

  Future<void> toggleDiscount(int id, bool status) async {
    await apiClient.patch('/api/discounts/$id/', data: {"is_active": status});
  }

  Future<String> generateCode() async {
    final response = await apiClient.get('/api/discounts/generate_code/');
    return response.data['code'];
  }
}

// ==========================================================================
// 2. DOMAIN LAYER (Events & States)
// ==========================================================================

abstract class DiscountEvent {}
class LoadDiscounts extends DiscountEvent {}
class AddDiscount extends DiscountEvent { final DiscountModel discount; AddDiscount(this.discount); }
class ToggleDiscountStatus extends DiscountEvent {
  final int id;
  final bool status;
  ToggleDiscountStatus(this.id, this.status);
}

abstract class DiscountState {}
class DiscountInitial extends DiscountState {}
class DiscountLoading extends DiscountState {}
class DiscountLoaded extends DiscountState {
  final List<DiscountModel> discounts;
  DiscountLoaded(this.discounts);
}
class DiscountError extends DiscountState { final String message; DiscountError(this.message); }

// ==========================================================================
// 3. BLOC LAYER (Business Logic)
// ==========================================================================

class DiscountBloc extends Bloc<DiscountEvent, DiscountState> {
  final DiscountRepository repository;

  DiscountBloc(this.repository) : super(DiscountInitial()) {
    on<LoadDiscounts>((event, emit) async {
      emit(DiscountLoading());
      try {
        final data = await repository.getDiscounts();
        emit(DiscountLoaded(data));
      } catch (e) { emit(DiscountError(e.toString())); }
    });

    on<ToggleDiscountStatus>((event, emit) async {
      final currentState = state;
      if (currentState is DiscountLoaded) {
        // Optimistic Update: UI update pehle, Backend baad mein
        final updatedList = currentState.discounts.map((item) {
          return item.id == event.id ? item.copyWith(isActive: event.status) : item;
        }).toList();
        emit(DiscountLoaded(updatedList));

        try {
          await repository.toggleDiscount(event.id, event.status);
        } catch (e) {
          add(LoadDiscounts()); // Error par purana data reload karein
        }
      }
    });

    on<AddDiscount>((event, emit) async {
      try {
        await repository.createDiscount(event.discount);
        add(LoadDiscounts());
      } catch (e) { debugPrint(e.toString()); }
    });
  }
}

// ==========================================================================
// 4. UI LAYER (Presentation)
// ==========================================================================

class OfferManagementTab extends StatefulWidget {
  const OfferManagementTab({super.key});
  @override
  State<OfferManagementTab> createState() => _OfferManagementTabState();
}


// Industrial Color Palette
const Color kPrimary = Color(0xFF0F172A);
const Color kSlate500 = Color(0xFF64748B);
const Color kSlate100 = Color(0xFFF1F5F9);
const Color kEmerald = Color(0xFF10B981);
const Color kDanger = Color(0xFFEF4444);


class _OfferManagementTabState extends State<OfferManagementTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DiscountRepository _repo = DiscountRepository();
  late DiscountBloc _discountBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _discountBloc = DiscountBloc(_repo)..add(LoadDiscounts());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _discountBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          title: BlocBuilder<DiscountBloc, DiscountState>(
            builder: (context, state) {
              if (state is DiscountLoaded) {
                final active = state.discounts.where((d) => d.isActive).length;
                final inactive = state.discounts.length - active;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side: Business Stats
                    Row(
                      children: [
                        _buildStatCard("Active", active.toString(), kEmerald),
                        const SizedBox(width: 12),
                        _buildStatCard("Paused", inactive.toString(), kSlate500),
                      ],
                    ),

                    // Right Side: Professional Create Button
                    ElevatedButton.icon(
                      onPressed: () => _showProfessionalDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        "NEW OFFER",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kSlate100))),
              child: TabBar(
                controller: _tabController,
                labelColor: kPrimary,
                unselectedLabelColor: kSlate500,
                indicatorColor: kPrimary,
                tabs: const [Tab(text: "THRESHOLD"), Tab(text: "FESTIVAL"), Tab(text: "COUPONS")],
              ),
            ),
          ),
        ),
        body: BlocBuilder<DiscountBloc, DiscountState>(
          builder: (context, state) {
            if (state is DiscountLoading) return const Center(child: CircularProgressIndicator());
            if (state is DiscountLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(state.discounts, 'THRESHOLD'),
                  _buildList(state.discounts, 'FESTIVAL'),
                  _buildList(state.discounts, 'COUPON'),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildList(List<DiscountModel> items, String type) {
    final filtered = items.where((i) => i.discountType == type).toList();
    if (filtered.isEmpty) return const Center(child: Text("No records found"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildIndustrialCard(filtered[index]),
    );
  }

  Widget _buildIndustrialCard(DiscountModel item) {

    final bool isExpired = item.validTo != null && item.validTo!.isBefore(DateTime.now());
    final Color cardColor = isExpired ? kDanger.withOpacity(0.05) : Colors.white;
    final Color textColor = isExpired ? kDanger : kPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isExpired ? kDanger.withOpacity(0.2) : kSlate100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                    if (isExpired)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(4)),
                        child: const Text("EXPIRED", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("${item.value}${item.valueType == 'PERCENT' ? '%' : '₹'} Off | Min ₹${item.minPurchase}", style: const TextStyle(color: kSlate500, fontSize: 12)),
                if (item.validTo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("Ends: ${DateFormat('dd MMM yyyy').format(item.validTo!)}", style: TextStyle(fontSize: 11, color: isExpired ? kDanger : kSlate500, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: item.isActive && !isExpired,
              activeColor: kEmerald,
              onChanged: isExpired ? null : (v) => _discountBloc.add(ToggleDiscountStatus(item.id!, v)),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfessionalDialog(BuildContext context) {
    final name = TextEditingController();
    final val = TextEditingController();
    final min = TextEditingController();
    final code = TextEditingController();
    String dType = 'THRESHOLD';
    String vType = 'PERCENT';
    DateTime? sDate, eDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setUI) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            // ✅ White Background for Dialog
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Configure Business Offer",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black87)),
                  const SizedBox(height: 24),

                  _field("Offer Title", name, "e.g. Sunday Brunch Special"),
                  const SizedBox(height: 16),

                  _dropdown("Category", ['THRESHOLD', 'FESTIVAL', 'COUPON'], dType, (v) => setUI(() => dType = v!)),

                  if (dType == 'FESTIVAL') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _dateBtn(sDate == null ? "Start Date" : DateFormat('dd/MM/yy').format(sDate!), () async {
                          final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                          if (d != null) setUI(() => sDate = d);
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _dateBtn(eDate == null ? "End Date" : DateFormat('dd/MM/yy').format(eDate!), () async {
                          final d = await showDatePicker(context: context, initialDate: sDate ?? DateTime.now(), firstDate: sDate ?? DateTime.now(), lastDate: DateTime(2030));
                          if (d != null) setUI(() => eDate = d);
                        })),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _field("Value", val, "0.00")),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: _dropdown("Unit", ['PERCENT', 'FLAT'], vType, (v) => setUI(() => vType = v!))),
                    ],
                  ),

                  if (dType == 'COUPON') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field("Coupon Code", code, "Enter or Generate")),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () async {
                            final generated = await _repo.generateCode();
                            setUI(() => code.text = generated);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.cyan),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.cyan, size: 24),
                          ),
                        )
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  _field("Min Order Value (₹)", min, "500"),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("DISCARD", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _discountBloc.add(AddDiscount(DiscountModel(
                              name: name.text,
                              discountType: dType,
                              valueType: vType,
                              value: double.tryParse(val.text) ?? 0,
                              minPurchase: double.tryParse(min.text) ?? 0,
                              code: dType == 'COUPON' ? code.text : null,
                              isActive: true,
                              validFrom: sDate,
                              validTo: eDate,
                            )));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("SAVE OFFER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
      ],
    ),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        // ✅ Border color darkened slightly to avoid label-look
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyan, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  );

  Widget _dropdown(String label, List<String> items, String val, Function(String?) onCh) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
      ],
    ),
    child: DropdownButtonFormField<String>(
      value: val,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyan, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onCh,
    ),
  );

  Widget _dateBtn(String label, VoidCallback tap) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
      ],
    ),
    child: OutlinedButton(
      onPressed: tap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
    ),
  );

}
