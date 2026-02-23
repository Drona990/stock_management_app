import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class SupplierEntity {
  final int? id;
  final String name;
  final String phone;
  final String? gstNumber;
  final String? address;
  final bool isActive;

  SupplierEntity({
    this.id,
    required this.name,
    required this.phone,
    this.gstNumber,
    this.address,
    this.isActive = true,
  });

  factory SupplierEntity.fromJson(Map<String, dynamic> json) => SupplierEntity(
    id: json['id'],
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    gstNumber: json['gst_number'],
    address: json['address'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "phone": phone,
    "gst_number": gstNumber,
    "address": address,
    "is_active": isActive,
  };
}

