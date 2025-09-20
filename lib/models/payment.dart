class Payment {
  final String id;
  final String shopId;
  final String shopName;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String description;
  final String? invoiceId;
  final DateTime createdAt;
  final String userId;

  Payment({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.amount,
    required this.type,
    required this.description,
    this.invoiceId,
    required this.createdAt,
    required this.userId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'credit',
      description: json['description'] ?? '',
      invoiceId: json['invoiceId'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'amount': amount,
      'type': type,
      'description': description,
      'invoiceId': invoiceId,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }
}

class ShopBalance {
  final String shopId;
  final String shopName;
  final double totalCredit;
  final double totalDebit;
  final double balance; // positive = we owe them, negative = they owe us

  ShopBalance({
    required this.shopId,
    required this.shopName,
    required this.totalCredit,
    required this.totalDebit,
  }) : balance = totalCredit - totalDebit;

  factory ShopBalance.fromJson(Map<String, dynamic> json) {
    return ShopBalance(
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      totalCredit: (json['totalCredit'] ?? 0).toDouble(),
      totalDebit: (json['totalDebit'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'balance': balance,
    };
  }
}
