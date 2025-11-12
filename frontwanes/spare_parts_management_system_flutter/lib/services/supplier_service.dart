import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SupplierService {
  static final String _baseUrl = AppConfig.suppliersUrl;

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final url = Uri.parse(_baseUrl);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final suppliers = data.cast<Map<String, dynamic>>();

      // Normalize MongoDB ObjectId format to simple string id
      return suppliers.map((supplier) {
        final normalized = Map<String, dynamic>.from(supplier);

        // Handle MongoDB ObjectId format
        if (supplier['_id'] != null) {
          final id = supplier['_id'];
          if (id is Map && id['\$oid'] != null) {
            normalized['id'] = id['\$oid'].toString();
          } else {
            normalized['id'] = id.toString();
          }
        } else if (supplier['id'] != null) {
          normalized['id'] = supplier['id'].toString();
        }

        return normalized;
      }).toList();
    } else {
      throw Exception('Failed to load suppliers');
    }
  }

  Future<Map<String, dynamic>> addSupplier(
    Map<String, dynamic> supplier,
  ) async {
    final url = Uri.parse(_baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(supplier),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to add supplier');
    }
  }

  Future<Map<String, dynamic>> updateSupplier(
    String id,
    Map<String, dynamic> supplier,
  ) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(supplier),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update supplier');
    }
  }

  Future<void> deleteSupplier(String id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.delete(url);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete supplier');
    }
  }

  Future<Map<String, dynamic>> getSupplier(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load supplier');
    }
  }
}
