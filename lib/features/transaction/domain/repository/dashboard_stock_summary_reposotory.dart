import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../entity/dashboard_stock_summary_entity.dart';

class DashboardStockSummaryRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<DashboardStockSummaryEntity> getSummary() async {
    try {
      final res = await apiClient.get('/api/dashboard/stock-summary/');

      debugPrint("📄 [REPO] RAW DATA: ${res.data}");

      if (res.data != null) {
        final stats = res.data['stats'];
        final inv = res.data['inventory'];
        debugPrint("📊 [DEBUG] Stats Found: ${stats != null}, Inventory Found: ${inv != null}");
      }

      final entity = DashboardStockSummaryEntity.fromJson(res.data);

      debugPrint("🏁 [REPO] Step 3: Entity Parsing Successful. Sales: ${entity.sales}");

      return entity;

    } catch (e, stacktrace) {
      debugPrint("🆘 [REPO ERROR] Dashboard Sync Failed!");
      debugPrint("Reason: $e");
      debugPrint("Stacktrace: $stacktrace");

      throw Exception("Dashboard API sync failed: $e");
    }
  }
}