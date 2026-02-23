// --- Tax Model & Entity ---
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class TaxProfileEntity {
  final int? id;
  final String name;
  final double taxPercentage;

  TaxProfileEntity({this.id, required this.name, required this.taxPercentage});

  factory TaxProfileEntity.fromJson(Map<String, dynamic> json) =>
      TaxProfileEntity(id: json['id'], name: json['name'], taxPercentage: double.parse(json['tax_percentage'].toString()));

  Map<String, dynamic> toJson() => {"name": name, "tax_percentage": taxPercentage};
}

// --- Tax Repository ---
class TaxProfileRepository {
  final ApiClient apiClient = sl<ApiClient>();
  Future<List<TaxProfileEntity>> getTaxes() async {
    final res = await apiClient.get('/api/inventory/tax-profiles/');
    final List data = (res.data is Map && res.data.containsKey('results')) ? res.data['results'] : res.data;
    return data.map((x) => TaxProfileEntity.fromJson(x)).toList();
  }
  Future<void> createTax(TaxProfileEntity tax) async => await apiClient.post('/api/inventory/tax-profiles/', data: tax.toJson());
  Future<void> updateTax(int id, TaxProfileEntity tax) async => await apiClient.put('/api/inventory/tax-profiles/$id/', data: tax.toJson());
  Future<void> deleteTax(int id) async => await apiClient.delete('/api/inventory/tax-profiles/$id/');
}

// --- Tax Bloc ---
abstract class TaxEvent {}
class LoadTaxes extends TaxEvent {}
class AddTax extends TaxEvent { final TaxProfileEntity tax; AddTax(this.tax); }
class EditTax extends TaxEvent { final int id; final TaxProfileEntity tax; EditTax(this.id, this.tax); }
class DeleteTax extends TaxEvent { final int id; DeleteTax(this.id); }

abstract class TaxState {}
class TaxLoading extends TaxState {}
class TaxLoaded extends TaxState { final List<TaxProfileEntity> taxes; TaxLoaded(this.taxes); }
class TaxError extends TaxState { final String msg; TaxError(this.msg); }

class TaxProfileBloc extends Bloc<TaxEvent, TaxState> {
  final TaxProfileRepository repo;
  TaxProfileBloc(this.repo) : super(TaxLoading()) {
    on<LoadTaxes>((event, emit) async {
      emit(TaxLoading());
      try { emit(TaxLoaded(await repo.getTaxes())); } catch (e) { emit(TaxError(e.toString())); }
    });
    on<AddTax>((event, emit) async { try { await repo.createTax(event.tax); add(LoadTaxes()); } catch (e) {} });
    on<EditTax>((event, emit) async { try { await repo.updateTax(event.id, event.tax); add(LoadTaxes()); } catch (e) {} });
    on<DeleteTax>((event, emit) async { try { await repo.deleteTax(event.id); add(LoadTaxes()); } catch (e) {} });
  }
}

// --- Tax UI View ---
class TaxProfileView extends StatefulWidget {
  const TaxProfileView({super.key});
  @override
  State<TaxProfileView> createState() => _TaxProfileViewState();
}

class _TaxProfileViewState extends State<TaxProfileView> {
  @override
  void initState() {
    super.initState();
    context.read<TaxProfileBloc>().add(LoadTaxes());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaxProfileBloc>();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tax Configurations",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text("Manage GST, VAT, and other tax profiles for billing",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showTaxDialog(context, bloc),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("CREATE TAX PROFILE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C24), // 💡 Professional Black Button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),

            // --- Grid Section ---
            Expanded(
              child: BlocBuilder<TaxProfileBloc, TaxState>(
                builder: (context, state) {
                  if (state is TaxLoading) return const Center(child: CircularProgressIndicator());
                  if (state is TaxLoaded) {
                    if (state.taxes.isEmpty) return _buildEmptyState();
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // Desktop view: 4 cards per row
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: state.taxes.length,
                      itemBuilder: (context, i) => _buildTaxCard(state.taxes[i], bloc),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 📦 Professional Tax Card ---
  Widget _buildTaxCard(TaxProfileEntity tax, TaxProfileBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Tax Badge Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          // Info Section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tax.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text("${tax.taxPercentage}%",
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.edit_outlined, Colors.blue, () => _showTaxDialog(context, bloc, tax: tax)),
              _iconBtn(Icons.delete_outline, Colors.redAccent, () => bloc.add(DeleteTax(tax.id!))),
            ],
          )
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 36,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // --- 📋 Professional Modal Dialog ---
  void _showTaxDialog(BuildContext context, TaxProfileBloc bloc, {TaxProfileEntity? tax}) {
    final name = TextEditingController(text: tax?.name);
    final percent = TextEditingController(text: tax?.taxPercentage.toString());

    showDialog(
      context: context,
      barrierDismissible: false, // Force click on buttons
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tax == null ? "New Tax Configuration" : "Edit Tax Profile",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Assign a descriptive name like 'GST 18%' and its numerical percentage.",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              _buildInput(name, "Tax Label", "e.g. SGST 9%", Icons.label_important_outline),
              const SizedBox(height: 16),
              _buildInput(percent, "Tax Percentage", "e.g. 9.0", Icons.percent_rounded, isNum: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1C24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () {
                if (name.text.isNotEmpty && percent.text.isNotEmpty) {
                  final entity = TaxProfileEntity(name: name.text, taxPercentage: double.parse(percent.text));
                  tax == null ? bloc.add(AddTax(entity)) : bloc.add(EditTax(tax.id!, entity));
                  Navigator.pop(ctx);
                }
              },
              child: const Text("SAVE PROFILE")
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, String hint, IconData icon, {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No tax profiles found. Create one to start billing.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}