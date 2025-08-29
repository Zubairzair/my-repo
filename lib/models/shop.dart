class Shop {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? gstNumber;
  final String? businessType;
  final DateTime createdAt;
  final String userId;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.gstNumber,
    this.businessType,
    required this.createdAt,
    required this.userId,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gstNumber: json['gstNumber'],
      businessType: json['businessType'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'gstNumber': gstNumber,
      'businessType': businessType,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }
}