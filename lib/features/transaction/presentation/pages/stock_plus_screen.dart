
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../../inventory/presentation/bloc/inventory_group_subgroup_bloc.dart';

// ==========================================================================
// 1. DATA LAYER (Models & Repository)
// ==========================================================================

class StockTransactionEntity {
  final int? id;
  final int groupId, subGroupId, noOfPieces, pcsPerUnit;
  final double priceWithGst, costPrice, sgstRate, cgstRate, igstRate;
  final String hsnCode;
  final List<dynamic>? barcodes;
  final Map<String, dynamic>? rawResponse;

  StockTransactionEntity({
    this.id,
    required this.groupId,
    required this.subGroupId,
    required this.noOfPieces,
    required this.pcsPerUnit,
    required this.priceWithGst,
    required this.costPrice,
    required this.sgstRate,
    required this.cgstRate,
    required this.igstRate,
    required this.hsnCode,
    this.barcodes,
    this.rawResponse,
  });

  Map<String, dynamic> toJson() => {
    "group": groupId,
    "sub_group": subGroupId,
    "no_of_pieces": noOfPieces,
    "pcs_per_unit": pcsPerUnit,
    "price_with_gst": priceWithGst,
    "cost_price": costPrice,
    "sgst_rate": sgstRate,
    "cgst_rate": cgstRate,
    "igst_rate": igstRate,
    "hsn_code": hsnCode,
  };

  factory StockTransactionEntity.fromJson(Map<String, dynamic> json) {
    return StockTransactionEntity(
      id: json['id'],
      groupId: json['group'] ?? 0,
      subGroupId: json['sub_group'] ?? 0,
      noOfPieces: json['no_of_pieces'] ?? 0,
      pcsPerUnit: json['pcs_per_unit'] ?? 1,
      priceWithGst: double.tryParse(json['price_with_gst'].toString()) ?? 0.0,
      costPrice: double.tryParse(json['cost_price'].toString()) ?? 0.0,
      sgstRate: double.tryParse(json['sgst_rate'].toString()) ?? 0.0,
      cgstRate: double.tryParse(json['cgst_rate'].toString()) ?? 0.0,
      igstRate: double.tryParse(json['igst_rate'].toString()) ?? 0.0,
      hsnCode: json['hsn_code']?.toString() ?? "",
      barcodes: json['barcode_list'],
      rawResponse: json,
    );
  }
}

class StockTransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<StockTransactionEntity> saveStockEntry(StockTransactionEntity entity) async {
    const String path = '/api/inventory/stock-transactions/';
    final response = await apiClient.post(path, data: entity.toJson());

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return StockTransactionEntity.fromJson(data);
    }
    throw Exception("Invalid Server Response");
  }
}

// ==========================================================================
// 2. BLOC LAYER
// ==========================================================================

abstract class StockEntryEvent {}
class SaveStockEntry extends StockEntryEvent {
  final StockTransactionEntity entry;
  SaveStockEntry(this.entry);
}

abstract class StockEntryState {}
class StockEntryInitial extends StockEntryState {}
class StockEntryLoading extends StockEntryState {}
class StockEntrySuccess extends StockEntryState {
  final String message;
  final StockTransactionEntity savedData;
  StockEntrySuccess(this.message, this.savedData);
}
class StockEntryError extends StockEntryState {
  final String error;
  StockEntryError(this.error);
}

class StockEntryBloc extends Bloc<StockEntryEvent, StockEntryState> {
  final StockTransactionRepository repository;
  StockEntryBloc(this.repository) : super(StockEntryInitial()) {
    on<SaveStockEntry>((event, emit) async {
      emit(StockEntryLoading());
      try {
        final result = await repository.saveStockEntry(event.entry);
        emit(StockEntrySuccess("Stock Added Successfully!", result));
      } catch (e) {
        emit(StockEntryError(e.toString()));
      }
    });
  }
}

