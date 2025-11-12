import 'product.dart';

class PurchaseItem {
  final String? id;
  final String productId;
  final String productName;
  final Product? product;
  final String warehouseId;
  final String warehouseName;
  final int quantity;
  final double unitPrice;

  PurchaseItem({
    this.id,
    required this.productId,
    required this.productName,
    this.product,
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    required this.unitPrice,
  }) {}

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    // Handle product data - can be populated object or just ID
    final productData =
        json['product_id'] is Map ? json['product_id'] : json['product'];
    final productId =
        productData is Map
            ? (productData['_id']?.toString() ??
                productData['id']?.toString() ??
                '')
            : (json['product_id']?.toString() ?? '');
    final productName = productData is Map ? (productData['name'] ?? '') : '';

    // Handle warehouse data - can be populated object or just ID
    final warehouseData =
        json['warehouse_id'] is Map ? json['warehouse_id'] : json['warehouse'];
    final warehouseId =
        warehouseData is Map
            ? (warehouseData['_id']?.toString() ??
                warehouseData['id']?.toString() ??
                '')
            : (json['warehouse_id']?.toString() ?? '');
    final warehouseName =
        warehouseData is Map ? (warehouseData['name'] ?? '') : '';

    final item = PurchaseItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      productId: productId,
      productName: productName,
      product:
          productData is Map<String, dynamic>
              ? Product.fromJson(productData)
              : null,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      quantity:
          json['quantity'] is int
              ? json['quantity']
              : int.tryParse(json['quantity'].toString()) ?? 0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
    );
    return item;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'product_id': productId,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
    if (id != null) map['_id'] = id!;
    return map;
  }
}
