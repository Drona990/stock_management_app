import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class InventoryProductEntity {
  final int? id;
  final String name, sku;
  final String? hsnCode, location, purchaseUnitName, image;
  final int category, unit;
  final int? brand, taxProfile;
  final String? categoryName, brandName, unitName, taxName;
  final double purchasePrice, sellingPrice, currentStock, minStockLevel, conversionFactor;
  final bool isPackItem, isTaxInclusive, trackExpiry;
  final double taxPercentage;

  InventoryProductEntity({
    this.id, required this.name, required this.sku, this.hsnCode,
    required this.category, this.categoryName, this.brand, this.brandName,
    required this.unit, this.unitName, required this.taxProfile, this.taxName,
    required this.purchasePrice, required this.sellingPrice,
    required this.currentStock, required this.minStockLevel,
    required this.isPackItem, this.purchaseUnitName,
    required this.conversionFactor, this.location,
    required this.isTaxInclusive, required this.trackExpiry, this.image,
    this.taxPercentage = 0.0,
  });


  factory InventoryProductEntity.fromJson(Map<String, dynamic> json) {
    final taxDetails = json['tax_details'] as Map<String, dynamic>?;

    return InventoryProductEntity(
      id: json['id'],
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      hsnCode: json['hsn_code'],
      category: json['category'] ?? 0,
      categoryName: json['category_details']?['name'],
      brand: json['brand'],
      brandName: json['brand_details']?['name'],
      unit: json['base_unit'] ?? 0,
      unitName: json['unit_details']?['short_name'],
      taxProfile: json['tax_profile'] ?? 0,
      taxName: json['tax_details']?['name'],
      image: json['image'],
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0.0') ?? 0.0,
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0.0') ?? 0.0,
      currentStock: double.tryParse(json['current_stock']?.toString() ?? '0.0') ?? 0.0,
      minStockLevel: double.tryParse(json['min_stock_level']?.toString() ?? '0.0') ?? 0.0,
      isPackItem: json['is_pack_item'] ?? false,
      purchaseUnitName: json['purchase_unit_name'],
      conversionFactor: double.tryParse(json['conversion_factor']?.toString() ?? '1.0') ?? 1.0,
      location: json['location'],
      isTaxInclusive: json['is_tax_inclusive'] ?? false,
      trackExpiry: json['track_expiry'] ?? false,
      taxPercentage: double.tryParse(taxDetails?['tax_percentage']?.toString() ?? "0.0") ?? 0.0,
    );
  }


  Map<String, dynamic> toJson() => {
    "name": name, "sku": sku, "hsn_code": hsnCode, "category": category,
    "brand": brand, "base_unit": unit, "tax_profile": taxProfile,
    "purchase_price": purchasePrice, "selling_price": sellingPrice,
    "min_stock_level": minStockLevel, "is_pack_item": isPackItem,
    "purchase_unit_name": purchaseUnitName, "conversion_factor": conversionFactor,
    "location": location, "is_tax_inclusive": isTaxInclusive, "track_expiry": trackExpiry,
  };
}

class InventoryProductRepository {
  final ApiClient apiClient = sl<ApiClient>();
  Future<List<InventoryProductEntity>> getProducts() async {
    final res = await apiClient.get('/api/inventory/products/');
    final List data = (res.data is Map) ? res.data['results'] : res.data;
    return data.map((x) => InventoryProductEntity.fromJson(x)).toList();
  }
  Future<void> saveProduct(InventoryProductEntity p, File? image, bool isUpdate) async {
    Map<String, dynamic> data = p.toJson();
    if (image != null) data["image"] = await MultipartFile.fromFile(image.path, contentType: MediaType('image', 'jpeg'));
    FormData formData = FormData.fromMap(data);
    if (isUpdate) { await apiClient.put('/api/inventory/products/${p.id}/', data: formData); }
    else { await apiClient.post('/api/inventory/products/', data: formData); }
  }
}

abstract class ProductEvent {}
class LoadProducts extends ProductEvent {}
class AddProduct extends ProductEvent { final InventoryProductEntity product; final File? imageFile; AddProduct(this.product, {this.imageFile}); }
class UpdateProduct extends ProductEvent { final InventoryProductEntity product; final File? imageFile; UpdateProduct(this.product, {this.imageFile}); }

abstract class ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState { final List<InventoryProductEntity> products; ProductLoaded(this.products); }
class ProductError extends ProductState { final String msg; ProductError(this.msg); }

class InventoryProductBloc extends Bloc<ProductEvent, ProductState> {
  final InventoryProductRepository repo;
  InventoryProductBloc(this.repo) : super(ProductLoading()) {
    on<LoadProducts>((e, emit) async {
      emit(ProductLoading());
      try { emit(ProductLoaded(await repo.getProducts())); } catch (e) { emit(ProductError(e.toString())); }
    });
    on<AddProduct>((e, emit) async {
      try { await repo.saveProduct(e.product, e.imageFile, false); add(LoadProducts()); } catch (e) { emit(ProductError(e.toString())); }
    });
    on<UpdateProduct>((e, emit) async {
      try { await repo.saveProduct(e.product, e.imageFile, true); add(LoadProducts()); } catch (e) { emit(ProductError(e.toString())); }
    });
  }
}