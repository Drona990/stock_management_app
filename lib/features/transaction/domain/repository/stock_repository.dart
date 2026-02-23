import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../entity/stock_log_entity.dart';

class StockRepository {
  final ApiClient apiClient = sl<ApiClient>();

  // Fetch Stock Logs with optional filters
  Future<List<StockLogEntity>> getStockLogs({String? productId, String? type}) async {
    final res = await apiClient.get('/api/ledger/logs/', query: {
      if (productId != null) 'product': productId,
      if (type != null) 'transaction_type': type,
    });
    final List data = res.data is Map ? res.data['results'] : res.data;
    return data.map((x) => StockLogEntity.fromJson(x)).toList();
  }

  // Report Wastage
  Future<void> reportWastage(WastageEntity wastage) async {
    await apiClient.post('/api/ledger/wastage/', data: wastage.toJson());
  }
}