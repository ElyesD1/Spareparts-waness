import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/operational_expense.dart';
import '../config/app_config.dart';
import 'session_manager.dart';
import 'warehouse_service.dart';
import 'user_service.dart';

class OperationalExpenseService {
  static final String baseUrl = AppConfig.operationalExpensesUrl;

  static Future<List<OperationalExpense>> getOperationalExpenses() async {
    try {
      final user = await SessionManager.getUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        // Debug: Print the first expense raw data
        if (jsonData.isNotEmpty) {
          print(
            '🔄 [OperationalExpenseService] Raw response data for first expense:',
          );
          print('🔄 [OperationalExpenseService] ${jsonData.first}');
        }

        final expenses =
            jsonData.map((json) => OperationalExpense.fromJson(json)).toList();

        // Enhance expenses with missing warehouse names and user names
        final enhancedExpenses = await _enhanceExpensesWithAdditionalData(
          expenses,
        );

        return enhancedExpenses;
      } else {
        throw Exception(
          'Failed to load operational expenses: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading operational expenses: $e');
    }
  }

  // Helper method to enhance expenses with warehouse names and user names
  static Future<List<OperationalExpense>> _enhanceExpensesWithAdditionalData(
    List<OperationalExpense> expenses,
  ) async {
    try {
      final warehouseService = WarehouseService();

      // Fetch warehouse names
      final warehouses = await warehouseService.getWarehouses();
      final warehouseMap = <String, String>{};
      for (final warehouse in warehouses) {
        warehouseMap[warehouse['id']?.toString() ?? ''] =
            warehouse['name'] as String;
      }

      // Fetch user names
      final userMap = <String, String>{};
      try {
        final users = await UserService.getUsers();
        for (final user in users) {
          if (user.id != null) {
            userMap[user.id!] = user.name;
          }
        }
      } catch (e) {
        print('⚠️ [OperationalExpenseService] Could not fetch user names: $e');
      }

      // Create new expense objects with warehouse names and user names
      final enhancedExpenses =
          expenses.map((expense) {
            final warehouseName =
                warehouseMap[expense.warehouseId] ??
                'Unknown Warehouse (ID: ${expense.warehouseId})';
            final userName =
                userMap[expense.createdBy] ??
                'Unknown User (ID: ${expense.createdBy})';

            print(
              '🔄 [OperationalExpenseService] Enhancing expense ${expense.id}:',
            );
            print(
              '🔄 [OperationalExpenseService]   Warehouse ID: ${expense.warehouseId} -> Name: $warehouseName',
            );
            print(
              '🔄 [OperationalExpenseService]   User ID: ${expense.createdBy} -> Name: $userName',
            );

            return OperationalExpense(
              id: expense.id,
              title: expense.title,
              amount: expense.amount,
              type: expense.type,
              warehouseId: expense.warehouseId,
              createdBy: expense.createdBy,
              date: expense.date,
              note: expense.note,
              warehouseName: warehouseName,
              createdByName: userName,
            );
          }).toList();

      return enhancedExpenses;
    } catch (e) {
      print('⚠️ [OperationalExpenseService] Error enhancing expenses: $e');
      // Return original expenses if enhancement fails
      return expenses;
    }
  }

  static Future<OperationalExpense> createOperationalExpense(
    OperationalExpense expense,
  ) async {
    try {
      final user = await SessionManager.getUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return OperationalExpense.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to create operational expense: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error creating operational expense: $e');
    }
  }

  static Future<OperationalExpense> updateOperationalExpense(
    String id,
    OperationalExpense expense,
  ) async {
    try {
      final user = await SessionManager.getUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        return OperationalExpense.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to update operational expense: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error updating operational expense: $e');
    }
  }

  static Future<void> deleteOperationalExpense(String id) async {
    try {
      final user = await SessionManager.getUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete operational expense: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting operational expense: $e');
    }
  }

  static Future<OperationalExpense> getOperationalExpenseById(String id) async {
    try {
      final user = await SessionManager.getUser();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return OperationalExpense.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to load operational expense: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading operational expense: $e');
    }
  }
}
