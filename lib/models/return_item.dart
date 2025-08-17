class ReturnItem {
  final String id;
  final String? invoiceId; // null for stock adjustments
  final String productName;
  final String productSku;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final ReturnType type;
  final String reason;
  final String? notes;
  final DateTime createdAt;
  final String userId;

  ReturnItem({
    required this.id,
    this.invoiceId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.type,
    required this.reason,
    this.notes,
    required this.createdAt,
    required this.userId,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'],
      productName: json['productName'] ?? '',
      productSku: json['productSku'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      type: ReturnType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ReturnType.customerReturn,
      ),
      reason: json['reason'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productName': productName,
      'productSku': productSku,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'type': type.toString().split('.').last,
      'reason': reason,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }
}

enum ReturnType {
  customerReturn, // Items sold but returned by customer
  stockAdjustment, // Manual stock corrections
}