// ==========================================================================
// 3. PRINT SERVICE
// ==========================================================================

class LabelPrintingService {
  static Future<void> generateAndPrintLabels(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final List barcodes = data['barcode_list'] ?? [];
    final shop = data['shop_details'] ?? {};
    final String subGroupName = data['sub_group_name'] ?? "ITEM";
    final String price = data['price_with_gst']?.toString() ?? "0.00";

    for (var code in barcodes) {
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 25 * PdfPageFormat.mm, marginAll: 1 * PdfPageFormat.mm),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(shop['name']?.toString().toUpperCase() ?? "SHOP NAME",
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${shop['address']} | ${shop['mobile']}",
                      style: const pw.TextStyle(fontSize: 4.5)),
                  pw.Divider(thickness: 0.5),
                  pw.Text(subGroupName.toUpperCase(),
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 1),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: code.toString(),
                    width: 90,
                    height: 25,
                    drawText: true,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text("PRICE: RS. $price",
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      );
    }
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Labels');
  }
}

// ==========================================================================
// 4. UI LAYER
// ==========================================================================

class StockPlusTransactionView extends StatefulWidget {
  const StockPlusTransactionView({super.key});
  @override
  State<StockPlusTransactionView> createState() => _StockPlusTransactionViewState();
}

class _StockPlusTransactionViewState extends State<StockPlusTransactionView> {
  final _noOfPcsCtrl = TextEditingController(text: "1");
  final _pcsCtrl = TextEditingController(text: "1");
  final _withGstCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();

