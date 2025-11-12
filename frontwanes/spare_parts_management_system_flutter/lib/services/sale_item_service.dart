import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/sale_item.dart';
import 'session_manager.dart';

class SaleItemService {
  static const String _baseUrl = 'http://localhost:3000/sale-item';

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    // Use the new backend route: /sale-item/sale/{saleId}
    final url = Uri.parse('$_baseUrl/sale/$saleId');
   
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
 
    final response = await http.get(url, headers: headers);
   
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body);
      
      final items = data.map((json) => SaleItem.fromJson(json)).toList();
      return items;
    } else {
      throw Exception('Failed to load sale items');
    }
  }

  Future<SaleItem> addSaleItem(SaleItem saleItem) async {
    // Use the correct endpoint based on the backend controller
    final url = Uri.parse(_baseUrl);
    final jsonData = saleItem.toJson();
  

    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(jsonData),
    );

  

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SaleItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add sale item: ${response.statusCode} - ${response.body}');
    }
  }

  Future<SaleItem> updateSaleItem(String id, SaleItem saleItem) async {
    final url = Uri.parse('$_baseUrl/$id');
    final jsonData = saleItem.toJson();
   

    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(jsonData),
    );

  
    if (response.statusCode == 200) {
      return SaleItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update sale item: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteSaleItem(String id) async {
    final url = Uri.parse('$_baseUrl/$id');
  

    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.delete(url, headers: headers);
   

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete sale item: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<SaleItem>> getAllSaleItems() async {
    final url = Uri.parse(_baseUrl);
    

    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
  
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final items = <SaleItem>[];
      
      for (int i = 0; i < data.length; i++) {
        try {
          final item = SaleItem.fromJson(data[i]);
          items.add(item);
        } catch (e) {
        }
      }
      
      return items;
    } else {
      throw Exception('Failed to load all sale items: ${response.statusCode} - ${response.body}');
    }
  }
  Future<SaleItem?> getSaleItemById(String id) async {
    final url = Uri.parse('$_baseUrl/$id');
    
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      return SaleItem.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Item not found
    } else {
      throw Exception('Failed to load sale item: ${response.statusCode} - ${response.body}');
    }
  }
  
} 
