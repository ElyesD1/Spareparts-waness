import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/domain/credit_sale.dart';
import '../config/app_config.dart';
import 'product_stock_service.dart';
import 'stock_movement_service.dart';
import 'session_manager.dart';
import 'customers_service.dart';

class CreditSalesService {
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

  Future<CreditSale> createCreditSale(
    Map<String, dynamic> creditSaleData,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/credit-sales'),
        headers: headers,
        body: jsonEncode(creditSaleData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final creditSale = CreditSale.fromJson(jsonDecode(response.body));

        // Now decrease product stock for each item in the credit sale
        await _decreaseProductStock(creditSale, creditSaleData);

        // Create stock movements for the credit sale
        await _createStockMovements(creditSale, creditSaleData);

        return creditSale;
      } else {
        throw Exception('Failed to create credit sale: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating credit sale: $e');
    }
  }

  Future<List<CreditSale>> getAllCreditSales() async {
    try {
      final headers = await _getHeaders();
      // Use with-calculations endpoint to get total_paid and remaining_amount
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/with-calculations'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CreditSale.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load credit sales: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading credit sales: $e');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/statistics'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading statistics: $e');
    }
  }

  Future<int> getProfitByYear(int year) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/profit/$year'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['profit'] as num).toInt();
      } else {
        throw Exception('Failed to load profit: ${response.body}');
      }
    } catch (e) {
      print('Error loading credit sales profit: $e');
      return 0;
    }
  }

  Future<void> checkAndUpdateStatuses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/check-statuses'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to check statuses: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking statuses: $e');
    }
  }

  Future<CreditSale> updateStatus(String creditSaleId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/credit-sales/$creditSaleId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        return CreditSale.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCreditSaleItems(
    String creditSaleId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sale-items/credit-sale/$creditSaleId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map<Map<String, dynamic>>(
              (item) => {
                'productId': item['product_id'],
                'quantity': item['quantity'],
                'unitPrice': item['unit_price'],
                'productName': item['product']?['name'] ?? 'Unknown Product',
              },
            )
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Méthode pour vérifier et mettre à jour automatiquement le statut
  Future<void> checkAndUpdateCreditSaleStatus(String creditSaleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/$creditSaleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final creditSaleData = jsonDecode(response.body);
        // Robust computation of remaining amount
        double? remainingAmount =
            (creditSaleData['remaining_amount'] is num)
                ? (creditSaleData['remaining_amount'] as num).toDouble()
                : null;
        final double creditAmount =
            (creditSaleData['credit_amount'] is num)
                ? (creditSaleData['credit_amount'] as num).toDouble()
                : 0.0;
        final List<dynamic> payments =
            (creditSaleData['payments'] is List)
                ? (creditSaleData['payments'] as List)
                : const [];
        final double totalPaid = payments.fold<double>(0.0, (sum, p) {
          final val =
              p is Map && p['amount'] is num
                  ? (p['amount'] as num).toDouble()
                  : 0.0;
          return sum + val;
        });
        if (remainingAmount == null) {
          remainingAmount = (creditAmount - totalPaid);
        }

        // Removed stray debug using undefined variable

        // Set completed ONLY when remaining is 0 or less
        if (remainingAmount <= 0) {
          await updateStatus(creditSaleId, 'completed');
        }
        // If some payment made but not fully paid → active
        else if (totalPaid > 0 && remainingAmount > 0) {
          await updateStatus(creditSaleId, 'active');
        }
      }
    } catch (e) {
      throw Exception('Error checking credit sale status: $e');
    }
  }

  Future<CreditSale> getCreditSaleById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return CreditSale.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch credit sale: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching credit sale: $e');
    }
  }

  Future<List<CreditSale>> getCreditSalesByCustomer(String customerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/credit-sales/customer/$customerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CreditSale.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to fetch customer credit sales: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching customer credit sales: $e');
    }
  }

  Future<CreditSale> updateCreditSaleStatus(String id, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/credit-sales/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return CreditSale.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to update credit sale status: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error updating credit sale status: $e');
    }
  }

  Future<void> deleteCreditSale(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/credit-sales/$id'),
        headers: headers,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete credit sale: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting credit sale: $e');
    }
  }

  // Helper method to decrease product stock for credit sale items
  Future<void> _decreaseProductStock(
    CreditSale creditSale,
    Map<String, dynamic> creditSaleData,
  ) async {
    try {
      final productStockService = ProductStockService();
      final items = creditSaleData['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return;
      }

      final warehouseId = creditSaleData['warehouse_id']?.toString();
      if (warehouseId == null) {
        return;
      }

      for (final item in items) {
        final productId = item['product_id']?.toString();
        final quantity = item['quantity'] as int?;

        if (productId == null || quantity == null) {
          continue;
        }

        try {
          // Get current stock level
          final currentStock = await productStockService.getCurrentStock(
            productId,
            warehouseId,
          );

          if (currentStock >= quantity) {
            // Calculate new stock level
            final newStock = currentStock - quantity;

            // Update stock
            await productStockService.updateStock(
              productId,
              warehouseId,
              newStock,
            );
          } else {
            // You might want to throw an exception here or handle this case differently
          }
        } catch (e) {
          // Continue with other products even if one fails
        }
      }
    } catch (e) {}
  }

  // Helper method to create stock movements for credit sale items
  Future<void> _createStockMovements(
    CreditSale creditSale,
    Map<String, dynamic> creditSaleData,
  ) async {
    try {
      final stockMovementService = StockMovementService();
      final items = creditSaleData['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return;
      }

      final warehouseId = creditSaleData['warehouse_id']?.toString();
      final customerId = creditSaleData['customer_id']?.toString();

      if (warehouseId == null || customerId == null) {
        return;
      }

      // Get user ID from session manager
      final user = await SessionManager.getUser();
      final userId = user?['id']?.toString();

      if (userId == null) {
        return;
      }

      // Get customer name from customer service
      String customerName = 'Client ID: $customerId';
      try {
        final customers = await CustomersService.getCustomers();
        final customer = customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => throw StateError('Customer not found'),
        );
        customerName = customer.name;
      } catch (e) {}

      for (final item in items) {
        final productId = item['product_id']?.toString();
        final quantity = item['quantity'] as int?;

        if (productId == null || quantity == null) {
          continue;
        }

        try {
          // Create stock movement for credit sale (using sale stock movement method)
          final success = await stockMovementService.createSaleStockMovement(
            productId: productId,
            quantity: quantity,
            warehouseId: warehouseId,
            userId: userId,
            customerName: customerName,
            saleId: creditSale.id!,
            note:
                'Vente à crédit - Client ID: $customerId (Vente #${creditSale.id})',
          );

          if (success) {
          } else {}
        } catch (e) {
          // Continue with other items even if one fails
        }
      }
    } catch (e) {}
  }
}
