import 'customer.dart';
import 'credit_sale_item.dart';
import 'credit_payment.dart';

class CreditSale {
  final String id;
  final Customer customer;
  final String warehouseId;
  final String createdBy;
  final DateTime saleDate;
  final double totalAmount;
  final double downPayment;
  final double creditAmount;
  final int installmentCount;
  final double monthlyPayment;
  final DateTime firstPaymentDate;
  final DateTime? lastPaymentDate;
  final String status; // 'pending', 'active', 'completed', 'overdue'
  final String? notes;
  final DateTime createdAt;
  final List<CreditSaleItem> items;
  final List<CreditPayment> payments;

  CreditSale({
    required this.id,
    required this.customer,
    required this.warehouseId,
    required this.createdBy,
    required this.saleDate,
    required this.totalAmount,
    required this.downPayment,
    required this.creditAmount,
    required this.installmentCount,
    required this.monthlyPayment,
    required this.firstPaymentDate,
    this.lastPaymentDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.items,
    required this.payments,
  });

  factory CreditSale.fromJson(Map<String, dynamic> json) {
    // Debug logging to see what we're receiving

    try {
      // Handle both 'customer' and 'customer_id' fields from backend
      final customerData = json['customer'] ?? json['customer_id'];

      return CreditSale(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        customer:
            customerData != null && customerData is Map
                ? Customer.fromJson(Map<String, dynamic>.from(customerData))
                : Customer.fromJson(
                  {},
                ), // Fallback to empty customer if not populated
        warehouseId: json['warehouse_id']?.toString() ?? '',
        createdBy: json['created_by']?.toString() ?? '',
        saleDate:
            json['sale_date'] != null
                ? DateTime.parse(json['sale_date'].toString())
                : DateTime.now(),
        totalAmount:
            json['total_amount'] != null
                ? double.parse(json['total_amount'].toString())
                : 0.0,
        downPayment:
            json['down_payment'] != null
                ? double.parse(json['down_payment'].toString())
                : 0.0,
        creditAmount:
            json['credit_amount'] != null
                ? double.parse(json['credit_amount'].toString())
                : 0.0,
        installmentCount: json['installment_count'] ?? 0,
        monthlyPayment:
            json['monthly_payment'] != null
                ? double.parse(json['monthly_payment'].toString())
                : 0.0,
        firstPaymentDate:
            json['first_payment_date'] != null
                ? DateTime.parse(json['first_payment_date'].toString())
                : DateTime.now(),
        lastPaymentDate:
            json['last_payment_date'] != null
                ? DateTime.parse(json['last_payment_date'].toString())
                : null,
        status: json['status'] ?? 'active',
        notes: json['notes'] ?? '',
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'].toString())
                : DateTime.now(),
        items:
            json['items'] != null &&
                    json['items'] is List &&
                    (json['items'] as List).isNotEmpty
                ? (json['items'] as List)
                    .map((item) {
                      try {
                        return CreditSaleItem.fromJson(item);
                      } catch (itemError) {
                        return null;
                      }
                    })
                    .where((item) => item != null)
                    .cast<CreditSaleItem>()
                    .toList()
                : [],
        payments:
            json['payments'] != null &&
                    json['payments'] is List &&
                    (json['payments'] as List).isNotEmpty
                ? (json['payments'] as List)
                    .map((payment) {
                      try {
                        return CreditPayment.fromJson(payment);
                      } catch (paymentError) {
                        return null;
                      }
                    })
                    .where((payment) => payment != null)
                    .cast<CreditPayment>()
                    .toList()
                : [],
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customer_id': customer.id,
      'warehouse_id': warehouseId,
      'created_by': createdBy,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'down_payment': downPayment,
      'credit_amount': creditAmount,
      'installment_count': installmentCount,
      'monthly_payment': monthlyPayment,
      'first_payment_date': firstPaymentDate.toIso8601String(),
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }

  // Computed properties
  // Sum of payments made AFTER the down payment (credit payments)
  double get creditPaymentsTotal =>
      payments.fold(0.0, (sum, payment) => sum + payment.amount);

  // What the user has paid in total = down payment + credit payments
  double get paidAmount => downPayment + creditPaymentsTotal;

  // Remaining part of the credit (excludes down payment)
  double get remainingAmount {
    final remaining = creditAmount - creditPaymentsTotal;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isOverdue {
    if (status == 'completed') return false;
    return DateTime.now().isAfter(firstPaymentDate.add(Duration(days: 30)));
  }

  String get statusDisplay {
    if (status == 'completed') return 'Payé';
    if (isOverdue) return 'En retard';
    if (payments.isNotEmpty) return 'Partiel';
    return 'En cours';
  }
}
