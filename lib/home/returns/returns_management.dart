import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReturnsManagement extends StatefulWidget {
  const ReturnsManagement({super.key});

  @override
  State<ReturnsManagement> createState() => _ReturnsManagementState();
}

class _ReturnsManagementState extends State<ReturnsManagement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Returns Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildReturnsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReturnDialog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Return'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Product Returns',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage returned items and stock adjustments',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('returns')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final returns = snapshot.data!.docs;
        final totalReturns = returns.length;
        final todayReturns = returns.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final returnDate = DateTime.parse(data['createdAt']);
          final today = DateTime.now();
          return returnDate.year == today.year &&
              returnDate.month == today.month &&
              returnDate.day == today.day;
        }).length;
        
        final totalValue = returns.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['totalAmount'] as double? ?? 0);
        });

        return Row(
          children: [
            _buildStatCard('Total Returns', totalReturns.toString(), Icons.assignment_return, Colors.orange),
            const SizedBox(width: 12),
            _buildStatCard('Today', todayReturns.toString(), Icons.today, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard('Value', 'Rs ${totalValue.toStringAsFixed(0)}', Icons.attach_money, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAllReturns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading returns',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final returns = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: returns.length,
          itemBuilder: (context, index) {
            final returnItem = returns[index].data() as Map<String, dynamic>;
            return _buildReturnCard(returnItem, returns[index].id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAllReturns() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('returns')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_return_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No returns recorded',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Returns will appear here when customers bring back items',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddReturnDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Return'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> returnItem, String docId) {
    final createdAt = DateTime.parse(returnItem['createdAt']);
    final returnType = returnItem['type'] ?? 'customerReturn';
    final isCustomerReturn = returnType == 'customerReturn';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCustomerReturn ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        returnItem['productName'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${returnItem['productSku'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCustomerReturn 
                        ? Colors.orange.withOpacity(0.1) 
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCustomerReturn ? 'CUSTOMER RETURN' : 'STOCK ADJUSTMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCustomerReturn ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Quantity',
                    '${returnItem['quantity']}',
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Unit Price',
                    'Rs ${(returnItem['unitPrice'] as double?)?.toStringAsFixed(2) ?? '0'}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Total',
                    'Rs ${(returnItem['totalAmount'] as double?)?.toStringAsFixed(2) ?? '0'}',
                    Icons.account_balance_wallet,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Return Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    returnItem['reason'] ?? 'No reason provided',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  if (returnItem['notes'] != null && returnItem['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${returnItem['notes']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (returnItem['invoiceId'] != null) 
                  Text(
                    'Invoice: ${returnItem['invoiceId']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _deleteReturn(docId, returnItem['productName']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAddReturnDialog() {
    final productNameController = TextEditingController();
    final productSkuController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    
    String selectedType = 'customerReturn';
    List<Map<String, dynamic>> stockItems = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Add Return'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Return Type Selection
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Return Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'customerReturn',
                          child: Text('Customer Return'),
                        ),
                        DropdownMenuItem(
                          value: 'stockAdjustment',
                          child: Text('Stock Adjustment'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stock Item Selection
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadStockItemsForReturn(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          stockItems = snapshot.data!;
                        }
                        
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Item from Stock',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_2),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Select from stock...'),
                            ),
                            ...stockItems.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['sku'],
                                child: Text('${item['name']} (${item['sku']})'),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              final selectedItem = stockItems.firstWhere((item) => item['sku'] == value);
                              setDialogState(() {
                                productNameController.text = selectedItem['name'];
                                productSkuController.text = selectedItem['sku'];
                                unitPriceController.text = selectedItem['price'].toString();
                              });
                            }
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: productNameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: productSkuController,
                      decoration: const InputDecoration(
                        labelText: 'Product SKU *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: unitPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price (Rs) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Return Reason *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                        helperText: 'e.g., Defective, Wrong size, Customer changed mind',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _processReturn(
                  context,
                  productNameController.text,
                  productSkuController.text,
                  quantityController.text,
                  unitPriceController.text,
                  reasonController.text,
                  notesController.text,
                  selectedType,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Return'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadStockItemsForReturn() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('userId', isEqualTo: userId)
          .get();

      return stockSnapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading stock items: $e');
      return [];
    }
  }

  Future<void> _processReturn(
    BuildContext dialogContext,
    String productName,
    String productSku,
    String quantity,
    String unitPrice,
    String reason,
    String notes,
    String returnType,
  ) async {
    if (productName.isEmpty || productSku.isEmpty || quantity.isEmpty || 
        unitPrice.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final returnId = 'RET-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final returnQuantity = int.parse(quantity);
      final returnUnitPrice = double.parse(unitPrice);
      final totalAmount = returnQuantity * returnUnitPrice;

      // Add return record
      await FirebaseFirestore.instance.collection('returns').add({
        'id': returnId,
        'userId': user.uid,
        'productName': productName,
        'productSku': productSku,
        'quantity': returnQuantity,
        'unitPrice': returnUnitPrice,
        'totalAmount': totalAmount,
        'type': returnType,
        'reason': reason,
        'notes': notes,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Restore stock if SKU exists in inventory
      final stockQuery = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('userId', isEqualTo: user.uid)
          .where('sku', isEqualTo: productSku)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final stockData = stockDoc.data();
        final currentStock = stockData['quantity'] as int;
        final newStock = currentStock + returnQuantity;

        await FirebaseFirestore.instance
            .collection('stock_items')
            .doc(stockDoc.id)
            .update({
          'quantity': newStock,
          'lastUpdated': DateTime.now().toString().substring(0, 10),
        });
      }

      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return processed successfully! Stock updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing return: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteReturn(String docId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Return'),
        content: Text('Are you sure you want to delete the return for "$productName"? This action cannot be undone and will not affect stock levels.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('returns')
                    .doc(docId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Return deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting return: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}