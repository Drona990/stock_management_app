class PurchaseItemEntry {
  int productId;
  String productName;
  double quantity;
  double unitPrice;
  double taxPercentage;
  String productBarcode;

  PurchaseItemEntry({
    required this.productId,
    this.productName = "",
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.taxPercentage = 0.0,
    this.productBarcode = "",
  });

  Map<String, dynamic> toJson() => {
    "product": productId,
    "quantity": quantity,
    "unit_price": unitPrice,
    "tax_percentage": taxPercentage,
  };

  factory PurchaseItemEntry.fromJson(Map<String, dynamic> json) => PurchaseItemEntry(
    productId: json['product'] ?? 0,
    productName: json['product_name'] ?? "Item",
    quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
    unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
    taxPercentage: double.tryParse(json['tax_percentage'].toString()) ?? 0.0,
    productBarcode: json['product_barcode'] ?? "N/A",
  );
}

class PurchaseHistoryEntity {
  final int id;
  final String billNumber;
  final String supplierName;
  final String purchaseDate; // 💡 String rakha hai taaki UI mein split karna asaan ho
  final String paymentMode;
  final double totalAmount;
  final List<PurchaseItemEntry> items;

  PurchaseHistoryEntity({
    required this.id,
    required this.billNumber,
    required this.supplierName,
    required this.purchaseDate,
    required this.paymentMode,
    required this.totalAmount,
    required this.items,
  });

  factory PurchaseHistoryEntity.fromJson(Map<String, dynamic> json) => PurchaseHistoryEntity(
    id: json['id'],
    billNumber: json['bill_number'] ?? "",
    supplierName: json['supplier_name'] ?? "N/A",
    purchaseDate: json['purchase_date'] ?? "", // 💡 Backend key matches here
    paymentMode: json['payment_mode'] ?? "CASH",
    totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
    items: (json['items'] as List?)?.map((i) => PurchaseItemEntry.fromJson(i)).toList() ?? [],
  );
}