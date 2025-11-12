import 'package:flutter/material.dart';

enum CreditSourceType { PURCHASE_RETURN, MANUAL_ADJUSTMENT }

enum CreditStatus { ACTIVE, EXPIRED, USED }

extension CreditStatusUi on CreditStatus {
  String get displayName {
    switch (this) {
      case CreditStatus.ACTIVE:
        return 'Active';
      case CreditStatus.EXPIRED:
        return 'Expired';
      case CreditStatus.USED:
        return 'Used';
    }
  }

  Color get color {
    switch (this) {
      case CreditStatus.ACTIVE:
        return Colors.green;
      case CreditStatus.EXPIRED:
        return Colors.red;
      case CreditStatus.USED:
        return Colors.grey;
    }
  }
}

class SupplierCredit {
  final String? id;
  final String supplierId;
  final double creditAmount;
  final double remainingAmount;
  final CreditSourceType sourceType;
  final String? sourceId;
  final DateTime? expiryDate;
  final CreditStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? supplierName;
  final List<CreditUsage>? usageHistory;

  const SupplierCredit({
    this.id,
    required this.supplierId,
    required this.creditAmount,
    required this.remainingAmount,
    required this.sourceType,
    this.sourceId,
    this.expiryDate,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.supplierName,
    this.usageHistory,
  });

  factory SupplierCredit.fromJson(Map<String, dynamic> json) {
    return SupplierCredit(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      supplierId: json['supplier_id']?.toString() ?? '',
      creditAmount: (json['credit_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      sourceType: CreditSourceType.values.firstWhere(
        (e) => e.name == (json['source_type'] as String),
        orElse: () => CreditSourceType.PURCHASE_RETURN,
      ),
      sourceId: json['source_id']?.toString(),
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'] as String)
              : null,
      status: CreditStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => CreditStatus.ACTIVE,
      ),
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      supplierName: json['supplier_name'] as String?,
      usageHistory:
          json['usage_history'] != null
              ? (json['usage_history'] as List)
                  .map((e) => CreditUsage.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'supplier_id': supplierId,
      'credit_amount': creditAmount,
      'remaining_amount': remainingAmount,
      'source_type': sourceType.name,
      if (sourceId != null) 'source_id': sourceId,
      if (expiryDate != null)
        'expiry_date': expiryDate!.toIso8601String().split('T')[0],
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class CreditUsage {
  final String? id;
  final String supplierCreditId;
  final String purchaseId;
  final double amountUsed;
  final DateTime? usedAt;
  final String? purchaseReference;

  const CreditUsage({
    this.id,
    required this.supplierCreditId,
    required this.purchaseId,
    required this.amountUsed,
    this.usedAt,
    this.purchaseReference,
  });

  factory CreditUsage.fromJson(Map<String, dynamic> json) {
    return CreditUsage(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      supplierCreditId: json['supplier_credit_id']?.toString() ?? '',
      purchaseId: json['purchase_id']?.toString() ?? '',
      amountUsed: (json['amount_used'] as num).toDouble(),
      usedAt:
          json['used_at'] != null
              ? DateTime.parse(json['used_at'] as String)
              : null,
      purchaseReference: json['purchase_reference'] as String?,
    );
  }
}
