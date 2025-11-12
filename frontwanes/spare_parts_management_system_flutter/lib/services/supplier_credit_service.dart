import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/supplier_credit.dart';
import '../models/domain/supplier_credit_usage.dart';

class SupplierCreditService {
  static const String baseUrl = 'http://localhost:3000/supplier-credits';

  static Future<List<SupplierCredit>> getAvailableCredits(
    String supplierId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');
    final res = await http.get(
      Uri.parse('$baseUrl/available/$supplierId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load credits: ${res.statusCode} ${res.body}');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => SupplierCredit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<double> getTotalAvailableCredit(String supplierId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/total-available/$supplierId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Credit API Response Status: ${res.statusCode}');
      print('Credit API Response Body: ${res.body}');

      if (res.statusCode != 200) {
        throw Exception(
          'Failed to load total credit: ${res.statusCode} ${res.body}',
        );
      }

      // Handle different response formats
      final decoded = jsonDecode(res.body);
      double totalAvailable = 0.0;

      if (decoded is Map<String, dynamic>) {
        // JSON object format: {"total_available": 60.00}
        totalAvailable = (decoded['total_available'] as num).toDouble();
      } else if (decoded is num) {
        // Direct number format: 60.00
        totalAvailable = decoded.toDouble();
      } else {
        throw Exception('Unexpected response format: $decoded');
      }

      print(
        'Total Available Credit for supplier $supplierId: \$${totalAvailable.toStringAsFixed(2)}',
      );

      return totalAvailable;
    } catch (e) {
      print('Error in getTotalAvailableCredit: $e');
      rethrow;
    }
  }

  static Future<bool> autoApplyCreditsToPurchase(String purchaseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');
    final res = await http.post(
      Uri.parse('$baseUrl/auto-apply/$purchaseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return res.statusCode == 200;
  }

  static Future<bool> applyCreditsToPurchase(
    String purchaseId,
    String supplierId,
    double amount,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');
    final res = await http.post(
      Uri.parse('$baseUrl/apply/$purchaseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'supplier_id': supplierId, 'amount': amount}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> createManualCredit(
    String supplierId,
    double amount, {
    String? notes,
    DateTime? expiryDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');
    final res = await http.post(
      Uri.parse('$baseUrl/manual'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'supplier_id': supplierId,
        'amount': amount,
        if (notes != null) 'notes': notes,
        if (expiryDate != null)
          'expiry_date': expiryDate.toIso8601String().split('T')[0],
      }),
    );
    return res.statusCode == 201 || res.statusCode == 200;
  }

  static Future<bool> updateCreditStatus(String creditId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');
    final res = await http.put(
      Uri.parse('$baseUrl/$creditId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return res.statusCode == 200;
  }

  static Future<List<SupplierCredit>> getAllCredits({
    String? supplierId,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    String url = baseUrl;
    final query = <String, String>{};
    if (supplierId != null) query['supplier_id'] = supplierId.toString();
    if (status != null) query['status'] = status;
    if (query.isNotEmpty) url += '?${Uri(queryParameters: query).query}';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load credits: ${res.statusCode} ${res.body}');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => SupplierCredit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SupplierCredit> getCreditById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    final res = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load credit: ${res.statusCode} ${res.body}');
    }
    return SupplierCredit.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static Future<List<SupplierCreditUsage>> getCreditUsageHistory(
    String creditId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    final res = await http.get(
      Uri.parse('$baseUrl/$creditId/usage-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load credit usage history: ${res.statusCode} ${res.body}',
      );
    }
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => SupplierCreditUsage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> checkAndUpdateExpiredCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    final res = await http.post(
      Uri.parse('$baseUrl/check-expired'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return res.statusCode == 200;
  }

  // Method to manually update remaining amount of a credit (for fixing data issues)
  static Future<bool> updateCreditRemainingAmount(
    String creditId,
    double remainingAmount,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/$creditId/remaining-amount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'remaining_amount': remainingAmount}),
      );

      print(
        'Update remaining amount response: ${res.statusCode} - ${res.body}',
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error updating remaining amount: $e');
      return false;
    }
  }

  // Method to create a test credit for debugging
  static Future<bool> createTestCredit(String supplierId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/manual'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'supplier_id': supplierId,
          'credit_amount': amount,
          'remaining_amount': amount, // Ensure remaining amount is set
          'notes': 'Test credit for debugging',
          'expiry_date':
              DateTime.now()
                  .add(const Duration(days: 365))
                  .toIso8601String()
                  .split('T')[0],
        }),
      );

      print('Create test credit response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Error creating test credit: $e');
      return false;
    }
  }

  // Method to directly fix database credits (for emergency fixes)
  static Future<bool> fixDatabaseCredits(String supplierId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    try {
      // This endpoint should update all credits for a supplier where remaining_amount = 0
      final res = await http.post(
        Uri.parse('$baseUrl/fix-credits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'supplier_id': supplierId}),
      );

      print('Fix database credits response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('Error fixing database credits: $e');
      return false;
    }
  }
}
