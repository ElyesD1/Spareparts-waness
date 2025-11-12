import 'http_client.dart';

class SalesService {
  final ApiClient _api;
  SalesService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Map<String, dynamic>>> getSales() async {
    final data = await _api.get('/sales');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> saleData) async {
    final sale = await _api.post('/sales', saleData);
    return sale as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSale(String id, Map<String, dynamic> saleData) async {
    final sale = await _api.put('/sales/$id', saleData);
    return sale as Map<String, dynamic>;
  }

  Future<void> deleteSale(String id) async {
    await _api.delete('/sales/$id');
  }

  /// Returns the count of sales for the current month
  Future<int> getSalesCountForCurrentMonth() async {
    try {
      final sales = await getSales();
      final now = DateTime.now();
      final currentMonthSales = sales.where((sale) {
        final saleDateStr = sale['sale_date'] ?? '';
        final saleDate = DateTime.tryParse(saleDateStr);
        return saleDate != null &&
          saleDate.year == now.year &&
          saleDate.month == now.month;
      }).toList();
      
      return currentMonthSales.length;
    } catch (e) {
      return 0;
    }
  }
} 
