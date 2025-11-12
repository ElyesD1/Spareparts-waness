import 'product.dart';
// If you have a Warehouse model, import it here. Otherwise, use Map<String, dynamic> for warehouse for now.

class ProductStock {
  final String? id;
  final String productId;
  final String warehouseId;
  final int quantity;
  final Product? product;
  final Map<String, dynamic>?
  warehouse; // Replace with Warehouse? if you have a Warehouse model

  ProductStock({
    this.id,
    required this.productId,
    required this.warehouseId,
    required this.quantity,
    this.product,
    this.warehouse,
  });

  factory ProductStock.fromJson(Map<String, dynamic> json) {
    // Handle product data - can be populated object or just ID
    final productData =
        json['product_id'] is Map ? json['product_id'] : json['product'];
    final productId =
        productData is Map
            ? (productData['_id']?.toString() ??
                productData['id']?.toString() ??
                '')
            : (json['product_id']?.toString() ?? '');

    // Handle warehouse data - can be populated object or just ID
    final warehouseData =
        json['warehouse_id'] is Map ? json['warehouse_id'] : json['warehouse'];
    final warehouseId =
        warehouseData is Map
            ? (warehouseData['_id']?.toString() ??
                warehouseData['id']?.toString() ??
                '')
            : (json['warehouse_id']?.toString() ?? '');

    return ProductStock(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      productId: productId,
      warehouseId: warehouseId,
      quantity: json['quantity'] ?? 0,
      product:
          productData is Map<String, dynamic>
              ? Product.fromJson(productData)
              : null,
      warehouse: warehouseData is Map<String, dynamic> ? warehouseData : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'product_id': productId,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      if (product != null) 'product': product!.toJson(),
      if (warehouse != null) 'warehouse': warehouse,
    };
  }
}
