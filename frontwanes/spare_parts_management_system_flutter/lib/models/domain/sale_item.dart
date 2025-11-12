import 'product.dart';

class SaleItem {
  final String? id;
  final String? saleId;
  final String? productId;
  final Product? product;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final Map<String, dynamic>? sale;

  SaleItem({
    this.id,
    this.saleId,
    this.productId,
    this.product,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.sale,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    // Handle product data - can be populated object or just ID
    final productData =
        json['product_id'] is Map ? json['product_id'] : json['product'];
    final productId =
        productData is Map
            ? (productData['_id']?.toString() ?? productData['id']?.toString())
            : json['product_id']?.toString();

    return SaleItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      saleId: json['sale_id']?.toString(),
      productId: productId,
      product:
          productData is Map<String, dynamic>
              ? Product.fromJson(productData)
              : null,
      quantity: json['quantity'],
      unitPrice:
          json['unitPrice'] != null
              ? (json['unitPrice'] is num
                  ? (json['unitPrice'] as num).toDouble()
                  : double.tryParse(json['unitPrice'].toString()))
              : (json['unit_price'] != null
                  ? (json['unit_price'] is num
                      ? (json['unit_price'] as num).toDouble()
                      : double.tryParse(json['unit_price'].toString()))
                  : null),
      totalPrice:
          json['totalPrice'] != null
              ? (json['totalPrice'] is num
                  ? (json['totalPrice'] as num).toDouble()
                  : double.tryParse(json['totalPrice'].toString()))
              : null,
      sale: json['sale'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (saleId != null && saleId!.isNotEmpty) data['sale_id'] = saleId;
    if (productId != null) data['product_id'] = productId;
    if (quantity != null) data['quantity'] = quantity;
    if (unitPrice != null) data['unit_price'] = unitPrice;
    if (totalPrice != null) data['totalPrice'] = totalPrice;
    if (sale != null) data['sale'] = sale;
    return data;
  }

  double get total => (quantity ?? 0) * (unitPrice ?? 0);
}
