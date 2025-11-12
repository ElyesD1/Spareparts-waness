class CreditPayment {
  final String id;
  final String creditSaleId;
  final String receivedBy;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // 'cash', 'check', 'bank_transfer'
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;

  CreditPayment({
    required this.id,
    required this.creditSaleId,
    required this.receivedBy,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
  });

  factory CreditPayment.fromJson(Map<String, dynamic> json) {
    return CreditPayment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      creditSaleId: json['credit_sale_id']?.toString() ?? '',
      receivedBy: json['received_by']?.toString() ?? '',
      amount:
          json['amount'] != null
              ? double.parse(json['amount'].toString())
              : 0.0,
      paymentDate:
          json['payment_date'] != null
              ? DateTime.parse(json['payment_date'].toString())
              : DateTime.now(),
      paymentMethod: json['payment_method'] ?? 'cash',
      referenceNumber: json['reference_number'],
      notes: json['notes'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'credit_sale_id': creditSaleId,
      'received_by': receivedBy,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'Espèces';
      case 'check':
        return 'Chèque';
      case 'bank_transfer':
        return 'Virement bancaire';
      default:
        return paymentMethod;
    }
  }
}
