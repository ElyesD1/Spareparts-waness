import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class WarehouseService {
  static final String _baseUrl = AppConfig.warehousesUrl;

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

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final headers = await _getHeaders();
    final url = Uri.parse(_baseUrl);
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final warehouses = data.cast<Map<String, dynamic>>();

      // Normalize MongoDB _id to id for each warehouse
      for (var warehouse in warehouses) {
        if (warehouse['_id'] != null) {
          // Handle MongoDB ObjectId format: {"$oid": "xxx"} or just the string
          final id = warehouse['_id'];
          if (id is Map && id['\$oid'] != null) {
            warehouse['id'] = id['\$oid'];
          } else if (id is String) {
            warehouse['id'] = id;
          } else {
            warehouse['id'] = id.toString();
          }
        }
      }

      return warehouses;
    } else {
      throw Exception('Failed to load warehouses: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getWarehouse(String id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load warehouse');
    }
  }

  Future<Map<String, dynamic>> addWarehouse(
    Map<String, dynamic> warehouse,
  ) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(warehouse),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to add warehouse');
    }
  }

  Future<Map<String, dynamic>> updateWarehouse(
    String id,
    Map<String, dynamic> warehouse,
  ) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(warehouse),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update warehouse');
    }
  }

  Future<void> deleteWarehouse(String id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.delete(url);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete warehouse');
    }
  }
}
