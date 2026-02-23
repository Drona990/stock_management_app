
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/transaction/presentation/pages/salse_history_sidebar.dart';
import '../../../inventory/presentation/bloc/inventory_product_management_bloc.dart';
import '../../domain/entity/salse_entity.dart';
import '../bloc/salse_bloc.dart';
import 'generate_invoice.dart';

class SalesMasterView extends StatefulWidget {
  const SalesMasterView({super.key});
  @override
  State<SalesMasterView> createState() => _SalesMasterViewState();
}

class _SalesMasterViewState extends State<SalesMasterView> {
  final _customerName = TextEditingController(text: "Walk-in Customer");
  final FocusNode _keyboardFocusNode = FocusNode();
  List<SaleItemEntry> _cart = [];
  String _barcodeBuffer = "";
  String _paymentMode = 'CASH';

  @override
  void initState() {
    super.initState();
    context.read<SaleBloc>().add(LoadSaleHistory());
    context.read<InventoryProductBloc>().add(LoadProducts());
  }

  // 🛒 Manual Logic: Button se item add karo
  void _addManualRow() {
    setState(() {
      _cart.add(SaleItemEntry(
        productId: 0,
        quantity: 1.0,
        unitPrice: 0.0,
        taxPercentage: 0.0, // Default tax
      ));
    });
  }

  // 🔫 Barcode Logic
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
        final p = state.products.firstWhere((element) => element.sku == code);

        // 💡 Log lagaya hai check karne ke liye
        debugPrint("🔍 BARCODE SCAN: ${p.name} | Tax in Entity: ${p.taxPercentage}");

