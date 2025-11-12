import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/purchase_return.dart';
import 'stock_movement_service.dart';
import 'product_stock_service.dart';

class PurchaseReturnService {
  static const String baseUrl = 'http://localhost:3000/purchase-returns';

  static Future<List<PurchaseReturn>> getPurchaseReturns({
    String? status,
    int? supplierId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    String url = baseUrl;
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (supplierId != null) query['supplier_id'] = supplierId.toString();
    if (query.isNotEmpty) url += '?${Uri(queryParameters: query).query}';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load purchase returns: ${res.statusCode} ${res.body}',
      );
    }

    try {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) {
        try {
          return PurchaseReturn.fromJson(e as Map<String, dynamic>);
        } catch (parseError) {
          rethrow;
        }
      }).toList();
    } catch (parseError) {
      rethrow;
    }
  }

  static Future<PurchaseReturn> getPurchaseReturn(String id) async {
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
      throw Exception(
        'Failed to load purchase return: ${res.statusCode} ${res.body}',
      );
    }
    return PurchaseReturn.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static Future<PurchaseReturn> createPurchaseReturn(
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception(
          'Failed to create purchase return: ${res.statusCode} ${res.body}',
        );
      }

      try {
        final purchaseReturn = PurchaseReturn.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );

        return purchaseReturn;
      } catch (parseError) {
        print('Error parsing created purchase return: $parseError');
        rethrow;
      }
    } catch (error) {
      print('Error creating purchase return: $error');

      rethrow;
    }
  }

  static Future<PurchaseReturn> updatePurchaseReturn(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    final res = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update purchase return: ${res.statusCode} ${res.body}',
      );
    }
    return PurchaseReturn.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static Future<bool> deletePurchaseReturn(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    final res = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  static Future<PurchaseReturn> approve(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    // First, get the current purchase return to check its status
    final currentReturn = await getPurchaseReturn(id);

    // Validate that the return can be approved
    if (currentReturn.status != ReturnStatus.PENDING) {
      throw Exception(
        'Purchase return can only be approved when status is PENDING. Current status: ${currentReturn.status.displayName}',
      );
    }

    // Rely on backend to handle all approval side-effects (credits, etc.)
    final res = await http.put(
      Uri.parse('$baseUrl/$id/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to approve purchase return: ${res.statusCode} ${res.body}',
      );
    }

    final approvedReturn = PurchaseReturn.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );

    return approvedReturn;
  }

  // Helper method to check if a purchase return can be completed
  static bool canComplete(PurchaseReturn purchaseReturn) {
    return purchaseReturn.status == ReturnStatus.APPROVED;
  }

  // Helper method to check if a purchase return can be approved
  static bool canApprove(PurchaseReturn purchaseReturn) {
    return purchaseReturn.status == ReturnStatus.PENDING;
  }

  // Helper method to check if a purchase return can be rejected
  static bool canReject(PurchaseReturn purchaseReturn) {
    return purchaseReturn.status == ReturnStatus.PENDING;
  }

  static Future<PurchaseReturn> reject(String id, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    // First, get the current purchase return to check its status
    final currentReturn = await getPurchaseReturn(id);

    // Validate that the return can be rejected
    if (currentReturn.status != ReturnStatus.PENDING) {
      throw Exception(
        'Purchase return can only be rejected when status is PENDING. Current status: ${currentReturn.status.displayName}',
      );
    }

    final res = await http.put(
      Uri.parse('$baseUrl/$id/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to reject purchase return: ${res.statusCode} ${res.body}',
      );
    }

    final rejectedReturn = PurchaseReturn.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );

    return rejectedReturn;
  }

  static Future<PurchaseReturn> complete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception('No access token found');

    // First, get the current purchase return to check its status
    final currentReturn = await getPurchaseReturn(id);

    // Validate that the return can be completed
    if (currentReturn.status != ReturnStatus.APPROVED) {
      throw Exception(
        'Purchase return can only be completed when status is APPROVED. Current status: ${currentReturn.status.displayName}',
      );
    }

    final res = await http.put(
      Uri.parse('$baseUrl/$id/complete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to complete purchase return: ${res.statusCode} ${res.body}',
      );
    }

    final purchaseReturn = PurchaseReturn.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );

    // Create stock movements and reduce stock for the completed purchase return
    try {
      final stockMovementService = StockMovementService();
      final productStockService = ProductStockService();

      // Get purchase return details for stock movement creation
      final supplierName = purchaseReturn.supplierName ?? 'Fournisseur inconnu';
      final returnId = purchaseReturn.id ?? '';
      final warehouseId = purchaseReturn.warehouseId;
      final userId = purchaseReturn.createdBy;

      // Process each item in the purchase return
      if (purchaseReturn.items != null && purchaseReturn.items!.isNotEmpty) {
        for (final item in purchaseReturn.items!) {
          // Create stock movement for the return
          final success = await stockMovementService
              .createPurchaseReturnStockMovement(
                productId: item.productId,
                quantity: item.quantity,
                warehouseId: warehouseId,
                userId: userId,
                supplierName: supplierName,
                purchaseId: purchaseReturn.supplierId,
                returnId: returnId,
                note:
                    'Retour Achat - Fournisseur: $supplierName (Retour #$returnId) - ${item.productName ?? 'Produit'}',
              );

          if (success) {
          } else {}

          // Reduce product stock for completed purchase returns
          final currentStock = await productStockService.getCurrentStock(
            item.productId,
            warehouseId,
          );

          if (currentStock > 0) {
            final newStock = currentStock - item.quantity;
            if (newStock >= 0) {
              await productStockService.updateStock(
                item.productId,
                warehouseId,
                newStock,
              );
            } else {}
          } else {}
        }
      } else {}
    } catch (e) {
      // Don't fail the completion if stock operations fail, but log the error
    }

    return purchaseReturn;
  }
}
