import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/domain/stock_movement.dart';
import 'session_manager.dart';

class StockMovementService {
  final String baseUrl = 'http://localhost:3000/movements';

  // Plain JSON list for ViewModels that expect Map<String, dynamic>
  Future<List<Map<String, dynamic>>> fetchMovements() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  Future<List<StockMovement>> fetchStockMovements() async {
    try {
      print(
        '🔄 [StockMovementService] Fetching stock movements from: $baseUrl',
      );

      final response = await http.get(Uri.parse(baseUrl));

      print(
        '🔄 [StockMovementService] Response status: ${response.statusCode}',
      );
      print('🔄 [StockMovementService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final List data = json.decode(response.body);
          print('🔄 [StockMovementService] Parsed ${data.length} movements');

          final List<StockMovement> movements = [];
          for (int i = 0; i < data.length; i++) {
            try {
              final movement = StockMovement.fromJson(data[i]);
              movements.add(movement);
            } catch (e) {
              print('❌ [StockMovementService] Error parsing movement $i: $e');
              print('❌ [StockMovementService] Movement data: ${data[i]}');
            }
          }

          print(
            '✅ [StockMovementService] Successfully parsed ${movements.length} movements',
          );
          return movements;
        } catch (e) {
          throw Exception('Erreur de parsing JSON: $e');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des mouvements de stock: $e');
    }
  }

  Future<bool> createStockMovement(Map<String, dynamic> data) async {
    // Get current user for authentication
    final user = await SessionManager.getUser();
    final headers = {'Content-Type': 'application/json'};
    if (user != null && user['access_token'] != null) {
      headers['Authorization'] = 'Bearer ${user['access_token']}';
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ [StockMovementService] Stock movement created successfully');
        return true;
      } else {
        print(
          '❌ [StockMovementService] Failed to create stock movement: ${response.statusCode} - ${response.body}',
        );

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            print('❌ [StockMovementService] Error details: $errorData');
          }
        } catch (e) {
          print('❌ [StockMovementService] Could not parse error response: $e');
        }

        return false;
      }
    } catch (e) {
      print('❌ [StockMovementService] Exception creating stock movement: $e');
      return false;
    }
  }

  // Utility method to create stock movement for a sale
  Future<bool> createSaleStockMovement({
    required String productId,
    required int quantity,
    required String warehouseId,
    required String userId,
    required String customerName,
    required String saleId,
    String? note,
  }) async {
    final movementData = {
      'product_id': productId,
      'quantity': quantity,
      'from_warehouse_id': warehouseId, // Sale reduces stock from warehouse
      'to_warehouse_id': null,
      'user_id': userId,
      'movement_type':
          'sale', // Changed from 'vente' to 'sale' for backend compatibility
      'source_type': 'sale',
      'source_id': saleId, // Add source_id for the sale
      'note':
          note ??
          'Vente: Client $customerName - Produit: Produit - Quantité: $quantity - Prix: N/A',
    };

    print(
      '🔄 [StockMovementService] Creating sale stock movement: $movementData',
    );
    return await createStockMovement(movementData);
  }

  // Utility method to create stock movement for a delivered purchase
  Future<bool> createPurchaseStockMovement({
    required String productId,
    required int quantity,
    required String warehouseId,
    required String userId,
    required String supplierName,
    required String purchaseId,
    String? note,
  }) async {
    final movementData = {
      'product_id': productId,
      'quantity': quantity,
      'from_warehouse_id': null,
      'to_warehouse_id': warehouseId, // Purchase adds stock to warehouse
      'user_id': userId,
      'movement_type':
          'purchase', // Changed from 'achat' to 'purchase' for backend compatibility
      'source_type': 'purchase',
      'source_id': purchaseId, // Add source_id for the purchase
      'note':
          note ??
          'Achat: Fournisseur $supplierName - Produit: Produit - Quantité: $quantity - Prix: N/A',
    };

    print(
      '🔄 [StockMovementService] Creating purchase stock movement: $movementData',
    );
    return await createStockMovement(movementData);
  }

  // Check if stock movements already exist for a purchase return to prevent duplication
  Future<bool> hasStockMovementsForPurchaseReturn(String returnId) async {
    try {
      final movements = await fetchStockMovements();
      return movements.any(
        (movement) =>
            movement.sourceType == 'purchase_return' &&
            movement.sourceId == returnId,
      );
    } catch (e) {
      print(
        '❌ [StockMovementService] Error checking existing stock movements: $e',
      );
      return false;
    }
  }

  // Utility method to create stock movement for a purchase return
  Future<bool> createPurchaseReturnStockMovement({
    required String productId,
    required int quantity,
    required String warehouseId,
    required String userId,
    required String supplierName,
    required String purchaseId,
    required String returnId,
    String? note,
  }) async {
    // Check if stock movements already exist for this return to prevent duplication
    final hasExistingMovements = await hasStockMovementsForPurchaseReturn(
      returnId,
    );
    if (hasExistingMovements) {
      print(
        '⚠️ [StockMovementService] Stock movements already exist for purchase return #$returnId, skipping creation to prevent duplication',
      );
      return true; // Return true since movements already exist
    }

    final movementData = {
      'product_id': productId,
      'quantity': quantity,
      'from_warehouse_id': warehouseId, // Return reduces stock from warehouse
      'to_warehouse_id': null,
      'user_id': userId,
      'movement_type': 'return', // État "Retour"
      'source_type': 'purchase_return',
      'source_id': returnId, // Add source_id for the purchase return
      'note':
          note ??
          'Retour: Fournisseur $supplierName - Produit: Produit - Quantité: $quantity - Prix: N/A',
    };

    print(
      '🔄 [StockMovementService] Creating purchase return stock movement: $movementData',
    );
    return await createStockMovement(movementData);
  }

  // Batch method to create multiple stock movements for a sale
  Future<bool> createSaleStockMovements({
    required List<Map<String, dynamic>> saleItems,
    required String warehouseId,
    required String userId,
    required String customerName,
    required String saleId,
  }) async {
    try {
      for (final item in saleItems) {
        final success = await createSaleStockMovement(
          productId: item['product_id'],
          quantity: item['quantity'],
          warehouseId: warehouseId,
          userId: userId,
          customerName: customerName,
          saleId: saleId,
          note:
              'Vente: Client $customerName - Produit: ${item['product_name'] ?? 'Produit'} - Quantité: ${item['quantity']} - Prix: ${item['unit_price'] ?? 'N/A'}',
        );

        if (!success) {
          print(
            '❌ [StockMovementService] Failed to create stock movement for product ${item['product_id']}',
          );
          return false;
        }
      }
      print(
        '✅ [StockMovementService] Successfully created ${saleItems.length} stock movements for sale #$saleId',
      );
      return true;
    } catch (e) {
      print('❌ [StockMovementService] Error creating sale stock movements: $e');
      return false;
    }
  }

  // Batch method to create multiple stock movements for a delivered purchase
  Future<bool> createPurchaseStockMovements({
    required List<Map<String, dynamic>> purchaseItems,
    required String warehouseId,
    required String userId,
    required String supplierName,
    required String purchaseId,
  }) async {
    try {
      for (final item in purchaseItems) {
        final success = await createPurchaseStockMovement(
          productId: item['product_id'],
          quantity: item['quantity'],
          warehouseId: warehouseId,
          userId: userId,
          supplierName: supplierName,
          purchaseId: purchaseId,
          note:
              'Achat: Fournisseur $supplierName - Produit: ${item['product_name'] ?? 'Produit'} - Quantité: ${item['quantity']} - Prix: ${item['unit_price'] ?? 'N/A'}',
        );

        if (!success) {
          print(
            '❌ [StockMovementService] Failed to create stock movement for product ${item['product_id']}',
          );
          return false;
        }
      }
      print(
        '✅ [StockMovementService] Successfully created ${purchaseItems.length} stock movements for purchase #$purchaseId',
      );
      return true;
    } catch (e) {
      print(
        '❌ [StockMovementService] Error creating purchase stock movements: $e',
      );
      return false;
    }
  }
}
