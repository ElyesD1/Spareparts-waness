import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/product_stock.dart';

class ProductStockService {
  static const String baseUrl = 'http://localhost:3000/product-stocks';

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Add stock to a product in a specific warehouse
  Future<void> addStock(
    String productId,
    String warehouseId,
    int quantity,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        // Changed from POST to PUT
        Uri.parse('$baseUrl/update-stock'), // Changed endpoint
        headers: headers,
        body: jsonEncode({
          'product_id': productId,
          'warehouse_id': warehouseId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add stock: ${response.body}');
      }

      print(
        'Stock added successfully for product $productId in warehouse $warehouseId: $quantity units',
      );
    } catch (e) {
      print('Error adding stock: $e');
      throw Exception('Error adding stock: $e');
    }
  }

  // Get current stock for a product in a specific warehouse
  Future<int> getCurrentStock(String productId, String warehouseId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/stock-level/$productId/$warehouseId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stockLevel'] ?? 0;
      } else {
        throw Exception('Failed to get stock level: ${response.body}');
      }
    } catch (e) {
      print('Error getting stock level: $e');
      return 0;
    }
  }

  // Update stock for a product in a specific warehouse
  Future<void> updateStock(
    String productId,
    String warehouseId,
    int newQuantity,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/update-stock'),
        headers: headers,
        body: jsonEncode({
          'product_id': productId,
          'warehouse_id': warehouseId,
          'quantity': newQuantity,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update stock: ${response.body}');
      }

      print(
        'Stock updated successfully for product $productId in warehouse $warehouseId: $newQuantity units',
      );
    } catch (e) {
      print('Error updating stock: $e');
      throw Exception('Error updating stock: $e');
    }
  }

  // Get all product stocks
  Future<List<ProductStock>> getAllProductStocks() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductStock.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get product stocks: ${response.body}');
      }
    } catch (e) {
      print('Error getting product stocks: $e');
      throw Exception('Error getting product stocks: $e');
    }
  }
}
