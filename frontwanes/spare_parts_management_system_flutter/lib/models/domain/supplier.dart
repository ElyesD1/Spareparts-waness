class Supplier {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? address;
  final String? companyName;
  final String? taxNumber;
  final double creditLimit;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.address,
    this.companyName,
    this.taxNumber,
    required this.creditLimit,
    required this.currentBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
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
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'is_active': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
