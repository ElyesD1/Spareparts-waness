class Customer {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? address;
  final String? companyName;
  final String? taxNumber;
  final int? cin;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.companyName,
    this.taxNumber,
    this.cin,
    required this.creditLimit,
    required this.currentBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    try {
      return Customer(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        address: json['address'],
        companyName: json['company_name'],
        taxNumber: json['tax_number'],
        creditLimit:
            json['credit_limit'] != null
                ? double.parse(json['credit_limit'].toString())
                : 0.0,
        currentBalance:
            json['current_balance'] != null
                ? double.parse(json['current_balance'].toString())
                : 0.0,
        cin: json['cin'],
        isActive: json['is_active'] ?? true,
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'].toString())
                : DateTime.now(),
        updatedAt:
            json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'].toString())
                : DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'company_name': companyName,
      'tax_number': taxNumber,
      'cin': cin,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'is_active': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
