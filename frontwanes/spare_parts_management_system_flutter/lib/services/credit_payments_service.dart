import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/credit_payment.dart';
import '../config/app_config.dart';

class CreditPaymentsService {
  static final String baseUrl = AppConfig.baseUrl;

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

  Future<CreditPayment> createCreditPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/credit-payments'),
        headers: headers,
        body: jsonEncode(paymentData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final payment = CreditPayment.fromJson(jsonDecode(response.body));

        return payment;
      } else {
        throw Exception('Failed to create credit payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating credit payment: $e');
    }
  }

  Future<List<CreditPayment>> getAllPayments() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-payments'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CreditPayment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch payments: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<List<CreditPayment>> getPaymentsByCreditSale(
    String creditSaleId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-payments/credit-sale/$creditSaleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CreditPayment.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to fetch credit sale payments: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching credit sale payments: $e');
    }
  }

  Future<double> getTotalPaidAmount(String creditSaleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-payments/total-paid/$creditSaleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.parse(data['total'].toString());
      } else {
        throw Exception('Failed to fetch total paid amount: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching total paid amount: $e');
    }
  }
}
