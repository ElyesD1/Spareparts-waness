// lib/models/stock_movement.dart
import 'product.dart';
import 'warehouse.dart';
import 'user.dart';

class StockMovement {
  final String id;
  final String productId;
  final String? productName;
  final String? productReference;
  final String? productBrand;
  final String? productCategory;
  final Product? product; // Keep for backward compatibility
  final String? fromWarehouseId;
  final String? fromWarehouseName;
  final Warehouse? fromWarehouse; // Keep for backward compatibility
  final String? toWarehouseId;
  final String? toWarehouseName;
  final Warehouse? toWarehouse; // Keep for backward compatibility
  final String userId;
  final String? userName;
  final String? userRole;
  final User? user; // Keep for backward compatibility
  final int quantity;
  final String movementType;
  final String? sourceType;
  final String? sourceId;
  final DateTime createdAt;
  final String? note;

  StockMovement({
    required this.id,
    required this.productId,
    this.productName,
    this.productReference,
    this.productBrand,
    this.productCategory,
    this.product,
    this.fromWarehouseId,
    this.fromWarehouseName,
    this.fromWarehouse,
    this.toWarehouseId,
    this.toWarehouseName,
    this.toWarehouse,
    required this.userId,
    this.userName,
    this.userRole,
    this.user,
    required this.quantity,
    required this.movementType,
    this.sourceType,
    this.sourceId,
    required this.createdAt,
    this.note,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse product data (for backward compatibility)
    Product? parseProduct(dynamic productData) {
      if (productData == null) return null;
      if (productData is Map<String, dynamic>) {
        try {
          return Product.fromJson(productData);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to safely parse warehouse data (for backward compatibility)
    Warehouse? parseWarehouse(dynamic warehouseData) {
      if (warehouseData == null) return null;
      if (warehouseData is Map<String, dynamic>) {
        try {
          return Warehouse.fromJson(warehouseData);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to safely parse user data (for backward compatibility)
    User? parseUser(dynamic userData) {
      if (userData == null) return null;
      if (userData is Map<String, dynamic>) {
        try {
          return User.fromJson(userData);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return StockMovement(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'],
      productReference: json['product_reference'],
      productBrand: json['product_brand'],
      productCategory: json['product_category'],
      product: parseProduct(
        json['product_id'] is Map ? json['product_id'] : json['product'],
      ), // Backward compatibility
      fromWarehouseId: json['from_warehouse_id']?.toString(),
      fromWarehouseName: json['from_warehouse_name'],
      fromWarehouse: parseWarehouse(
        json['fromWarehouse'] ?? json['from_warehouse'],
      ), // Backward compatibility
      toWarehouseId: json['to_warehouse_id']?.toString(),
      toWarehouseName: json['to_warehouse_name'],
      toWarehouse: parseWarehouse(
        json['toWarehouse'] ?? json['to_warehouse'],
      ), // Backward compatibility
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'],
      userRole: json['user_role'],
      user: parseUser(
        json['user_id'] is Map ? json['user_id'] : json['user'],
      ), // Backward compatibility
      quantity: json['quantity'] ?? 0,
      movementType: (json['movement_type'] ?? '').toString().toLowerCase(),
      sourceType:
          (json['source_type'] ?? json['sourceType'] ?? '')
              .toString()
              .toLowerCase(),
      sourceId: json['source_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
      note: json['note'],
    );
  }

  // Getter methods for backward compatibility
  String get displayProductName =>
      productName ?? product?.name ?? 'Produit inconnu';
  String get displayFromWarehouseName =>
      fromWarehouseName ?? fromWarehouse?.name ?? 'Entrepôt inconnu';
  String get displayToWarehouseName =>
      toWarehouseName ?? toWarehouse?.name ?? 'Entrepôt inconnu';
  String get displayUserName => userName ?? user?.name ?? 'Utilisateur inconnu';
  String get displayUserRole => userRole ?? user?.role ?? '';
}
