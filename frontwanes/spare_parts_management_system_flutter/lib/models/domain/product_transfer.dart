class ProductTransfer {
  final String? id;
  final String productId;
  final String? productName;
  final String? productReference;
  final String fromWarehouseId;
  final String? fromWarehouseName;
  final String toWarehouseId;
  final String? toWarehouseName;
  final int quantity;
  final String reason;
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final String
  status; // 'pending', 'approved', 'rejected', 'in_transit', 'completed', 'cancelled'
  final String requestedBy;
  final String? requestedByName;
  final String? requestedByRole;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? processedBy;
  final String? processedByName;
  final DateTime? processedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductTransfer({
    this.id,
    required this.productId,
    this.productName,
    this.productReference,
    required this.fromWarehouseId,
    this.fromWarehouseName,
    required this.toWarehouseId,
    this.toWarehouseName,
    required this.quantity,
    required this.reason,
    this.priority = 'normal',
    this.status = 'pending',
    required this.requestedBy,
    this.requestedByName,
    this.requestedByRole,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.processedBy,
    this.processedByName,
    this.processedAt,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductTransfer.fromJson(Map<String, dynamic> json) {
    return ProductTransfer(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'],
      productReference: json['product_reference'],
      fromWarehouseId: json['from_warehouse_id']?.toString() ?? '',
      fromWarehouseName: json['from_warehouse_name'],
      toWarehouseId: json['to_warehouse_id']?.toString() ?? '',
      toWarehouseName: json['to_warehouse_name'],
      quantity: json['quantity'] ?? 0,
      reason: json['reason'] ?? '',
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'pending',
      requestedBy: json['requested_by']?.toString() ?? '',
      requestedByName: json['requested_by_name'],
      requestedByRole: json['requested_by_role'],
      approvedBy: json['approved_by']?.toString(),
      approvedByName: json['approved_by_name'],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      processedBy: json['processed_by']?.toString(),
      processedByName: json['processed_by_name'],
      processedAt:
          json['processed_at'] != null
              ? DateTime.parse(json['processed_at'])
              : null,
      notes: json['notes'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'product_id': productId,
      'from_warehouse_id': fromWarehouseId,
      'to_warehouse_id': toWarehouseId,
      'quantity': quantity,
      'reason': reason,
      'priority': priority,
      'status': status,
      'requested_by': requestedBy,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (processedBy != null) 'processed_by': processedBy,
      if (notes != null) 'notes': notes,
    };
  }

  // Helper methods for status checking
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isInTransit => status == 'in_transit';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get canBeApproved => isPending;
  bool get canBeProcessed => isApproved;
  bool get canBeCancelled => isPending || isApproved;

  // Priority helpers
  bool get isUrgent => priority == 'urgent';
  bool get isHigh => priority == 'high';
  bool get isNormal => priority == 'normal';
  bool get isLow => priority == 'low';
}
