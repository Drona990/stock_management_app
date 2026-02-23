import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../entity/purchase_entity.dart';

class PurchaseRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<PurchaseHistoryEntity>> getHistory() async {
    final res = await apiClient.get('/api/transaction/purchases/');

    // 💡 Backend ka raw data dekhne ke liye yahan log karein
    print("--- BACKEND RAW RESPONSE START ---");
    print(res.data);
    print("--- BACKEND RAW RESPONSE END ---");

    final List data = (res.data is Map) ? res.data['results'] : res.data;

    // Individual item check karne ke liye
    if (data.isNotEmpty) {
      print("First Record Structure: ${data[0]}");
    }

    return data.map((x) => PurchaseHistoryEntity.fromJson(x)).toList();
  }

  Future<void> createPurchase(Map<String, dynamic> data) async {
    print("Sending to Backend: $data");
    await apiClient.post('/api/transaction/purchases/', data: data);
  }
}