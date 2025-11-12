import 'dart:convert';
import 'package:http/http.dart' as http;

class SupplierService {
  static const String _baseUrl = 'http://localhost:3000/suppliers';

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final url = Uri.parse(_baseUrl);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
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
