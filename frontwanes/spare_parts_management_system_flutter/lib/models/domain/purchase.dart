class Purchase {
  final String id;
  final String date;
  final double totalAmount;
  final double creditApplied;
  final double finalAmount;
  final Map<String, dynamic>? supplier;
  final Map<String, dynamic>? createdBy;
  final String? status;
  final Map<String, dynamic>? deliveredBy;
  final String? deliveredAt;
  // Derived display fields
  final String? supplierName;
  final String? createdByName;
  final String? warehouseName;

  Purchase({
    required this.id,
    required this.date,
    required this.totalAmount,
    this.creditApplied = 0.0,
    this.finalAmount = 0.0,
    this.supplier,
    this.createdBy,
    this.status,
    this.deliveredBy,
    this.deliveredAt,
    this.supplierName,
    this.createdByName,
    this.warehouseName,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final supplierMap =
        json['supplier_id'] is Map
            ? (json['supplier_id'] as Map).cast<String, dynamic>()
            : json['supplier'] is Map
            ? (json['supplier'] as Map).cast<String, dynamic>()
            : null;
    final createdByMap =
        json['created_by'] is Map
            ? (json['created_by'] as Map).cast<String, dynamic>()
            : json['createdBy'] is Map
            ? (json['createdBy'] as Map).cast<String, dynamic>()
            : null;

    return Purchase(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      creditApplied:
          double.tryParse(json['credit_applied']?.toString() ?? '0.0') ?? 0.0,
      finalAmount:
          double.tryParse(json['final_amount']?.toString() ?? '0.0') ?? 0.0,
      supplier: supplierMap,
      createdBy: createdByMap,
      status: json['status'],
      deliveredBy: json['delivered_by'] ?? json['deliveredBy'],
      deliveredAt: json['delivered_at'] ?? json['deliveredAt'],
      supplierName:
          supplierMap != null ? supplierMap['name']?.toString() : null,
      createdByName:
          createdByMap != null ? createdByMap['name']?.toString() : null,
      warehouseName: json['warehouseName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'date': date,
      'total_amount': totalAmount,
      'credit_applied': creditApplied,
      'final_amount': finalAmount,
      'supplier_id': supplier,
      'created_by': createdBy,
      'status': status,
      'delivered_by': deliveredBy,
      'delivered_at': deliveredAt,
      'supplierName': supplierName,
      'createdByName': createdByName,
      'warehouseName': warehouseName,
    };
  }

  Purchase copyWith({
    String? id,
    String? date,
    double? totalAmount,
    double? creditApplied,
    double? finalAmount,
    Map<String, dynamic>? supplier,
    Map<String, dynamic>? createdBy,
    String? status,
    Map<String, dynamic>? deliveredBy,
    String? deliveredAt,
    String? supplierName,
    String? createdByName,
    String? warehouseName,
  }) {
    return Purchase(
      id: id ?? this.id,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      creditApplied: creditApplied ?? this.creditApplied,
      finalAmount: finalAmount ?? this.finalAmount,
      supplier: supplier ?? this.supplier,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      supplierName: supplierName ?? this.supplierName,
      createdByName: createdByName ?? this.createdByName,
      warehouseName: warehouseName ?? this.warehouseName,
    );
  }
}
