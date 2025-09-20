import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a payment record
  static Future<void> addPayment({
    required String shopId,
    required String shopName,
    required double amount,
    required String type, // 'credit' or 'debit'
    required String description,
    String? invoiceId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final payment = Payment(
      id: '',
      shopId: shopId,
      shopName: shopName,
      amount: amount,
      type: type,
      description: description,
      invoiceId: invoiceId,
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _firestore.collection('payments').add(payment.toJson());
  }

  // Get all payments for a specific shop
  static Future<List<Payment>> getShopPayments(String shopId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .where('shopId', isEqualTo: shopId)
        .get();

    // Sort on client side to avoid composite index requirement
    final payments = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromJson(data);
    }).toList();

    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return payments;
  }

  // Get all payments
  static Future<List<Payment>> getAllPayments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .get();

    // Sort on client side to avoid composite index requirement
    final payments = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromJson(data);
    }).toList();

    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return payments;
  }

  // Calculate balance for a specific shop
  static Future<ShopBalance> getShopBalance(String shopId, String shopName) async {
    final payments = await getShopPayments(shopId);
    
    double totalCredit = 0.0;
    double totalDebit = 0.0;

    for (final payment in payments) {
      if (payment.type == 'credit') {
        totalCredit += payment.amount;
      } else {
        totalDebit += payment.amount;
      }
    }

    return ShopBalance(
      shopId: shopId,
      shopName: shopName,
      totalCredit: totalCredit,
      totalDebit: totalDebit,
    );
  }

  // Get balances for all shops
  static Future<List<ShopBalance>> getAllShopBalances() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Get all shops
    final shopsSnapshot = await _firestore
        .collection('shops')
        .where('userId', isEqualTo: userId)
        .get();

    final List<ShopBalance> balances = [];

    for (final shopDoc in shopsSnapshot.docs) {
      final shopData = shopDoc.data();
      final shopId = shopDoc.id;
      final shopName = shopData['name'] ?? 'Unknown Shop';

      final balance = await getShopBalance(shopId, shopName);
      balances.add(balance);
    }

    return balances;
  }

  // Get total credit and debit across all shops
  static Future<Map<String, double>> getTotalCreditDebit() async {
    final payments = await getAllPayments();
    
    double totalCredit = 0.0;
    double totalDebit = 0.0;

    for (final payment in payments) {
      if (payment.type == 'credit') {
        totalCredit += payment.amount;
      } else {
        totalDebit += payment.amount;
      }
    }

    return {
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'netBalance': totalCredit - totalDebit,
    };
  }

  // Delete a payment
  static Future<void> deletePayment(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).delete();
  }
}
