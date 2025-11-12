import 'package:flutter/material.dart';

enum ReturnStatus { PENDING, APPROVED, REJECTED, COMPLETED }

extension ReturnStatusUi on ReturnStatus {
  String get displayName {
    switch (this) {
      case ReturnStatus.PENDING:
        return 'Pending';
      case ReturnStatus.APPROVED:
        return 'Approved';
      case ReturnStatus.REJECTED:
        return 'Rejected';
      case ReturnStatus.COMPLETED:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case ReturnStatus.PENDING:
        return Colors.orange;
      case ReturnStatus.APPROVED:
        return Colors.blue;
      case ReturnStatus.REJECTED:
        return Colors.red;
      case ReturnStatus.COMPLETED:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case ReturnStatus.PENDING:
        return Icons.pending;
      case ReturnStatus.APPROVED:
        return Icons.check_circle;
      case ReturnStatus.REJECTED:
        return Icons.cancel;
      case ReturnStatus.COMPLETED:
        return Icons.done_all;
    }
  }
}

class PurchaseReturn {
  final String? id;
  final String supplierId;
  final String warehouseId;
  final String createdBy;
  final DateTime returnDate;
  final double totalAmount;
  final String reason;
  final ReturnStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? supplierName;
  final String? warehouseName;
  final String? createdByName;
  final List<PurchaseReturnItem>? items;

  const PurchaseReturn({
    this.id,
    required this.supplierId,
    required this.warehouseId,
    required this.createdBy,
    required this.returnDate,
    required this.totalAmount,
    required this.reason,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.supplierName,
    this.warehouseName,
    this.createdByName,
    this.items,
  });

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final supplierMap =
        json['supplier'] is Map
            ? (json['supplier'] as Map).cast<String, dynamic>()
            : (json['supplier_id'] is Map
                ? (json['supplier_id'] as Map).cast<String, dynamic>()
                : null);
    final warehouseMap =
        json['warehouse'] is Map
            ? (json['warehouse'] as Map).cast<String, dynamic>()
            : (json['warehouse_id'] is Map
                ? (json['warehouse_id'] as Map).cast<String, dynamic>()
                : null);
    final createdByMap =
        json['createdBy'] is Map
            ? (json['createdBy'] as Map).cast<String, dynamic>()
            : (json['created_by'] is Map
                ? (json['created_by'] as Map).cast<String, dynamic>()
                : null);

    return PurchaseReturn(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      supplierId:
          supplierMap?['_id']?.toString() ??
          supplierMap?['id']?.toString() ??
          json['supplier_id']?.toString() ??
          '',
      warehouseId:
          warehouseMap?['_id']?.toString() ??
          warehouseMap?['id']?.toString() ??
          json['warehouse_id']?.toString() ??
          '',
      createdBy:
          createdByMap?['_id']?.toString() ??
          createdByMap?['id']?.toString() ??
          json['created_by']?.toString() ??
          '',
      returnDate: DateTime.parse(json['return_date'] as String),
      totalAmount: parseDouble(json['total_amount']),
      reason: json['reason'] as String? ?? '',
      status: _parseStatus(json['status']),
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      supplierName:
          (json['supplier_name'] as String?) ??
          supplierMap?['name']?.toString(),
      warehouseName:
          (json['warehouse_name'] as String?) ??
          warehouseMap?['name']?.toString(),
      createdByName:
          (json['created_by_name'] as String?) ??
          createdByMap?['name']?.toString(),
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map(
                    (item) => PurchaseReturnItem.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'supplier_id': supplierId,
      'warehouse_id': warehouseId,
      'created_by': createdBy,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'total_amount': totalAmount,
      'reason': reason,
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper method to safely parse status from various formats
  static ReturnStatus _parseStatus(dynamic statusValue) {
    if (statusValue == null) return ReturnStatus.PENDING;

    final statusStr = statusValue.toString().toUpperCase();

    // Handle different possible status formats
    switch (statusStr) {
      case 'PENDING':
      case 'PENDENT':
        return ReturnStatus.PENDING;
      case 'APPROVED':
      case 'APPROVE':
        return ReturnStatus.APPROVED;
      case 'REJECTED':
      case 'REJECT':
        return ReturnStatus.REJECTED;
      case 'COMPLETED':
      case 'COMPLETE':
      case 'DONE':
        return ReturnStatus.COMPLETED;
      default:
        return ReturnStatus.PENDING;
    }
  }
}

class PurchaseReturnItem {
  final String? id;
  final String purchaseReturnId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  final String? productName;
  final String? productReference;

  const PurchaseReturnItem({
    this.id,
    required this.purchaseReturnId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.productName,
    this.productReference,
  });

  factory PurchaseReturnItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numeric values
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PurchaseReturnItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      purchaseReturnId: json['purchase_return_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: parseInt(json['quantity']),
      unitPrice: parseDouble(json['unit_price']),
      totalPrice: parseDouble(json['total_price']),
      productName: json['product_name'] as String?,
      productReference: json['product_reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'purchase_return_id': purchaseReturnId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
