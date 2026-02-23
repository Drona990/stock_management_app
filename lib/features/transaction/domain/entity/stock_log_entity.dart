class StockLogEntity {
  final int id;
  final String productName;
  final String transactionType;
  final double quantityChanged;
  final double balanceAfter;
  final String referenceId;
  final DateTime createdAt;
  final String note;

  StockLogEntity({
    required this.id, required this.productName, required this.transactionType,
    required this.quantityChanged, required this.balanceAfter,
    required this.referenceId, required this.createdAt, required this.note,
  });

  factory StockLogEntity.fromJson(Map<String, dynamic> json) => StockLogEntity(
    id: json['id'],
    productName: json['product_name'] ?? "Unknown",
    transactionType: json['transaction_type'],
    quantityChanged: double.parse(json['quantity_changed'].toString()),
    balanceAfter: double.parse(json['balance_after'].toString()),
    referenceId: json['reference_id'] ?? "",
    createdAt: DateTime.parse(json['created_at']),
    note: json['note'] ?? "",
  );
}

class WastageEntity {
  final int? id;
  final int productId;
  final String? productName;
  final double quantity;
  final String reason;
  final DateTime? wastedAt;

  WastageEntity({this.id, required this.productId, this.productName, required this.quantity, required this.reason, this.wastedAt});

  Map<String, dynamic> toJson() => {
    "product": productId,
    "quantity": quantity,
    "reason": reason,
  };

  factory WastageEntity.fromJson(Map<String, dynamic> json) => WastageEntity(
    id: json['id'],
    productId: json['product'],
    productName: json['product_name'],
    quantity: double.parse(json['quantity'].toString()),
    reason: json['reason'] ?? "",
    wastedAt: DateTime.parse(json['wasted_at']),
  );
}