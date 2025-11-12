import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/purchase.dart';
import '../models/domain/purchase_item.dart';
import 'session_manager.dart';
import 'warehouse_service.dart';
import 'auth_service.dart';
import 'product_stock_service.dart';
import 'stock_movement_service.dart';

class PurchaseService {
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  final String baseUrl = 'http://localhost:3000/purchases';

  Future<List<Purchase>> fetchPurchases() async {
    final token = await _getAuthToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = json.decode(response.body);

      var purchases =
          data.map((json) {
            try {
              final purchase = Purchase.fromJson(json);
              // Derive safe display names
              final supplierName =
                  (json['supplier'] is Map && json['supplier'] != null)
                      ? (json['supplier']['name']?.toString())
                      : null;
              final createdByName =
                  (json['createdBy'] is Map && json['createdBy'] != null)
                      ? (json['createdBy']['name']?.toString())
                      : null;
              // If your backend returns purchase items with warehouses, you can compute a name; else keep null
              final withNames = purchase.copyWith(
                supplierName: supplierName ?? 'Non défini',
                createdByName: createdByName ?? 'Non défini',
              );
              return withNames;
            } catch (e) {
              rethrow;
            }
          }).toList();

      // Enhance with warehouse names (first item's warehouse; 'Multiple' if mixed)
      try {
        final warehouses = await WarehouseService().getWarehouses();
        final warehouseMap = {
          for (final w in warehouses) w['id'] as int: (w['name'] as String),
        };

        final enhanced = await Future.wait(
          purchases.map((p) async {
            try {
              final items = await fetchPurchaseItems(p.id);
              if (items.isEmpty) return p.copyWith(warehouseName: 'Non défini');
              final ids = items.map((i) => i.warehouseId).toSet();
              if (ids.length > 1) return p.copyWith(warehouseName: 'Multiple');
              final wid = ids.first;
              final name = warehouseMap[wid] ?? 'Entrepôt $wid';
              return p.copyWith(warehouseName: name);
            } catch (_) {
              return p.copyWith(warehouseName: 'Non défini');
            }
          }),
        );
        purchases = enhanced;
      } catch (_) {
        // ignore enhancement failures
      }
      return purchases;
    } else {
      throw Exception('Erreur lors du chargement des achats');
    }
  }

  Future<Purchase> fetchPurchaseById(String purchaseId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$purchaseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Purchase.fromJson(data);
    } else {
      throw Exception('Erreur lors du chargement de l\'achat');
    }
  }

  Future<String> createPurchase(Map<String, dynamic> purchaseData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(purchaseData),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur lors de la création de l\'achat');
    }
    final data = json.decode(response.body);
    return (data['_id'] ?? data['id']).toString();
  }

  Future<void> createPurchaseItem(Map<String, dynamic> itemData) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('http://localhost:3000/purchase-item'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(itemData),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur lors de la création de l\'item d\'achat');
    }
  }

  Future<List<PurchaseItem>> fetchPurchaseItems(String purchaseId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('http://localhost:3000/purchase-item/purchase/$purchaseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final List<dynamic> data = json.decode(response.body);
        final items = data.map((e) => PurchaseItem.fromJson(e)).toList();
        return items;
      } catch (e, stack) {
        rethrow;
      }
    } else {
      throw Exception('Erreur lors du chargement des items d\'achat');
    }
  }

  Future<void> updatePurchase(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/purchases/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de la mise à jour de l\'achat');
    }
  }

  Future<void> deletePurchase(String id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/purchases/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de l\'achat');
    }
  }

  Future<void> confirmDelivery(
    String purchaseId,
    String deliveredByUserId,
  ) async {
    try {
      // Step 1: Confirm delivery in the backend
      final url = Uri.parse(
        'http://localhost:3000/purchases/$purchaseId/deliver',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deliveredBy': deliveredByUserId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to confirm delivery');
      }

      // Step 2: Get purchase details and items
      final purchaseItems = await fetchPurchaseItems(purchaseId);

      // Get purchase details for supplier name
      final purchases = await fetchPurchases();
      final purchase = purchases.firstWhere((p) => p.id == purchaseId);
      final supplierName = purchase.supplier?['name'] ?? 'Fournisseur inconnu';

      // Step 3: Add each item to stock and create stock movements
      final productStockService = ProductStockService();
      final stockMovementService = StockMovementService();

      // Prepare items data for batch stock movement creation
      final purchaseItemsData =
          purchaseItems
              .map(
                (item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'product_name': item.product?.name ?? 'Produit',
                },
              )
              .toList();

      // Create stock movements for the delivered purchase
      try {
        print('🔄 [PurchaseService] Creating stock movements...');
        final stockMovementSuccess = await stockMovementService
            .createPurchaseStockMovements(
              purchaseItems: purchaseItemsData,
              warehouseId:
                  purchaseItems
                      .first
                      .warehouseId, // Assuming all items go to same warehouse
              userId: deliveredByUserId,
              supplierName: supplierName,
              purchaseId: purchaseId,
            );

        if (stockMovementSuccess) {
          print(
            '✅ [PurchaseService] Stock movements created successfully for purchase #$purchaseId',
          );
        } else {
          print(
            '❌ [PurchaseService] Failed to create stock movements for purchase #$purchaseId',
          );
        }

        for (final item in purchaseItems) {
          try {
            // Add stock to the product
            await productStockService.addStock(
              item.productId,
              item.warehouseId,
              item.quantity,
            );
          } catch (e) {
            print(
              '❌ [PurchaseService] Error processing item ${item.productId}: $e',
            );
            // Continue with other items even if one fails
          }
        }
      } catch (e) {
        throw Exception('Failed to confirm delivery: $e');
      }
    } catch (e) {
      throw Exception('Erreur lors de la confirmation de la livraison: $e');
    }
  }
}
