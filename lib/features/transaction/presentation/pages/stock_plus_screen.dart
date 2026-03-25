
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String? createdAt;

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
    this.createdAt,
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
      createdAt: json['formatted_date'] ?? json['created_at']?.toString() ?? "",
      rawResponse: json,
    );
  }
}

class StockTransactionRepository1 {
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



class StockTransactionRepository {
  final ApiClient apiClient = sl<ApiClient>();

  // PERSISTENCE: Data fetch karne ke liye
  Future<List<StockTransactionEntity>> fetchHistory() async {
    final response = await apiClient.get('/api/inventory/stock-transactions/');
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((e) => StockTransactionEntity.fromJson(e)).toList();
    }
    throw Exception("History load fail hui");
  }

  // SAVE / UPDATE
  Future<StockTransactionEntity> saveStockEntry(StockTransactionEntity entity) async {
    final bool isUpdate = entity.id != null;
    final String path = isUpdate
        ? '/api/inventory/stock-transactions/${entity.id}/'
        : '/api/inventory/stock-transactions/';

    final response = isUpdate
        ? await apiClient.put(path, data: entity.toJson())
        : await apiClient.post(path, data: entity.toJson());

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return StockTransactionEntity.fromJson(data);
    }
    throw Exception("Invalid Server Response");
  }

  // DELETE
  Future<void> deleteStock(int id) async {
    final response = await apiClient.delete('/api/inventory/stock-transactions/$id/');
    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorMsg = response.data['error'] ?? "Delete failed";
      throw Exception(errorMsg);
    }
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

