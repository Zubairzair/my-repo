import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';

class PaymentManagement extends StatefulWidget {
  const PaymentManagement({super.key});

  @override
  State<PaymentManagement> createState() => _PaymentManagementState();
}

class _PaymentManagementState extends State<PaymentManagement>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isDisposed = false;
  bool _isLoading = false;
  List<ShopBalance> _shopBalances = [];
  List<Payment> _recentPayments = [];
  Map<String, double> _totalStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback callback) {
    if (!_isDisposed && mounted) {
      setState(callback);
    }
  }

  Future<void> _loadData() async {
    if (_isDisposed) return;

    _safeSetState(() {
      _isLoading = true;
    });

    try {
      final balances = await PaymentService.getAllShopBalances();
      final payments = await PaymentService.getAllPayments();
      final stats = await PaymentService.getTotalCreditDebit();

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _shopBalances = balances;
          _recentPayments = payments.take(10).toList();
          _totalStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading payment data: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isDisposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPaymentDialog,
            tooltip: 'Add Payment',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      _buildShopBalancesSection(),
                      const SizedBox(height: 24),
                      _buildRecentPaymentsSection(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Credit',
            'Rs ${(_totalStats['totalCredit'] ?? 0.0).toStringAsFixed(2)}',
            Colors.green,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Debit',
            'Rs ${(_totalStats['totalDebit'] ?? 0.0).toStringAsFixed(2)}',
            Colors.red,
            Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopBalancesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop Balances',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_shopBalances.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No shop balances found'),
              ),
            )
          else
            ..._shopBalances.map((balance) => _buildBalanceItem(balance)),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(ShopBalance balance) {
    final isPositive = balance.balance >= 0;
    final balanceColor = isPositive ? Colors.green : Colors.red;
    final balanceText = isPositive 
        ? 'We owe: Rs ${balance.balance.abs().toStringAsFixed(2)}'
        : 'They owe: Rs ${balance.balance.abs().toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceText,
                  style: TextStyle(
                    color: balanceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showShopPayments(balance),
            icon: const Icon(Icons.history),
            tooltip: 'View History',
          ),
          IconButton(
            onPressed: () => _showAddPaymentDialog(shopId: balance.shopId, shopName: balance.shopName),
            icon: const Icon(Icons.add),
            tooltip: 'Add Payment',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Payments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentPayments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No recent payments found'),
              ),
            )
          else
            ..._recentPayments.map((payment) => _buildPaymentItem(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final isCredit = payment.type == 'credit';
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  payment.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  payment.createdAt.toString().substring(0, 16),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs ${payment.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog({String? shopId, String? shopName}) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(
        shopId: shopId,
        shopName: shopName,
        onPaymentAdded: _loadData,
      ),
    );
  }

  void _showShopPayments(ShopBalance balance) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopPaymentHistory(
          shopId: balance.shopId,
          shopName: balance.shopName,
        ),
      ),
    );
  }
}

class AddPaymentDialog extends StatefulWidget {
  final String? shopId;
  final String? shopName;
  final VoidCallback onPaymentAdded;

  const AddPaymentDialog({
    super.key,
    this.shopId,
    this.shopName,
    required this.onPaymentAdded,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final descriptionController = TextEditingController();
  
  String? _selectedShopId;
  String? _selectedShopName;
  String _paymentType = 'credit';
  List<Map<String, dynamic>> _shops = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.shopId;
    _selectedShopName = widget.shopName;
    _loadShops();
  }

  @override
  void dispose() {
    _amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        _shops = snapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading shops: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Selection
                      if (widget.shopId == null) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedShopId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Shop *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Select a shop...'),
                            ),
                            ..._shops.map((shop) {
                              return DropdownMenuItem<String>(
                                value: shop['docId'],
                                child: Text(
                                  shop['name'] ?? 'Unknown Shop',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              final shop = _shops.firstWhere(
                                (s) => s['docId'] == value,
                                orElse: () => {},
                              );
                              setState(() {
                                _selectedShopId = value;
                                _selectedShopName = shop['name'];
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) return 'Please select a shop';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        TextFormField(
                          initialValue: widget.shopName,
                          decoration: const InputDecoration(
                            labelText: 'Shop Name',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Payment Type
                      DropdownButtonFormField<String>(
                        value: _paymentType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment Type *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'credit',
                            child: Flexible(
                              child: Text(
                                'Credit (Money we owe them)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'debit',
                            child: Flexible(
                              child: Text(
                                'Debit (Money they owe us)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _paymentType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount *',
                          border: OutlineInputBorder(),
                          prefixText: 'Rs ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          helperText: 'e.g., Invoice payment, Advance, etc.',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      );


  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation
    if (_selectedShopId == null || _selectedShopName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final description = descriptionController.text.trim();

      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }



      await PaymentService.addPayment(
        shopId: _selectedShopId!,
        shopName: _selectedShopName!,
        amount: amount,
        type: _paymentType,
        description: description,
      );

      if (mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment added successfully: Rs ${amount.toStringAsFixed(2)} ${_paymentType == 'credit' ? 'Credit' : 'Debit'}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the parent data
        widget.onPaymentAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Error adding payment';
        if (e.toString().contains('Exception:')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          errorMessage = 'Error adding payment: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

class ShopPaymentHistory extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopPaymentHistory({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopPaymentHistory> createState() => _ShopPaymentHistoryState();
}

class _ShopPaymentHistoryState extends State<ShopPaymentHistory> {
  List<Payment> _payments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payments = await PaymentService.getShopPayments(widget.shopId);
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.shopName} - Payment History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? const Center(
                  child: Text('No payment history found'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    final isCredit = payment.type == 'credit';
                    final color = isCredit ? Colors.green : Colors.red;
                    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payment.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  payment.createdAt.toString().substring(0, 16),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs ${payment.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                isCredit ? 'Credit' : 'Debit',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
