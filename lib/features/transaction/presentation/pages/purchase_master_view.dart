/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/transaction/presentation/pages/purchase_history_sidebar.dart';

import '../../../inventory/presentation/bloc/inventory_product_management_bloc.dart';
import '../../domain/entity/purchase_entity.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/suppier_bloc.dart';
import 'package:flutter/services.dart';


class PurchaseMasterView extends StatefulWidget {
  const PurchaseMasterView({super.key});

  @override
  State<PurchaseMasterView> createState() => _PurchaseMasterViewState();
}

class _PurchaseMasterViewState extends State<PurchaseMasterView> {
  final _billNo = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  int? _selSupplier;
  String _mode = 'CASH';
  List<PurchaseItemEntry> _cart = [];
  String _barcodeBuffer = "";
  final ScrollController _scrollController = ScrollController();

  // 🔍 Filter States
  String _searchQuery = "";
  String _statusFilter = "ALL";

  @override
  void initState() {
    super.initState();
    context.read<PurchaseBloc>().add(LoadPurchaseHistory());
    context.read<SupplierBloc>().add(LoadSuppliers());
    context.read<InventoryProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _billNo.dispose();
    _keyboardFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _safePop(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  // ==========================================================================
  // 🏢 SIDEBAR LOGIC (LARGE PANEL & WORKABLE FILTERS)
  // ==========================================================================

  void _openHistoryPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "History",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 40,
            child: BlocProvider.value(
              value: context.read<PurchaseBloc>()..add(LoadPurchaseHistory()),
              child: const PurchaseHistorySidebar(), // 💡 External File Call
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }




  // ==========================================================================
  // ⚡ BILLING SCREEN UI (REMAINING SAME AS PREVIOUS)
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKey: _handleBarcodeKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: BlocListener<PurchaseBloc, PurchaseState>(
          listener: (context, state) {
            if (state is PurchaseSuccess) {
              _billNo.clear();
              setState(() { _cart = []; _selSupplier = null; });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.msg), backgroundColor: Colors.green));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context),
                const SizedBox(height: 24),
                _buildSectionHeader("BILL DETAILS / बिल विवरण"),
                _buildBillMasterCard(),
                const SizedBox(height: 32),
                _buildSectionHeader("ITEMIZED STOCK INWARD / आइटम प्रविष्टि"),
                Expanded(child: _buildAdvancedCart()),
                _buildFloatingSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // (Helper widgets like _buildTopHeader, _buildAdvancedCart, _buildBillMasterCard remain integrated below)

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Stock Inward Master", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          Text("Ready to scan barcodes or enter details manually", style: TextStyle(color: Color(0xFF64748B))),
        ]),
        ElevatedButton.icon(
          onPressed: () => _openHistoryPanel(context),
          icon: const Icon(Icons.history_rounded),
          label: const Text("FULL LOGS / विवरण"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildBillMasterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildSupplierPicker()),
          const SizedBox(width: 20),
          Expanded(child: _buildModernInput(_billNo, "Invoice Number", Icons.receipt_long)),
          const SizedBox(width: 20),
          Expanded(child: _buildPaymentModePicker()),
        ],
      ),
    );
  }

  Widget _buildAdvancedCart() {
    if (_cart.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), const Text("Scan item now or click add manually", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
    }
    return ListView.builder(controller: _scrollController, itemCount: _cart.length, itemBuilder: (ctx, index) => _buildAdvancedItemCard(index));
  }

  Widget _buildAdvancedItemCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildProductPicker(index)),
          const SizedBox(width: 20),
          _buildQuantityControl(index),
          const SizedBox(width: 20),
          SizedBox(width: 150, child: _buildRateInput(index)),
          const Spacer(),
          Text("₹${(_cart[index].quantity * _cart[index].unitPrice).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF00BCD4))),
          const SizedBox(width: 20),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => setState(() => _cart.removeAt(index))),
        ],
      ),
    );
  }

  // (Standard UI Helpers)
  Widget _buildStatusChip(String mode) {
    Color color = mode == 'CREDIT' ? Colors.orange : Colors.green;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(mode, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Widget _buildSectionHeader(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 1.5)));
  Widget _buildModernInput(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  Widget _buildPaymentModePicker() => DropdownButtonFormField<String>(value: _mode, items: const [DropdownMenuItem(value: "CASH", child: Text("Cash")), DropdownMenuItem(value: "ONLINE", child: Text("Online")), DropdownMenuItem(value: "CREDIT", child: Text("Credit"))], onChanged: (v) => setState(() => _mode = v!), decoration: InputDecoration(labelText: "Mode", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));

  // (Scaning & Logic Helpers)
  void _handleBarcodeKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter && _barcodeBuffer.isNotEmpty) {
        _addItemByBarcode(_barcodeBuffer.trim());
        _barcodeBuffer = "";
      } else if (event.character != null) {
        _barcodeBuffer += event.character!;
      }
    }
  }

  void _addItemByBarcode(String code) {
    final state = context.read<InventoryProductBloc>().state;
    if (state is ProductLoaded) {
      try {
        final prod = state.products.firstWhere((p) => p.sku == code);
        setState(() => _cart.add(PurchaseItemEntry(productId: prod.id!, quantity: 1.0, unitPrice: prod.purchasePrice)));
        _scrollToBottom();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SKU not found!")));
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () => _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
  }

  void _postBill() {
    if (_selSupplier == null || _billNo.text.isEmpty || _cart.isEmpty) return;
    context.read<PurchaseBloc>().add(PostPurchaseBill(_selSupplier!, _billNo.text, _mode, _cart));
  }

  Widget _buildSupplierPicker() {
    return BlocBuilder<SupplierBloc, SupplierState>(builder: (context, state) {
      final list = (state is SupplierLoaded) ? state.suppliers : [];
      return DropdownButtonFormField<int>(isExpanded: true, value: _selSupplier, items: list.map<DropdownMenuItem<int>>((e) => DropdownMenuItem(value: e.id, child: Text(e.name ?? ""))).toList(), onChanged: (v) => setState(() => _selSupplier = v), decoration: InputDecoration(labelText: "Supplier", prefixIcon: const Icon(Icons.business_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
    });
  }

  Widget _buildProductPicker(int index) {
    return BlocBuilder<InventoryProductBloc, ProductState>(builder: (context, state) {
      final prods = (state is ProductLoaded) ? state.products : [];
      return DropdownButtonFormField<int?>(isExpanded: true, value: _cart[index].productId == 0 ? null : _cart[index].productId, items: prods.map<DropdownMenuItem<int?>>((p) => DropdownMenuItem(value: p.id, child: Text("${p.name} (${p.sku})"))).toList(), onChanged: (v) => setState(() { _cart[index].productId = v!; _cart[index].unitPrice = prods.firstWhere((e) => e.id == v).purchasePrice; }), decoration: InputDecoration(hintText: "Select Item", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
    });
  }

  Widget _buildQuantityControl(int index) {
    return Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Row(children: [IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => setState(() { if(_cart[index].quantity > 1) _cart[index].quantity--; })), SizedBox(width: 40, child: Text(_cart[index].quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setState(() => _cart[index].quantity++)),]));
  }

  Widget _buildRateInput(int index) {
    return TextFormField(key: ValueKey('rate_${_cart[index].productId}_$index'), initialValue: _cart[index].unitPrice.toString(), keyboardType: TextInputType.number, onChanged: (v) => setState(() => _cart[index].unitPrice = double.tryParse(v) ?? 0.0), decoration: InputDecoration(labelText: "Unit Rate", prefixText: "₹ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  }

  Widget _buildFloatingSummary() {
    double total = _cart.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    return Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.only(top: 24), decoration: BoxDecoration(color: const Color(0xFF1A1C24), borderRadius: BorderRadius.circular(24)), child: Row(children: [ElevatedButton.icon(onPressed: () => setState(() => _cart.add(PurchaseItemEntry(productId: 0))), icon: const Icon(Icons.add), label: const Text("MANUAL ADD"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20))), const Spacer(), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("GRAND TOTAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))]), const SizedBox(width: 32), ElevatedButton(onPressed: _postBill, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("POST BILL", style: TextStyle(fontWeight: FontWeight.bold)))]));
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/transaction/presentation/pages/purchase_history_sidebar.dart';
import '../../../inventory/presentation/bloc/inventory_product_management_bloc.dart';
import '../../domain/entity/purchase_entity.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/suppier_bloc.dart';
import 'package:flutter/services.dart';

class PurchaseMasterView extends StatefulWidget {
  const PurchaseMasterView({super.key});

  @override
  State<PurchaseMasterView> createState() => _PurchaseMasterViewState();
}

class _PurchaseMasterViewState extends State<PurchaseMasterView> {
  final _billNo = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  int? _selSupplier;
  String _mode = 'CASH';
  List<PurchaseItemEntry> _cart = [];
  String _barcodeBuffer = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PurchaseBloc>().add(LoadPurchaseHistory());
    context.read<SupplierBloc>().add(LoadSuppliers());
    context.read<InventoryProductBloc>().add(LoadProducts());
  }

  @override
  void dispose() {
    _billNo.dispose();
    _keyboardFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🛠️ HELPER: Product Configuration se Factor nikalne ke liye
  double _getConversionFactor(int productId) {
    final state = context.read<InventoryProductBloc>().state;
    if (state is ProductLoaded) {
      try {
        return state.products.firstWhere((p) => p.id == productId).conversionFactor;
      } catch (e) {
        return 1.0;
      }
    }
    return 1.0;
  }

  void _openHistoryPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "History",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 40,
            child: BlocProvider.value(
              value: context.read<PurchaseBloc>()..add(LoadPurchaseHistory()),
              child: const PurchaseHistorySidebar(),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKey: _handleBarcodeKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: BlocListener<PurchaseBloc, PurchaseState>(
          listener: (context, state) {
            if (state is PurchaseSuccess) {
              _billNo.clear();
              setState(() { _cart = []; _selSupplier = null; });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.msg), backgroundColor: Colors.green));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context),
                const SizedBox(height: 24),
                _buildSectionHeader("BILL DETAILS / बिल विवरण"),
                _buildBillMasterCard(),
                const SizedBox(height: 32),
                _buildSectionHeader("ITEMIZED STOCK INWARD / आइटम प्रविष्टि"),
                Expanded(child: _buildAdvancedCart()),
                _buildFloatingSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Stock Inward Master", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          Text("Ready to scan barcodes or enter details manually", style: TextStyle(color: Color(0xFF64748B))),
        ]),
        ElevatedButton.icon(
          onPressed: () => _openHistoryPanel(context),
          icon: const Icon(Icons.history_rounded),
          label: const Text("FULL LOGS / विवरण"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _buildBillMasterCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildSupplierPicker()),
          const SizedBox(width: 20),
          Expanded(child: _buildModernInput(_billNo, "Invoice Number", Icons.receipt_long)),
          const SizedBox(width: 20),
          Expanded(child: _buildPaymentModePicker()),
        ],
      ),
    );
  }

  Widget _buildAdvancedCart() {
    if (_cart.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), const Text("Scan item now or click add manually", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
    }
    return ListView.builder(controller: _scrollController, itemCount: _cart.length, itemBuilder: (ctx, index) => _buildAdvancedItemCard(index));
  }

  Widget _buildAdvancedItemCard(int index) {
    // 🔥 Universal Calculation Logic
    double factor = _getConversionFactor(_cart[index].productId);
    double totalPieces = _cart[index].quantity * factor; // 4 Crate * 30 = 120 Pieces
    double lineTotal = totalPieces * _cart[index].unitPrice; // 120 Pieces * ₹5 = ₹600

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildProductPicker(index)),
          const SizedBox(width: 20),
          _buildQuantityControl(index),
          const SizedBox(width: 20),
          SizedBox(width: 150, child: _buildRateInput(index)),
          const Spacer(),
          // 💡 Showing Piece-wise Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Total Units: ${totalPieces.toStringAsFixed(0)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text("₹${lineTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF00BCD4))),
            ],
          ),
          const SizedBox(width: 20),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => setState(() => _cart.removeAt(index))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 1.5)));
  Widget _buildModernInput(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  Widget _buildPaymentModePicker() => DropdownButtonFormField<String>(value: _mode, items: const [DropdownMenuItem(value: "CASH", child: Text("Cash")), DropdownMenuItem(value: "ONLINE", child: Text("Online")), DropdownMenuItem(value: "CREDIT", child: Text("Credit"))], onChanged: (v) => setState(() => _mode = v!), decoration: InputDecoration(labelText: "Mode", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));

  void _handleBarcodeKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter && _barcodeBuffer.isNotEmpty) {
        _addItemByBarcode(_barcodeBuffer.trim());
        _barcodeBuffer = "";
      } else if (event.character != null) {
        _barcodeBuffer += event.character!;
      }
    }
  }

  void _addItemByBarcode(String code) {
    final state = context.read<InventoryProductBloc>().state;
    if (state is ProductLoaded) {
      try {
        final prod = state.products.firstWhere((p) => p.sku == code);
        setState(() => _cart.add(PurchaseItemEntry(productId: prod.id!, quantity: 1.0, unitPrice: prod.purchasePrice)));
        _scrollToBottom();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SKU not found!")));
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () => _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
  }

  void _postBill() {
    if (_selSupplier == null || _billNo.text.isEmpty || _cart.isEmpty) return;
    context.read<PurchaseBloc>().add(PostPurchaseBill(_selSupplier!, _billNo.text, _mode, _cart));
  }

  Widget _buildSupplierPicker() {
    return BlocBuilder<SupplierBloc, SupplierState>(builder: (context, state) {
      final list = (state is SupplierLoaded) ? state.suppliers : [];
      return DropdownButtonFormField<int>(isExpanded: true, value: _selSupplier, items: list.map<DropdownMenuItem<int>>((e) => DropdownMenuItem(value: e.id, child: Text(e.name ?? ""))).toList(), onChanged: (v) => setState(() => _selSupplier = v), decoration: InputDecoration(labelText: "Supplier", prefixIcon: const Icon(Icons.business_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
    });
  }

  Widget _buildProductPicker(int index) {
    return BlocBuilder<InventoryProductBloc, ProductState>(builder: (context, state) {
      final prods = (state is ProductLoaded) ? state.products : [];
      return DropdownButtonFormField<int?>(isExpanded: true, value: _cart[index].productId == 0 ? null : _cart[index].productId, items: prods.map<DropdownMenuItem<int?>>((p) => DropdownMenuItem(value: p.id, child: Text("${p.name} (${p.sku})"))).toList(), onChanged: (v) => setState(() {
        final p = prods.firstWhere((e) => e.id == v);
        _cart[index].productId = v!;
        _cart[index].unitPrice = p.purchasePrice;
      }), decoration: InputDecoration(hintText: "Select Item", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
    });
  }

  Widget _buildQuantityControl(int index) {
    return Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Row(children: [IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => setState(() { if(_cart[index].quantity > 1) _cart[index].quantity--; })), SizedBox(width: 40, child: Text(_cart[index].quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setState(() => _cart[index].quantity++)),]));
  }

  Widget _buildRateInput(int index) {
    return TextFormField(key: ValueKey('rate_${_cart[index].productId}_$index'), initialValue: _cart[index].unitPrice.toString(), keyboardType: TextInputType.number, onChanged: (v) => setState(() => _cart[index].unitPrice = double.tryParse(v) ?? 0.0), decoration: InputDecoration(labelText: "Unit Rate", prefixText: "₹ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  }

  Widget _buildFloatingSummary() {
    // 🔥 Grand Total updated to respect Conversion Factors
    double grandTotal = 0;
    for (var item in _cart) {
      double factor = _getConversionFactor(item.productId);
      grandTotal += (item.quantity * factor * item.unitPrice);
    }

    return Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.only(top: 24), decoration: BoxDecoration(color: const Color(0xFF1A1C24), borderRadius: BorderRadius.circular(24)), child: Row(children: [ElevatedButton.icon(onPressed: () => setState(() => _cart.add(PurchaseItemEntry(productId: 0))), icon: const Icon(Icons.add), label: const Text("MANUAL ADD"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20))), const Spacer(), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("GRAND TOTAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), Text("₹${grandTotal.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))]), const SizedBox(width: 32), ElevatedButton(onPressed: _postBill, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("POST BILL", style: TextStyle(fontWeight: FontWeight.bold)))]));
  }
}