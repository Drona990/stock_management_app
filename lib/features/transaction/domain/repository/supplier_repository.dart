import 'package:flutter/cupertino.dart';

import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../entity/supplier_entity.dart';

class SupplierRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<SupplierEntity>> getSuppliers() async {
    try {
      final res = await apiClient.get('/api/transaction/suppliers/');
      // 💡 Logical Fix: Check if data is inside 'results' (Pagination) or direct list
      final dynamic responseData = res.data;
      List data;
      if (responseData is Map && responseData.containsKey('results')) {
        data = responseData['results'];
      } else {
        data = responseData;
      }
      return data.map((x) => SupplierEntity.fromJson(x)).toList();
    } catch (e) {
      debugPrint("Repository Error: $e");
      rethrow;
    }
  }

  Future<void> createSupplier(SupplierEntity s) async =>
      await apiClient.post('/api/transaction/suppliers/', data: s.toJson());

  Future<void> deleteSupplier(int id) async =>
      await apiClient.delete('/api/transaction/suppliers/$id/');
}