/*
class _StockPlusTransactionViewState extends State<StockPlusTransactionView> {
  final _noOfPcsCtrl = TextEditingController(text: "1");
  final _pcsCtrl = TextEditingController(text: "1");
  final _withGstCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();

  ProductGroupEntity? selectedGroup;
  ProductSubGroupEntity? selectedSubGroup;
  List<StockTransactionEntity> recentEntries = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Track if we are editing an entry
  StockTransactionEntity? editingEntity;

  @override
  void initState() {
    super.initState();
    context.read<ProductGroupBloc>().add(LoadGroups());
  }

  void _hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _resetForm() {
    setState(() {
      editingEntity = null;
      _withGstCtrl.clear();
      _costPriceCtrl.clear();
      _noOfPcsCtrl.text = "1";
      _pcsCtrl.text = "1";
      selectedGroup = null;
      selectedSubGroup = null;
    });
  }

  void _onEdit(StockTransactionEntity item) {
    setState(() {
      editingEntity = item;
      _noOfPcsCtrl.text = item.noOfPieces.toString();
      _pcsCtrl.text = item.pcsPerUnit.toString();
      _withGstCtrl.text = item.priceWithGst.toString();
      _costPriceCtrl.text = item.costPrice.toString();
      // Dropdown selection match logic logic yahan aayega if needed
    });
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  void _calculatePrice() {
    if (selectedGroup == null) return;
    double withGst = double.tryParse(_withGstCtrl.text) ?? 0;
    double tax = (selectedGroup?.sgst ?? 0) + (selectedGroup?.cgst ?? 0);
    double cost = withGst / (1 + (tax / 100));
    _costPriceCtrl.text = cost.toStringAsFixed(2);
  }

  void _showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return BlocListener<StockEntryBloc, StockEntryState>(
      listener: (context, state) {
        if (state is StockEntryLoading) {
          showDialog(context: context, barrierDismissible: false, useRootNavigator: true, builder: (_) => const Center(child: CircularProgressIndicator()));
        } else if (state is StockEntrySuccess) {
          _hideLoading(context);
          if (state.savedData.rawResponse != null) {
            LabelPrintingService.generateAndPrintLabels(state.savedData.rawResponse!);
          }
          setState(() {
            if (editingEntity != null) {
              recentEntries.removeWhere((e) => e.id == editingEntity!.id);
            }
            recentEntries.insert(0, state.savedData);
          });
          _resetForm();
          _showMsg(editingEntity == null ? "Stock Added & Printed" : "Stock Updated & Reprinted", isError: false);
        } else if (state is StockEntryError) {
          _hideLoading(context);
          _showMsg(state.error);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          title: Text(editingEntity == null ? "STOCK PLUS ENTRY" : "EDIT STOCK ENTRY"),
          actions: [
            if (editingEntity != null) IconButton(icon: const Icon(Icons.cancel), onPressed: _resetForm),
            IconButton(icon: const Icon(Icons.history_rounded, size: 26), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
            const SizedBox(width: 8),
          ],
        ),
        endDrawer: _buildRightHistoryDrawer(isMobile, screenWidth),
        body: Column(
          children: [
            _buildTopActionBar(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile
                    ? Column(children: [_buildFormCard(), const SizedBox(height: 16), _buildYellowTaxPanel()])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: _buildFormCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildYellowTaxPanel()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionBar(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: ElevatedButton.icon(
        onPressed: _onSave,
        icon: Icon(editingEntity == null ? Icons.print_rounded : Icons.save_as_rounded),
        label: Text(editingEntity == null ? "SAVE & PRINT LABELS" : "UPDATE & REPRINT"),
        style: ElevatedButton.styleFrom(
          backgroundColor: editingEntity == null ? const Color(0xFF0F172A) : Colors.indigo.shade900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupDropdown(),
          const SizedBox(height: 16),
          _buildSubGroupDropdown(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _tf(_noOfPcsCtrl, "NO OF PIECES", isDecimal: false)),
            const SizedBox(width: 12),
            Expanded(child: _tf(_pcsCtrl, "PCS / UNIT", isDecimal: false)),
          ]),
          const SizedBox(height: 16),
          _tf(_withGstCtrl, "PRICE WITH GST", isDecimal: true, onChange: (_) => _calculatePrice()),
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
          isExpanded: true,
          value: groups.any((e) => e.id == selectedGroup?.id) ? selectedGroup : null,
          decoration: _deco("PRODUCT GROUP"),
          items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
          onChanged: (val) {
            setState(() { selectedGroup = val; selectedSubGroup = null; _calculatePrice(); });
            context.read<ProductSubGroupBloc>().add(LoadSubGroups(groupId: val!.id));
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
          isExpanded: true,
          value: subGroups.any((e) => e.id == selectedSubGroup?.id) ? selectedSubGroup : null,
          decoration: _deco("SUB MASTER"),
          items: subGroups.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (val) => setState(() => selectedSubGroup = val),
        );
      },
    );
  }

  Widget _buildYellowTaxPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEF3C7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _taxRow("SGST RATE", "${selectedGroup?.sgst ?? 0.0}%"),
        _taxRow("CGST RATE", "${selectedGroup?.cgst ?? 0.0}%"),
        _taxRow("HSN CODE", selectedGroup?.hsnCode ?? "N/A"),
      ]),
    );
  }

  Widget _buildRightHistoryDrawer(bool isMobile, double screenWidth) {
    return Drawer(
      width: isMobile ? screenWidth * 0.85 : screenWidth * 0.35,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), color: const Color(0xFF0F172A), child: const SafeArea(child: Center(child: Text("RECENT ADDITIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
        Expanded(
          child: recentEntries.isEmpty
              ? const Center(child: Text("History is empty"))
              : ListView.separated(
            itemCount: recentEntries.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, index) {
              final item = recentEntries[index];
              return ListTile(
                title: Text(item.hsnCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Qty: ${item.noOfPieces} | ₹${item.priceWithGst}"),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _onEdit(item)),
                  IconButton(icon: const Icon(Icons.print), onPressed: () => LabelPrintingService.generateAndPrintLabels(item.rawResponse!)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _onSave() {
    if (selectedGroup == null || selectedSubGroup == null) { _showMsg("Select Group & Sub-Group"); return; }
    final entity = StockTransactionEntity(
      id: editingEntity?.id, // Important: Null for new, ID for update
      groupId: selectedGroup!.id!,
      subGroupId: selectedSubGroup!.id!,
      noOfPieces: int.parse(_noOfPcsCtrl.text),
      pcsPerUnit: int.parse(_pcsCtrl.text),
      priceWithGst: double.parse(_withGstCtrl.text),
      costPrice: double.parse(_costPriceCtrl.text),
      sgstRate: selectedGroup?.sgst ?? 0.0,
      cgstRate: selectedGroup?.cgst ?? 0.0,
      igstRate: (selectedGroup?.sgst ?? 0.0) + (selectedGroup?.cgst ?? 0.0),
      hsnCode: selectedGroup?.hsnCode ?? "",
    );
    context.read<StockEntryBloc>().add(SaveStockEntry(entity));
  }

  InputDecoration _deco(String l) => InputDecoration(labelText: l, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));
  Widget _tf(TextEditingController c, String l, {bool readOnly = false, bool isDecimal = true, Function(String)? onChange}) => TextField(controller: c, readOnly: readOnly, onChanged: onChange, decoration: _deco(l), keyboardType: TextInputType.number);
  Widget _taxRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));
}*/


