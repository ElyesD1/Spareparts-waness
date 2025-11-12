class User {
  final String? id;
  final String name;
  final String email;
  final String? password;
  final int phoneNumber;
  final String role;
  final String? warehouseId;
  final String? warehouseName;
  final String? warehouseLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
    required this.phoneNumber,
    required this.role,
    this.warehouseId,
    this.warehouseName,
    this.warehouseLocation,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] as String?,
      phoneNumber:
          json['phone_number'] is int
              ? json['phone_number']
              : int.tryParse(json['phone_number']?.toString() ?? '0') ?? 0,
      role: json['role'] as String? ?? 'employee',
      warehouseId: json['warehouse_id']?.toString(),
      warehouseName: json['warehouse_name'] as String?,
      warehouseLocation: json['warehouse_location'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
    };
    if (id != null) {
      data['_id'] = id;
    }
    if (password != null) {
      data['password'] = password;
    }
    if (warehouseId != null) {
      data['warehouse_id'] = warehouseId;
    }
    if (warehouseName != null) {
      data['warehouse_name'] = warehouseName;
    }
    if (warehouseLocation != null) {
      data['warehouse_location'] = warehouseLocation;
    }
    return data;
  }
}