        setState(() {
          _cart.add(SaleItemEntry(
            productId: p.id!,
            quantity: 1,
            unitPrice: p.sellingPrice,
            productName: p.name,
            taxPercentage: p.taxPercentage, // 💡 Seedha entity se uthayein
          ));
        });
      } catch (e) {
        _showErrorSnackBar("SKU: $code Not found!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 CALCULATION: Tax ke saath screen total
    double total = _cart.fold(0, (sum, item) {
      double base = item.quantity * item.unitPrice;
      double tax = base * (item.taxPercentage / 100);
      return sum + base + tax;
    });

    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKey: _handleBarcodeKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: BlocListener<SaleBloc, SaleState>(
          listener: (context, state) {
            if (state is SaleSuccess) {
              setState(() => _cart = []);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.msg), backgroundColor: Colors.green)
              );
              // 💡 Backend se aaye fresh data se invoice generate karein
              PdfInvoiceService.generateInvoice(state.newSale);
            }
            if (state is SaleError) {
              _showErrorSnackBar(state.msg);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 24),
                _buildBillMasterCard(),
                const SizedBox(height: 32),
                _buildSectionHeader("ITEMS IN CART / बिक्री सूची"),
                Expanded(child: _buildCartList()),
                _buildFloatingSummary(total),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Sales Master (POS)", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        Text("Type SKU and press Enter to test without scanner", style: TextStyle(color: Color(0xFF64748B))),
      ]),
      ElevatedButton.icon(
        onPressed: () => _openHistorySidebar(context),
        icon: const Icon(Icons.receipt_long),
        label: const Text("SALES LOGS"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );

  Widget _buildBillMasterCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
    child: Row(children: [
      Expanded(flex: 2, child: TextFormField(controller: _customerName, decoration: const InputDecoration(labelText: "Customer Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()))),
      const SizedBox(width: 20),
      Expanded(child: DropdownButtonFormField<String>(value: _paymentMode, items: const [DropdownMenuItem(value: "CASH", child: Text("Cash")), DropdownMenuItem(value: "ONLINE", child: Text("Online"))], onChanged: (v)=> setState(()=> _paymentMode = v!), decoration: const InputDecoration(labelText: "Payment Mode", border: OutlineInputBorder()))),
    ]),
  );

  Widget _buildCartList() => _cart.isEmpty
      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade200), const Text("Cart Empty. Add rows or scan items.", style: TextStyle(color: Colors.grey))]))
      : ListView.builder(itemCount: _cart.length, itemBuilder: (ctx, i) => _buildItemCard(i));

  Widget _buildItemCard(int i) {
    double itemBase = _cart[i].quantity * _cart[i].unitPrice;
    double itemTax = itemBase * (_cart[i].taxPercentage / 100);
    double itemTotal = itemBase + itemTax;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(flex: 3, child: _productPicker(i)),
          const SizedBox(width: 20),
          _qtyControl(i),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${itemTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF00BCD4))),
              Text("incl. ${_cart[i].taxPercentage}% GST", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() => _cart.removeAt(i))),
        ],
      ),
    );
  }


  Widget _productPicker(int i) {
    return BlocBuilder<InventoryProductBloc, ProductState>(builder: (context, state) {
      final prods = (state is ProductLoaded) ? state.products : [];
      return DropdownButtonFormField<int?>(
        isExpanded: true,
        value: _cart[i].productId == 0 ? null : _cart[i].productId,
        items: prods.map((p) => DropdownMenuItem<int?>(
            value: p.id,
            child: Text("${p.name} (Stock: ${p.currentStock.toInt()})")
        )).toList(),
        onChanged: (v) {
          final p = prods.firstWhere((e) => e.id == v);

          // 💡 YAHAN HAI ASLI CHECH: Console mein dekhein selection par kya aata hai
          debugPrint("🎯 DROPDOWN SELECT: ${p.name}");
          debugPrint("📊 Entity Tax Value: ${p.taxPercentage}");
          debugPrint("🏷️ Entity Tax Name: ${p.taxName}");

          setState(() {
            _cart[i].productId = v!;
            _cart[i].unitPrice = p.sellingPrice;
            _cart[i].productName = p.name;

            // 💡 FIXED LINE: Default value hata di hai taaki asli data dikhe
            _cart[i].taxPercentage = p.taxPercentage;
          });
        },
        decoration: const InputDecoration(border: InputBorder.none, hintText: "Select Product Manually"),
      );
    });
  }



  Widget _qtyControl(int i) => Row(children: [
    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { if(_cart[i].quantity > 1) _cart[i].quantity--; })),
    Text(_cart[i].quantity.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _cart[i].quantity++)),
  ]);


  Widget _buildFloatingSummary(double total) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFF1A1C24), borderRadius: BorderRadius.circular(24)),
    child: Row(
      children: [
        ElevatedButton.icon(
          onPressed: _addManualRow,
          icon: const Icon(Icons.add),
          label: const Text("ADD ROW"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("GRAND TOTAL (Incl. Tax)", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
            Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(width: 32),
        ElevatedButton(
          onPressed: _validateAndCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("CHECKOUT", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  void _validateAndCheckout() {
    if (_cart.isEmpty) {
      _showErrorSnackBar("Your cart is empty!");
      return;
    }

    final productState = context.read<InventoryProductBloc>().state;
    if (productState is ProductLoaded) {
      for (var item in _cart) {
        if (item.productId == 0) {
          _showErrorSnackBar("Please select a product for all rows.");
          return;
        }
        final p = productState.products.firstWhere((p) => p.id == item.productId);
        if (item.quantity > p.currentStock) {
          _showErrorSnackBar("Insufficient stock for ${p.name}! (Available: ${p.currentStock.toInt()})");
          return;
        }
      }
      context.read<SaleBloc>().add(PostSaleInvoice(_cart));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange.shade900, behavior: SnackBarBehavior.floating),
    );
  }

  void _openHistorySidebar(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "History",
      pageBuilder: (ctx, anim1, anim2) => Align(
        alignment: Alignment.centerRight,
        child: Material(elevation: 40, child: BlocProvider.value(value: context.read<SaleBloc>(), child: const SalesHistorySidebar())),
      ),
      transitionBuilder: (ctx, a1, a2, child) => SlideTransition(position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(a1), child: child),
    );
  }

  Widget _buildSectionHeader(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B))));
}