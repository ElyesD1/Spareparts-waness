import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;
  final AuthService _auth;

  ApiClient({this.baseUrl = 'http://localhost:3000', AuthService? auth})
      : _auth = auth ?? AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) async {
    final res = await http.get(_u(path), headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
  }

  Future<dynamic> post(String path, dynamic body) async {
    final res = await http.post(_u(path), headers: await _headers(), body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('POST $path failed: ${res.statusCode} ${res.body}');
  }

  Future<dynamic> put(String path, dynamic body) async {
    final res = await http.put(_u(path), headers: await _headers(), body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('PUT $path failed: ${res.statusCode} ${res.body}');
  }

  Future<void> delete(String path) async {
    final res = await http.delete(_u(path), headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
  }
}





