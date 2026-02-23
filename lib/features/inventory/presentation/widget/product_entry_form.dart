import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/features/inventory/presentation/widget/tax_profile_view.dart';
import '../bloc/inventory_category.dart';
import '../bloc/inventory_product_management_bloc.dart';
import 'inventory_units_view.dart';

class ProductEntryForm extends StatefulWidget {
  final InventoryProductEntity? existingProduct;
  const ProductEntryForm({super.key, this.existingProduct});

  @override
  State<ProductEntryForm> createState() => _ProductEntryFormState();
}

class _ProductEntryFormState extends State<ProductEntryForm> {
  // 📝 Controllers
  final name = TextEditingController();
  final sku = TextEditingController();
  final pPrice = TextEditingController();
  final sPrice = TextEditingController();
  final hsn = TextEditingController();
  final location = TextEditingController();
  final convFactor = TextEditingController(text: "1.0");
  final minStock = TextEditingController(text: "5.0");
  final pUnitName = TextEditingController();

  // ⚙️ State Variables
  File? _file;
  int? selCat, selUnit, selTax;
  bool isPack = false, trackExp = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      name.text = p.name;
      sku.text = p.sku;
      pPrice.text = p.purchasePrice.toString();
      sPrice.text = p.sellingPrice.toString();
      hsn.text = p.hsnCode ?? "";
      location.text = p.location ?? "";
      isPack = p.isPackItem;
      selCat = p.category;
      selUnit = p.unit;
      selTax = p.taxProfile;
      trackExp = p.trackExpiry;
      convFactor.text = p.conversionFactor.toString();
      minStock.text = p.minStockLevel.toString();
      pUnitName.text = p.purchaseUnitName ?? "";
    }
  }

  // 💡 Pure English & Pure Hindi Help Dialog
  void _showHelp(String title, String engMsg, String hinMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENGLISH", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 12, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Text(engMsg, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            const Text("हिन्दी", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orangeAccent, fontSize: 12, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Text(hinMsg, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE / बंद करें", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BCD4))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPanelHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              _sectionTitle("Visual Identity / पहचान"),
              _imagePickerUI(),
              const SizedBox(height: 32),
              _buildAdvancedField(
                  name, "Product Name / उत्पाद का नाम", Icons.badge_outlined,
                  "Enter the full name of the product as it will appear on invoices.",
                  "उत्पाद का पूरा नाम दर्ज करें जैसा कि बिल पर दिखाई देगा।"
              ),
              _buildAdvancedField(
                  sku, "SKU - Barcode / बारकोड", Icons.qr_code_scanner,
                  "Unique identifier for the product (Stock Keeping Unit). You can scan a barcode here.",
                  "उत्पाद के लिए विशिष्ट कोड (स्टॉक कीपिंग यूनिट)। आप यहाँ बारकोड स्कैन कर सकते हैं।"
              ),
              const SizedBox(height: 24),
              _sectionTitle("Inventory Strategy / स्टॉक रणनीति"),
              _buildStrategyBox(),
              const SizedBox(height: 24),
              _sectionTitle("Pricing & Financials / कीमत और टैक्स"),
              _buildPricingBox(),
              const SizedBox(height: 24),
              _sectionTitle("Classification / वर्गीकरण"),
              _buildDropdowns(),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildAdvancedField(TextEditingController c, String label, IconData i, String engHelp, String hinHelp, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showHelp(label, engHelp, hinHelp),
                child: const Icon(Icons.info_outline, size: 16, color: Color(0xFF00BCD4)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: c,
            keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(i, size: 20, color: const Color(0xFF64748B)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00BCD4))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyBox() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
    child: Column(children: [
      Row(children: [
        Expanded(child: _buildAdvancedField(
            hsn, "HSN Code / एचएसएन", Icons.gavel,
            "Harmonized System Nomenclature code for tax classification.",
            "टैक्स वर्गीकरण के लिए एचएसएन कोड दर्ज करें।"
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildAdvancedField(
            location, "Location / स्थान", Icons.door_sliding_outlined,
            "Specific shelf or aisle where this item is stored.",
            "वह शेल्फ या जगह जहाँ यह आइटम रखा गया है।"
        )),
      ]),
      _buildAdvancedField(
          minStock, "Min Alert Qty / न्यूनतम स्टॉक", Icons.warning_amber_rounded,
          "Minimum quantity to keep in stock before getting a low stock alert.",
          "लो स्टॉक अलर्ट मिलने से पहले स्टॉक में रखने के लिए न्यूनतम मात्रा।",
          isNum: true
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Track Expiry / एक्सपायरी ट्रैक", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        value: trackExp, onChanged: (v) => setState(() => trackExp = v),
        secondary: IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            onPressed: () => _showHelp("Expiry Tracking", "Required for perishable goods to monitor use-by dates.", "खराब होने वाली वस्तुओं की एक्सपायरी डेट ट्रैक करने के लिए आवश्यक।")
        ),
      ),
      const Divider(height: 32),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text("Bulk Pack Logic / थोk रूपांतरण", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        value: isPack, onChanged: (v) => setState(() => isPack = v),
        secondary: IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            onPressed: () => _showHelp("Bulk Conversion", "Use if you buy in bulk (Boxes) and sell in units (Pieces).", "उपयोग करें यदि आप थोक (डिब्बे) में खरीदते हैं और यूनिट (पीस) में बेचते हैं।")
        ),
      ),
      if(isPack) ...[
        _buildAdvancedField(pUnitName, "Pack Unit / पैक इकाई", Icons.inventory_2_outlined, "Name of the bulk package (e.g. Carton, Crate).", "थोक पैकेज का नाम (जैसे: कार्टन, क्रेट)।"),
        _buildAdvancedField(convFactor, "Ratio / अनुपात", Icons.calculate_outlined, "Number of base units inside one bulk pack.", "एक थोक पैक के अंदर बेस यूनिट्स की संख्या।", isNum: true),
      ]
    ]),
  );

  Widget _buildPricingBox() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      Row(children: [
        Expanded(child: _buildAdvancedField(pPrice, "Purchase Rate / खरीद दर", Icons.payments_outlined, "Cost price per unit from the supplier.", "सप्लायर से प्रति यूनिट खरीद मूल्य।", isNum: true)),
        const SizedBox(width: 16),
        Expanded(child: _buildAdvancedField(sPrice, "Selling Rate / बिक्री दर", Icons.sell_outlined, "Selling price per unit for customers.", "ग्राहकों के लिए प्रति यूनिट बिक्री मूल्य।", isNum: true)),
      ]),
      const SizedBox(height: 12),
      _buildDropHeader("Tax Profile / टैक्स प्रोफाइल", "Applicable GST rate for this product.", "इस उत्पाद के लिए लागू जीएसटी दर।"),
      _taxDrop(),
    ]),
  );

  Widget _buildDropdowns() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildDropHeader("Category / श्रेणी", "Select the category this product belongs to.", "वह श्रेणी चुनें जिससे यह उत्पाद संबंधित है।"),
    _catDrop(),
    const SizedBox(height: 20),
    _buildDropHeader("Base Unit / आधार इकाई", "Smallest unit for consumption or sale.", "खपत या बिक्री के लिए सबसे छोटी इकाई।"),
    _unitDrop(),
  ]);

  Widget _buildDropHeader(String label, String engH, String hinH) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
    const SizedBox(width: 6),
    GestureDetector(onTap: () => _showHelp(label, engH, hinH), child: const Icon(Icons.info_outline, size: 16, color: Color(0xFF00BCD4))),
  ]);

  Widget _buildPanelHeader() => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
    child: Row(children: [
      const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF00BCD4)),
      const SizedBox(width: 12),
      Text(widget.existingProduct == null ? "Register New Item / नया आइटम" : "Edit / सुधार", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Spacer(),
      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
    ]),
  );

  Widget _imagePickerUI() => GestureDetector(
    onTap: () async {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
      if(img != null) setState(() => _file = File(img.path));
    },
    child: Container(
      height: 160, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: _file != null
          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_file!, fit: BoxFit.cover))
          : (widget.existingProduct?.image != null
          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(widget.existingProduct!.image!, fit: BoxFit.cover))
          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: Colors.grey), Text("Add Photo / फोटो जोड़ें", style: TextStyle(fontSize: 12, color: Colors.grey))])),
    ),
  );

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
    child: Row(children: [
      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("DISCARD / रद्द करें"))),
      const SizedBox(width: 20),
      Expanded(child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20)),
          onPressed: _save,
          child: Text(widget.existingProduct == null ? "SAVE / सुरक्षित करें" : "UPDATE / अपडेट", style: const TextStyle(fontWeight: FontWeight.bold)))),
    ]),
  );

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF00BCD4), letterSpacing: 1.5)));

  Widget _catDrop() => BlocBuilder<InventoryCategoryBloc, InventoryCategoryState>(builder: (context, state) => _drop((state is InvCategoryLoaded) ? state.categories : [], "Select Category", (v) => selCat = v, selCat));
  Widget _unitDrop() => BlocBuilder<InventoryUnitBloc, InvUnitState>(builder: (context, state) => _drop((state is InvUnitLoaded) ? state.units : [], "Select Unit", (v) => selUnit = v, selUnit));
  Widget _taxDrop() => BlocBuilder<TaxProfileBloc, TaxState>(builder: (context, state) => _drop((state is TaxLoaded) ? state.taxes : [], "Select Tax Profile", (v) => selTax = v, selTax));

  Widget _drop(List items, String l, Function(int?) onCh, int? val) => DropdownButtonFormField<int>(
    value: val, items: items.map<DropdownMenuItem<int>>((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
    onChanged: (v) => setState(() => onCh(v)),
    decoration: InputDecoration(hintText: l, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200))),
  );

  void _save() {
    if (name.text.isEmpty || selCat == null || selUnit == null) return;
    final p = InventoryProductEntity(
        id: widget.existingProduct?.id, name: name.text, sku: sku.text, category: selCat!, unit: selUnit!,
        purchasePrice: double.tryParse(pPrice.text) ?? 0.0, sellingPrice: double.tryParse(sPrice.text) ?? 0.0,
        currentStock: widget.existingProduct?.currentStock ?? 0.0, minStockLevel: double.tryParse(minStock.text) ?? 5.0,
        isPackItem: isPack, purchaseUnitName: pUnitName.text, conversionFactor: double.tryParse(convFactor.text) ?? 1.0,
        location: location.text, hsnCode: hsn.text, trackExpiry: trackExp, taxProfile: selTax ?? 0, isTaxInclusive: false,
        image: widget.existingProduct?.image
    );
    if(widget.existingProduct == null) {
      context.read<InventoryProductBloc>().add(AddProduct(p, imageFile: _file));
    } else {
      context.read<InventoryProductBloc>().add(UpdateProduct(p, imageFile: _file));
    }
    Navigator.pop(context);
  }
}