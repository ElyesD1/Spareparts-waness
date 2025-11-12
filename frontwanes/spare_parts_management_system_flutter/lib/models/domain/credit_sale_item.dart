class CreditSaleItem {
  final String id;
  final String creditSaleId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  CreditSaleItem({
    required this.id,
    required this.creditSaleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CreditSaleItem.fromJson(Map<String, dynamic> json) {
    return CreditSaleItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      creditSaleId: json['credit_sale_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice:
          json['unit_price'] != null
              ? double.parse(json['unit_price'].toString())
              : 0.0,
      totalPrice:
          json['total_price'] != null
              ? double.parse(json['total_price'].toString())
              : (json['unit_price'] != null && json['quantity'] != null
                  ? double.parse(json['unit_price'].toString()) *
                      (json['quantity'] as int)
                  : 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'credit_sale_id': creditSaleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