class _StockPlusTransactionViewState extends State<StockPlusTransactionView> {
  final _noOfPcsCtrl = TextEditingController(text: "1");
  final _pcsCtrl = TextEditingController(text: "1");
  final _withGstCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();

  ProductGroupEntity? selectedGroup;
  ProductSubGroupEntity? selectedSubGroup;
  List<StockTransactionEntity> recentEntries = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  StockTransactionEntity? editingEntity;
  bool isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductGroupBloc>().add(LoadGroups());
    _loadHistory(); // 🔄 Persistence: Load from server on startup
  }

  // LOGIC: Data persistence fetch
  Future<void> _loadHistory() async {
    setState(() => isHistoryLoading = true);
    try {
      final response = await sl<ApiClient>().get('/api/inventory/stock-transactions/');
      final List data = response.data;
      setState(() {
        recentEntries = data.map((e) => StockTransactionEntity.fromJson(e)).toList();
        isHistoryLoading = false;
      });
    } catch (e) {
      setState(() => isHistoryLoading = false);
    }
  }

  // LOGIC: Editing selection
  void _onEdit(StockTransactionEntity item) {
    // 1. Match Product Group from Bloc State
    final groupState = context.read<ProductGroupBloc>().state;
    ProductGroupEntity? matchedGroup;
    if (groupState is GroupLoaded) {
      matchedGroup = groupState.groups.firstWhere((g) => g.id == item.groupId, orElse: () => groupState.groups.first);
    }

    setState(() {
      editingEntity = item;
      selectedGroup = matchedGroup;
      _noOfPcsCtrl.text = item.noOfPieces.toString();
      _pcsCtrl.text = item.pcsPerUnit.toString();
      _withGstCtrl.text = item.priceWithGst.toString();
      _costPriceCtrl.text = item.costPrice.toString();

      // 2. Load Subgroups for the selected group
      if (matchedGroup != null) {
        context.read<ProductSubGroupBloc>().add(LoadSubGroups(groupId: matchedGroup.id));
      }
    });

    _calculatePrice(); // Auto calculate tax panel
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  // LOGIC: Safe Delete
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure to delete this stock ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await sl<ApiClient>().delete('/api/inventory/stock-transactions/$id/');
                if (res.statusCode == 200 || res.statusCode == 204) {
                  _showMsg("Deleted Successfully", isError: false);
                  _loadHistory(); // Refresh persistent list
                }
              } catch (e) {
                _showMsg("Delete Failed: Items might be used.");
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      editingEntity = null;
      _withGstCtrl.clear();
      _costPriceCtrl.clear();
      _noOfPcsCtrl.text = "1";
      _pcsCtrl.text = "1";
      selectedGroup = null;
      selectedSubGroup = null;
    });
  }

  void _calculatePrice() {
    if (selectedGroup == null) return;
    double withGst = double.tryParse(_withGstCtrl.text) ?? 0;
    double tax = (selectedGroup?.sgst ?? 0) + (selectedGroup?.cgst ?? 0);
    double cost = withGst / (1 + (tax / 100));
    _costPriceCtrl.text = cost.toStringAsFixed(2);
  }

  void _showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return BlocListener<StockEntryBloc, StockEntryState>(
      listener: (context, state) {
        if (state is StockEntryLoading) {
          showDialog(context: context, barrierDismissible: false, useRootNavigator: true, builder: (_) => const Center(child: CircularProgressIndicator()));
        } else if (state is StockEntrySuccess) {
          Navigator.of(context, rootNavigator: true).pop();
          _loadHistory(); // Persistence refresh
          _resetForm();
          _showMsg(editingEntity == null ? "Stock Added & Printed" : "Stock Updated & Reprinted", isError: false);
        } else if (state is StockEntryError) {
          Navigator.of(context, rootNavigator: true).pop();
          _showMsg(state.error);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          title: Text(editingEntity == null ? "STOCK PLUS ENTRY" : "EDIT STOCK ENTRY"),
          actions: [
            if (editingEntity != null) IconButton(icon: const Icon(Icons.cancel), onPressed: _resetForm),
            IconButton(icon: const Icon(Icons.history_rounded), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
          ],
        ),
        endDrawer: _buildRightHistoryDrawer(isMobile, screenWidth),
        body: Column(
          children: [
            _buildTopActionBar(isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile
                    ? Column(children: [_buildFormCard(), const SizedBox(height: 16), _buildYellowTaxPanel()])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: _buildFormCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildYellowTaxPanel()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AAPKE ORIGINAL UI WIDGETS ---

  Widget _buildTopActionBar(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: ElevatedButton.icon(
        onPressed: _onSave,
        icon: Icon(editingEntity == null ? Icons.print_rounded : Icons.save_as_rounded),
        label: Text(editingEntity == null ? "SAVE & PRINT LABELS" : "UPDATE & REPRINT"),
        style: ElevatedButton.styleFrom(
          backgroundColor: editingEntity == null ? const Color(0xFF0F172A) : Colors.indigo.shade900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupDropdown(),
          const SizedBox(height: 16),
          _buildSubGroupDropdown(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _tf(_noOfPcsCtrl, "NO OF PIECES", isDecimal: false)),
            const SizedBox(width: 12),
            Expanded(child: _tf(_pcsCtrl, "PCS / UNIT", isDecimal: false)),
          ]),
          const SizedBox(height: 16),
          _tf(_withGstCtrl, "PRICE WITH GST", isDecimal: true, onChange: (_) => _calculatePrice()),
          const SizedBox(height: 16),
          _tf(_costPriceCtrl, "COST PRICE (AUTO)", readOnly: true),
        ],
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return BlocBuilder<ProductGroupBloc, ProductGroupState>(
      builder: (context, state) {
        List<ProductGroupEntity> groups = (state is GroupLoaded) ? state.groups : [];
        return DropdownButtonFormField<ProductGroupEntity>(
          isExpanded: true,
          value: groups.any((e) => e.id == selectedGroup?.id) ? groups.firstWhere((e) => e.id == selectedGroup?.id) : null,
          decoration: _deco("PRODUCT GROUP"),
          items: groups.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
          onChanged: (val) {
            setState(() { selectedGroup = val; selectedSubGroup = null; _calculatePrice(); });
            context.read<ProductSubGroupBloc>().add(LoadSubGroups(groupId: val!.id));
          },
        );
      },
    );
  }

  Widget _buildSubGroupDropdown() {
    return BlocBuilder<ProductSubGroupBloc, SubGroupState>(
      builder: (context, state) {
        List<ProductSubGroupEntity> subGroups = (state is SubGroupLoaded) ? state.subGroups : [];

        // Auto-select subgroup if editing
        if (editingEntity != null && selectedSubGroup == null && subGroups.isNotEmpty) {
          try {
            selectedSubGroup = subGroups.firstWhere((s) => s.id == editingEntity!.subGroupId);
          } catch(e) {}
        }

        return DropdownButtonFormField<ProductSubGroupEntity>(
          isExpanded: true,
          value: subGroups.any((e) => e.id == selectedSubGroup?.id) ? subGroups.firstWhere((e) => e.id == selectedSubGroup?.id) : null,
          decoration: _deco("SUB MASTER"),
          items: subGroups.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (val) => setState(() => selectedSubGroup = val),
        );
      },
    );
  }

  Widget _buildYellowTaxPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEF3C7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _taxRow("SGST RATE", "${selectedGroup?.sgst ?? 0.0}%"),
        _taxRow("CGST RATE", "${selectedGroup?.cgst ?? 0.0}%"),
        _taxRow("HSN CODE", selectedGroup?.hsnCode ?? "N/A"),
      ]),
    );
  }

  Widget _buildRightHistoryDrawer(bool isMobile, double screenWidth) {
    return Drawer(
      width: isMobile ? screenWidth * 0.85 : 400,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), color: const Color(0xFF0F172A), child: const SafeArea(child: Center(child: Text("HISTORY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
        Expanded(
          child: isHistoryLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
            itemCount: recentEntries.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, index) {
              final item = recentEntries[index];
              return ListTile(
                title: Text(item.hsnCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Qty: ${item.noOfPieces} | ₹${item.priceWithGst}\n${item.createdAt??""}"),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _onEdit(item)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(item.id!)),
                  IconButton(icon: const Icon(Icons.print), onPressed: () => LabelPrintingService.generateAndPrintLabels(item.rawResponse!)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }


  void _onSave() {
    // 1. Basic Validation
    if (selectedGroup == null || selectedSubGroup == null) {
      _showMsg("Select Group & Sub-Group");
      return;
    }
    if (_noOfPcsCtrl.text.isEmpty || _withGstCtrl.text.isEmpty) {
      _showMsg("Please fill all fields");
      return;
    }

    // 2. Warning Modal / Confirmation Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Confirm Stock Entry", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure to add stock and print ?"),
            const SizedBox(height: 16),
            _summaryRow("Group:", selectedGroup?.name ?? ""),
            _summaryRow("Sub-Master:", selectedSubGroup?.name ?? ""),
            _summaryRow("Total Pieces:", _noOfPcsCtrl.text),
            _summaryRow("Price/Unit:", "₹${_withGstCtrl.text}"),
            const Divider(height: 24),
            const Text(
              "Note: After saving stock barcode will autogenerate.",
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _processSave();
            },
            child: const Text("YES, SAVE & PRINT"),
          ),
        ],
      ),
    );
  }

  // Final Processing Logic (Aapka original code)
  void _processSave() {
    final entity = StockTransactionEntity(
      id: editingEntity?.id,
      groupId: selectedGroup!.id!,
      subGroupId: selectedSubGroup!.id!,
      noOfPieces: int.parse(_noOfPcsCtrl.text),
      pcsPerUnit: int.parse(_pcsCtrl.text),
      priceWithGst: double.parse(_withGstCtrl.text),
      costPrice: double.parse(_costPriceCtrl.text),
      sgstRate: selectedGroup?.sgst ?? 0.0,
      cgstRate: selectedGroup?.cgst ?? 0.0,
      igstRate: (selectedGroup?.sgst ?? 0.0) + (selectedGroup?.cgst ?? 0.0),
      hsnCode: selectedGroup?.hsnCode ?? "",
    );
    context.read<StockEntryBloc>().add(SaveStockEntry(entity));
  }

  // Summary Row Helper
  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  InputDecoration _deco(String l) => InputDecoration(labelText: l, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)));
  Widget _tf(TextEditingController c, String l, {bool readOnly = false, bool isDecimal = true, Function(String)? onChange}) => TextField(controller: c, readOnly: readOnly, onChanged: onChange, decoration: _deco(l), keyboardType: TextInputType.number);
  Widget _taxRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));
}