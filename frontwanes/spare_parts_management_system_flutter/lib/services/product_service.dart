import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'http_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/domain/product.dart';

class ProductService {
  final ApiClient _api = ApiClient();
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static const String _baseUrl = 'http://localhost:3000/products';

  Future<List<Product>> getProducts() async {
    final data = await _api.get('/products');
    final List<dynamic> list = data as List<dynamic>;
    return list.map((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final data = await _api.get('/products/barcode/$barcode');
      return Product.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Product> addProduct(Product product) async {
    final data = await _api.post('/products', product.toJson());
    return Product.fromJson(data);
  }

  Future<Product> updateProduct(String id, Product product) async {
    final data = await _api.put('/products/$id', product.toJson());
    return Product.fromJson(data);
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
  }

  Future<Product> addProductWithImage(Product product, XFile? image) async {
    final token = await _getAuthToken();
    final url = Uri.parse('http://localhost:3000/products/with-image');
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['product'] = jsonEncode(product.toJson());
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final filename = image.name;
        request.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: filename),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add product with image');
    }
  }

  Future<Product> updateProductWithImage(
    String id,
    Product product,
    XFile? image,
  ) async {
    final token = await _getAuthToken();
    final url = Uri.parse('http://localhost:3000/products/$id/with-image');

    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['product'] = jsonEncode(
      product.toJson(),
    ); // Always include this!
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final filename = image.name;
        request.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: filename),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update product with image: ${response.body}');
    }
  }

  // Check stock availability for a product in a specific warehouse
  Future<Map<String, dynamic>> checkStockAvailability(
    String productId,
    String warehouseId,
    int quantity,
  ) async {
    final data = await _api.get(
      '/product-stocks/check-availability/$productId/$warehouseId/$quantity',
    );
    return data as Map<String, dynamic>;
  }

  // Get current stock level for a product in a specific warehouse
  Future<int> getStockLevel(String productId, String warehouseId) async {
    final data = await _api.get(
      '/product-stocks/stock-level/$productId/$warehouseId',
    );
    return (data['stockLevel'] ?? 0) as int;
  }

  // Get all stock entries (product + qty) for a specific warehouse
  Future<List<Map<String, dynamic>>> getProductsByWarehouse(
    String warehouseId,
  ) async {
    final data = await _api.get('/product-stocks/by-warehouse/$warehouseId');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
