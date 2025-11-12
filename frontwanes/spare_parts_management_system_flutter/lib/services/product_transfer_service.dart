import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/product_transfer.dart';
import 'session_manager.dart';

class ProductTransferService {
  static const String baseUrl = 'http://localhost:3000/product-transfers';

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

  /// Get all transfers (admin) or user-specific transfers (based on role)
  Future<List<ProductTransfer>> getTransfers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductTransfer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transfers: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching transfers: $e');
    }
  }

  /// Get transfers by warehouse (for managers)
  Future<List<ProductTransfer>> getTransfersByWarehouse(
    String warehouseId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl?warehouse_id=$warehouseId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductTransfer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load warehouse transfers: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching warehouse transfers: $e');
    }
  }

  /// Get user's transfer requests
  Future<List<ProductTransfer>> getUserTransfers(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductTransfer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user transfers: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user transfers: $e');
    }
  }

  /// Create new transfer request
  Future<ProductTransfer> createTransfer(
    Map<String, dynamic> transferData,
  ) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not authenticated');

      // Add requesting user info
      transferData['requested_by'] = user['id'];

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(transferData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductTransfer.fromJson(data);
      } else {
        throw Exception('Failed to create transfer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating transfer: $e');
    }
  }

  /// Approve transfer (manager/admin only)
  Future<ProductTransfer> approveTransfer(
    String transferId, {
    String? notes,
  }) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not authenticated');

      final requestData = {
        'approved_by': user['id'],
        if (notes != null) 'notes': notes,
      };

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$transferId/approve'),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductTransfer.fromJson(data);
      } else {
        throw Exception('Failed to approve transfer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error approving transfer: $e');
    }
  }

  /// Reject transfer
  Future<ProductTransfer> rejectTransfer(
    String transferId,
    String reason,
  ) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not authenticated');

      final requestData = {'approved_by': user['id'], 'reason': reason};

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$transferId/reject'),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductTransfer.fromJson(data);
      } else {
        throw Exception('Failed to reject transfer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error rejecting transfer: $e');
    }
  }

  /// Process transfer (execute the actual stock movement)
  Future<ProductTransfer> processTransfer(String transferId) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not authenticated');

      final requestData = {'processed_by': user['id']};

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$transferId/process'),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductTransfer.fromJson(data);
      } else {
        throw Exception('Failed to process transfer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing transfer: $e');
    }
  }

  /// Cancel transfer
  Future<ProductTransfer> cancelTransfer(
    String transferId,
    String reason,
  ) async {
    try {
      final user = await SessionManager.getUser();
      if (user == null) throw Exception('User not authenticated');

      final requestData = {'user_id': user['id']};

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$transferId/cancel'),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProductTransfer.fromJson(data);
      } else {
        throw Exception('Failed to cancel transfer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error cancelling transfer: $e');
    }
  }

  /// Check if user can perform action based on role and warehouse
  static bool canCreateTransfer(
    String userRole,
    String? userWarehouseId,
    String fromWarehouseId,
  ) {
    switch (userRole) {
      case 'admin':
        return true; // Admin can transfer from any warehouse
      case 'manager':
        return userWarehouseId ==
            fromWarehouseId; // Manager can only transfer from their warehouse
      case 'cashier':
        return userWarehouseId ==
            fromWarehouseId; // Cashier can only request from their warehouse
      default:
        return false;
    }
  }

  static bool canApproveTransfer(
    String userRole,
    String? userWarehouseId,
    String toWarehouseId,
  ) {
    switch (userRole) {
      case 'admin':
        return true; // Admin can approve any transfer
      case 'manager':
        return userWarehouseId ==
            toWarehouseId; // Manager can approve transfers to their warehouse
      default:
        return false; // Cashiers cannot approve
    }
  }

  static bool canProcessTransfer(String userRole) {
    return userRole == 'admin' || userRole == 'manager';
  }

  static bool canViewAllTransfers(String userRole) {
    return userRole == 'admin';
  }
}
