class OperationalExpense {
  final String? id;
  final String title;
  final double amount;
  final String type;
  final String warehouseId;
  final String createdBy;
  final DateTime date;
  final String? note;
  final String? warehouseName;
  final String? createdByName;

  OperationalExpense({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.warehouseId,
    required this.createdBy,
    required this.date,
    this.note,
    this.warehouseName,
    this.createdByName,
  });

  factory OperationalExpense.fromJson(Map<String, dynamic> json) {
    // Handle amount field that might be string or number
    double amount;
    if (json['amount'] is String) {
      amount = double.parse(json['amount'] as String);
    } else if (json['amount'] is num) {
      amount = (json['amount'] as num).toDouble();
    } else {
      amount = 0.0; // fallback
    }

    // Handle warehouse data - can be populated object or just ID
    final warehouseData =
        json['warehouse_id'] is Map ? json['warehouse_id'] : null;
    final warehouseId =
        warehouseData != null
            ? (warehouseData['_id']?.toString() ??
                warehouseData['id']?.toString() ??
                json['warehouse_id']?.toString() ??
                '')
            : (json['warehouse_id']?.toString() ?? '');
    final warehouseName = warehouseData?['name'] ?? json['warehouse_name'];

    // Handle created_by - can be populated object or just ID
    final createdByData = json['created_by'] is Map ? json['created_by'] : null;
    final createdBy =
        createdByData != null
            ? (createdByData['_id']?.toString() ??
                createdByData['id']?.toString() ??
                json['created_by']?.toString() ??
                '')
            : (json['created_by']?.toString() ?? '');
    final createdByName = createdByData?['name'] ?? json['created_by_name'];

    return OperationalExpense(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title'] as String? ?? '',
      amount: amount,
      type: json['type'] as String? ?? 'other',
      warehouseId: warehouseId,
      createdBy: createdBy,
      date:
          json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(),
      note: json['note'] as String?,
      warehouseName: warehouseName,
      createdByName: createdByName,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['_id'] = id;
    data['title'] = title;
    data['amount'] = amount;
    data['type'] = type;
    data['warehouse_id'] = warehouseId;
    data['created_by'] = createdBy;
    data['date'] = date.toIso8601String().substring(0, 10);
    if (note != null) data['note'] = note;
    return data;
  }

  OperationalExpense copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? warehouseId,
    String? createdBy,
    DateTime? date,
    String? note,
    String? warehouseName,
    String? createdByName,
  }) {
    return OperationalExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      warehouseId: warehouseId ?? this.warehouseId,
      createdBy: createdBy ?? this.createdBy,
      date: date ?? this.date,
      note: note ?? this.note,
      warehouseName: warehouseName ?? this.warehouseName,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
