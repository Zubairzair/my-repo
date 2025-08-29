class Product {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int quantity;
  final int minStock;
  final List<ProductVariation> variations;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String userId;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.minStock,
    this.variations = const [],
    required this.createdAt,
    required this.lastUpdated,
    required this.userId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      minStock: json['minStock'] ?? 0,
      variations: (json['variations'] as List<dynamic>?)
          ?.map((v) => ProductVariation.fromJson(v))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'quantity': quantity,
      'minStock': minStock,
      'variations': variations.map((v) => v.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'userId': userId,
    };
  }
}

class ProductVariation {
  final String id;
  final String type; // color, size, model, etc.
  final String value; // red, large, v2, etc.
  final String sku;
  final int quantity;
  final double? priceModifier; // additional cost for this variation

  ProductVariation({
    required this.id,
    required this.type,
    required this.value,
    required this.sku,
    required this.quantity,
    this.priceModifier,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      sku: json['sku'] ?? '',
      quantity: json['quantity'] ?? 0,
      priceModifier: json['priceModifier']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'sku': sku,
      'quantity': quantity,
      'priceModifier': priceModifier,
    };
  }
}