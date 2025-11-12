import 'package:flutter/material.dart';

class SupplierCreditUsage {
  final String? id;
  final String supplierCreditId;
  final String purchaseId;
  final double amountUsed;
  final DateTime? usedAt;

  // Related entities (populated when eager loading)
  final Map<String, dynamic>? supplierCredit;
  final Map<String, dynamic>? purchase;

  const SupplierCreditUsage({
    this.id,
    required this.supplierCreditId,
    required this.purchaseId,
    required this.amountUsed,
    this.usedAt,
    this.supplierCredit,
    this.purchase,
  });

  factory SupplierCreditUsage.fromJson(Map<String, dynamic> json) {
    return SupplierCreditUsage(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      supplierCreditId: json['supplier_credit_id']?.toString() ?? '',
      purchaseId: json['purchase_id']?.toString() ?? '',
      amountUsed: (json['amount_used'] as num).toDouble(),
      usedAt:
          json['used_at'] != null
              ? DateTime.parse(json['used_at'] as String)
              : null,
      supplierCredit: json['supplierCredit'] as Map<String, dynamic>?,
      purchase: json['purchase'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'supplier_credit_id': supplierCreditId,
      'purchase_id': purchaseId,
      'amount_used': amountUsed,
      if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
    };
  }
}