  ProductGroupEntity? selectedGroup;
  ProductSubGroupEntity? selectedSubGroup;
  List<StockTransactionEntity> recentEntries = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<ProductGroupBloc>().add(LoadGroups());
  }

  void _hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _calculatePrice() {
    if (selectedGroup == null) return;
    double withGst = double.tryParse(_withGstCtrl.text) ?? 0;
    double tax = (selectedGroup?.sgst ?? 0) + (selectedGroup?.cgst ?? 0);
    double cost = withGst / (1 + (tax / 100));
    _costPriceCtrl.text = cost.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockEntryBloc, StockEntryState>(
      listener: (context, state) {
        if (state is StockEntryLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: true, // ✅ Important: Root navigator ka use karein
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else if (state is StockEntrySuccess) {
          _hideLoading(context);

          if (state.savedData.rawResponse != null) {
            LabelPrintingService.generateAndPrintLabels(state.savedData.rawResponse!);
          }


          setState(() {
            recentEntries.insert(0, state.savedData);
            _withGstCtrl.clear();
            _costPriceCtrl.clear();
            _noOfPcsCtrl.text = "1";
            _pcsCtrl.text = "1";
            selectedGroup = null;
            selectedSubGroup = null;
          });


          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Stock Saved Successfully"), backgroundColor: Colors.green)
          );
        } else if (state is StockEntryError) {
          _hideLoading(context); // ✅ Error mein bhi loading band karein
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red)
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          title: const Text("STOCK PLUS ENTRY", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, size: 28),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            const SizedBox(width: 15),
          ],
        ),
        endDrawer: _buildRightHistoryModal(),
        body: Column(
          children: [
            _buildTopActionBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildFormCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: _buildYellowTaxPanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _onSave,
            icon: const Icon(Icons.save),
            label: const Text("SAVE & PRINT LABELS"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildGroupDropdown(),
          const SizedBox(height: 16),
          _buildSubGroupDropdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _tf(_noOfPcsCtrl, "NO OF PIECES")),
              const SizedBox(width: 12),
              Expanded(child: _tf(_pcsCtrl, "PCS")),
            ],
          ),
          const SizedBox(height: 16),
          _tf(_withGstCtrl, "WITH GST PRICE", onChange: (_) => _calculatePrice()),
          const SizedBox(height: 16),
          _tf(_costPriceCtrl, "COST PRICE (AUTO)", readOnly: true),
        ],
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return BlocBuilder<ProductGroupBloc, ProductGroupState>(
      builder: (context, state) {
        List<ProductGroupEntity> groups = [];
        if (state is GroupLoaded) groups = state.groups;

        return DropdownButtonFormField<ProductGroupEntity>(
          value: groups.any((e) => e.id == selectedGroup?.id) ? selectedGroup : null,
          decoration: _deco("GROUP NAME"),
          hint: const Text("Select Product Group"),
          items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                selectedGroup = val;
                selectedSubGroup = null;
                _calculatePrice();
              });
              context.read<ProductSubGroupBloc>().add(LoadSubGroups(groupId: val.id));
            }
          },
        );
      },
    );
  }

  Widget _buildSubGroupDropdown() {
    return BlocBuilder<ProductSubGroupBloc, SubGroupState>(
      builder: (context, state) {
        List<ProductSubGroupEntity> subGroups = [];
        if (state is SubGroupLoaded) subGroups = state.subGroups;

        return DropdownButtonFormField<ProductSubGroupEntity>(
          value: subGroups.any((e) => e.id == selectedSubGroup?.id) ? selectedSubGroup : null,
          decoration: _deco("SUB NAME"),
          hint: const Text("Select Sub Group"),
          items: subGroups.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (val) => setState(() => selectedSubGroup = val),
        );
      },
    );
  }

  Widget _buildYellowTaxPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GST & HSN INFO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          const Divider(color: Colors.orange),
          _taxRow("SGST", "${selectedGroup?.sgst ?? 0.0}%"),
          _taxRow("CGST", "${selectedGroup?.cgst ?? 0.0}%"),
          _taxRow("HSN CODE", selectedGroup?.hsnCode ?? "-"),
        ],
      ),
    );
  }

  Widget _buildRightHistoryModal() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.35,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blueGrey.shade900,
            child: const SafeArea(child: Center(child: Text("RECENT ENTRIES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ),
          Expanded(
            child: recentEntries.isEmpty
                ? const Center(child: Text("No entries yet"))
                : ListView.separated(
              itemCount: recentEntries.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, index) {
                final item = recentEntries[index];
                return ListTile(
                  title: Text("HSN: ${item.hsnCode}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Qty: ${item.noOfPieces} | ₹${item.priceWithGst}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.print, color: Colors.blue),
                    onPressed: () => LabelPrintingService.generateAndPrintLabels(item.rawResponse!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String l) => InputDecoration(labelText: l, border: const OutlineInputBorder());

  Widget _tf(TextEditingController c, String l, {bool readOnly = false, Function(String)? onChange}) => TextField(
      controller: c,
      readOnly: readOnly,
      onChanged: onChange,
      decoration: _deco(l),
      keyboardType: const TextInputType.numberWithOptions(decimal: true));

  Widget _taxRow(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));

  void _onSave() {
    if (selectedGroup == null || selectedSubGroup == null || _withGstCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    final entity = StockTransactionEntity(
      groupId: selectedGroup!.id!,
      subGroupId: selectedSubGroup!.id!,
      noOfPieces: int.tryParse(_noOfPcsCtrl.text) ?? 0,
      pcsPerUnit: int.tryParse(_pcsCtrl.text) ?? 1,
      priceWithGst: double.tryParse(_withGstCtrl.text) ?? 0.0,
      costPrice: double.tryParse(_costPriceCtrl.text) ?? 0.0,
      sgstRate: selectedGroup?.sgst ?? 0.0,
      cgstRate: selectedGroup?.cgst ?? 0.0,
      igstRate: (selectedGroup?.sgst ?? 0.0) + (selectedGroup?.cgst ?? 0.0),
      hsnCode: selectedGroup?.hsnCode ?? "",
    );
    context.read<StockEntryBloc>().add(SaveStockEntry(entity));
  }
}