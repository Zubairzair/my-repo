import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SKUService {
  static final SKUService _instance = SKUService._internal();
  factory SKUService() => _instance;
  SKUService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate automatic SKU based on category and product count
  /// Format: CATEGORY-001-VARIATION (e.g., SHIRT-001-RED-L)
  Future<String> generateAutoSKU({
    required String category,
    String? color,
    String? size,
    String? model,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get current product count for this category
      final categoryQuery = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category.toUpperCase())
          .get();

      final productNumber = (categoryQuery.docs.length + 1).toString().padLeft(3, '0');
      
      // Build SKU parts
      final categoryPart = category.toUpperCase().replaceAll(' ', '');
      var sku = '$categoryPart-$productNumber';
      
      // Add variations if provided
      final variations = <String>[];
      if (color != null && color.isNotEmpty) {
        variations.add(color.toUpperCase().substring(0, color.length > 3 ? 3 : color.length));
      }
      if (size != null && size.isNotEmpty) {
        variations.add(size.toUpperCase());
      }
      if (model != null && model.isNotEmpty) {
        variations.add(model.toUpperCase().substring(0, model.length > 2 ? 2 : model.length));
      }
      
      if (variations.isNotEmpty) {
        sku += '-${variations.join('-')}';
      }
      
      // Check for duplicates and add suffix if needed
      final existingQuery = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .where('sku', isEqualTo: sku)
          .get();
          
      if (existingQuery.docs.isNotEmpty) {
        var counter = 1;
        var newSku = '$sku-${counter.toString().padLeft(2, '0')}';
        
        while (true) {
          final checkQuery = await _firestore
              .collection('products')
              .where('userId', isEqualTo: userId)
              .where('sku', isEqualTo: newSku)
              .get();
              
          if (checkQuery.docs.isEmpty) break;
          
          counter++;
          newSku = '$sku-${counter.toString().padLeft(2, '0')}';
        }
        
        sku = newSku;
      }
      
      return sku;
    } catch (e) {
      throw Exception('Failed to generate SKU: ${e.toString()}');
    }
  }

  /// Validate SKU format and uniqueness
  Future<bool> validateSKU(String sku) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      // Check format (basic validation)
      if (sku.isEmpty || sku.length < 3) return false;
      
      // Check uniqueness
      final existingQuery = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .where('sku', isEqualTo: sku.toUpperCase())
          .get();
          
      return existingQuery.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get product by SKU
  Future<DocumentSnapshot?> getProductBySKU(String sku) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final query = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .where('sku', isEqualTo: sku.toUpperCase())
          .limit(1)
          .get();
          
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Generate variation SKU
  String generateVariationSKU(String baseSku, String variationType, String variationValue) {
    final variation = variationValue.toUpperCase().substring(
      0, 
      variationValue.length > 3 ? 3 : variationValue.length
    );
    return '$baseSku-$variation';
  }

  /// Extract category from SKU
  String extractCategoryFromSKU(String sku) {
    final parts = sku.split('-');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Extract product number from SKU
  String extractProductNumberFromSKU(String sku) {
    final parts = sku.split('-');
    return parts.length > 1 ? parts[1] : '';
  }
}