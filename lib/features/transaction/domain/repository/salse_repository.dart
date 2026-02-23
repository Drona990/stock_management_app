import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../entity/salse_entity.dart';

class SaleRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<SaleHistoryEntity> createSale(List<SaleItemEntry> items) async {
    try {
      final data = {
        "invoice_no": "INV-${DateTime.now().millisecondsSinceEpoch}",
        "items_data": items.map((e) => e.toJson()).toList(),
      };

      debugPrint("📤 [Repo] Sending Data: $data");
      final res = await apiClient.post('/api/transaction/sales/', data: data);
      debugPrint("📥 [Repo] Backend Response: ${res.data}");

      return SaleHistoryEntity.fromJson(res.data);
    } catch (e) {
      debugPrint("❌ [Repo] Create Error: $e");
      rethrow;
    }
  }
  Future<List<SaleHistoryEntity>> getHistory() async {
    try {
      debugPrint("📡 FETCHING SALE HISTORY...");

      final res = await apiClient.get('/api/transaction/sales/');

      // 📝 LOG: Check karo data results mein hai ya direct list hai
      debugPrint("📄 RAW HISTORY DATA: ${res.data}");

      final List data = (res.data is Map && res.data.containsKey('results'))
          ? res.data['results'] : res.data;

      return data.map((x) => SaleHistoryEntity.fromJson(x)).toList();

    } catch (e) {
      debugPrint("❌ HISTORY FETCH ERROR: $e");
      rethrow;
    }
  }
}