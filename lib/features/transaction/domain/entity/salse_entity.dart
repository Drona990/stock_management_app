class SaleItemEntry {
  int productId;
  String productName;
  String productBarcode;
  double quantity;
  double unitPrice;
  double taxPercentage;
  double lineTotal; // 💡 Added this field

  SaleItemEntry({
    required this.productId,
    this.productName = "",
    this.productBarcode = "",
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.taxPercentage = 0.0,
    this.lineTotal = 0.0, // 💡 Initialize
  });

  factory SaleItemEntry.fromJson(Map<String, dynamic> json) {
    double qty = double.tryParse(json['quantity']?.toString() ?? "0.0") ?? 0.0;
    double price = double.tryParse(json['unit_price']?.toString() ?? "0.0") ?? 0.0;

    return SaleItemEntry(
      productId: json['product'] ?? 0,
      productName: json['product_name'] ?? "Unknown",
      productBarcode: json['product_barcode'] ?? "N/A",
      quantity: qty,
      unitPrice: price,
      taxPercentage: double.tryParse(json['tax_percentage']?.toString() ?? "0.0") ?? 0.0,
      lineTotal: double.tryParse(json['line_total']?.toString() ?? "0.0") ?? (qty * price),
    );
  }

  Map<String, dynamic> toJson() => {
    "product": productId,
    "quantity": quantity,
    "unit_price": unitPrice,
    "tax_percentage": taxPercentage,
  };
}
class SaleHistoryEntity {
  final int id;
  final String invoiceNo;
  final DateTime saleDate;
  final double totalAmount;
  final List<SaleItemEntry> items;

  SaleHistoryEntity({
    required this.id,
    required this.invoiceNo,
    required this.saleDate,
    required this.totalAmount,
    required this.items,
  });

  factory SaleHistoryEntity.fromJson(Map<String, dynamic> json) => SaleHistoryEntity(
    id: json['id'],
    invoiceNo: json['invoice_no'] ?? "N/A",
    saleDate: DateTime.parse(json['sale_date']),
    totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
    items: (json['items'] as List?)?.map((i) => SaleItemEntry.fromJson(i)).toList() ?? [],
  );
}