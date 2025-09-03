import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/invoice_export_service.dart';

class CreateInvoice extends StatefulWidget {
  const CreateInvoice({super.key});

  @override
  State<CreateInvoice> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoice> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _discountController;
  late final TextEditingController _extraDiscountController;

  List<Map<String, dynamic>> items = [];

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _selectedShopId;
  Map<String, dynamic>? _selectedShop;
  List<Map<String, dynamic>> _shops = [];
  int _nextInvoiceNumber = 1;

  // Mathematical calculations with proper logic
  double get subtotal => items.fold(
      0.0,
          (sum, item) =>
      sum +
          ((item['quantity'] ?? 1) as int) *
              ((item['tp'] ?? 0.0) as double));

  double get discount => (double.tryParse(_discountController.text) ?? 0.0) * subtotal / 100;
  double get extraDiscount => (double.tryParse(_extraDiscountController.text) ?? 0.0) * subtotal / 100;

  double get totalDiscount => discount + extraDiscount;
  double get finalTotal => subtotal - totalDiscount;

  Map<String, dynamic> _createEmptyItem() {
    return {
      'sku': '',
      'name': '',
      'quantity': 1,
      'unit': 'Pcs',
      'tp': 0.0,
      'stockItemId': null,
      'availableStock': 0,
    };
  }

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(text: '0');
    _extraDiscountController = TextEditingController(text: '0');
    items = [_createEmptyItem()]; // Initialize with one empty item
    _loadShops();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _discountController.dispose();
    _extraDiscountController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback callback) {
    if (!_isDisposed && mounted) {
      setState(callback);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Fix AutomaticKeepAliveClientMixin error
    
    if (_isDisposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('New Invoice'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildShopSection(),
                  const SizedBox(height: 24),
                  _buildItemsSection(),
                  const SizedBox(height: 24),
                  _buildDiscountSection(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 100), // Space for bottom button
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildShopSection() {
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
            'Shop Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Shop Name Dropdown
          DropdownButtonFormField<String>(
            value: _selectedShopId,
            decoration: InputDecoration(
              labelText: 'Shop Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: _shops.isEmpty 
              ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No shops available - Add shops first'),
                  ),
                ]
              : [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select a shop...'),
                  ),
                  ..._shops.map((shop) {
                    final shopId = shop['docId']?.toString() ?? '';
                    final shopName = shop['name']?.toString() ?? 'Unnamed Shop';
                    
                    return DropdownMenuItem<String>(
                      value: shopId,
                      child: Text(
                        shopName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ],
            onChanged: (value) {
              if (value != null) {
                final selectedShop = _shops.firstWhere(
                  (shop) => shop['docId']?.toString() == value,
                  orElse: () => {},
                );
                
                if (selectedShop.isNotEmpty) {
                  _safeSetState(() {
                    _selectedShopId = value;
                    _selectedShop = selectedShop;
                  });
                }
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a shop';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Shop Address (Auto-filled)
          if (_selectedShop != null) ...[
            TextFormField(
              initialValue: _selectedShop!['address']?.toString() ?? 'No address provided',
              decoration: InputDecoration(
                labelText: 'Shop Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
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
            'Invoice Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            return _buildItemRow(index);
          }),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Another Item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final qty = (items[index]['quantity'] ?? 1) as int;
    final tp = (items[index]['tp'] ?? 0.0) as double;
    final itemTotal = qty * tp;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Serial Number and Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Item #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              if (items.length > 1)
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // SKU Field (Auto-generate or Manual)
          TextFormField(
            initialValue: items[index]['sku']?.toString() ?? '',
            decoration: InputDecoration(
              labelText: 'SKU',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              helperText: 'Leave empty to auto-generate unique SKU',
            ),
            onChanged: (value) {
              _safeSetState(() {
                items[index]['sku'] = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Item Name Dropdown from Stock
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadStockItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              
              final stockItems = snapshot.data ?? [];
              
              return DropdownButtonFormField<String>(
                value: items[index]['stockItemId'],
                decoration: InputDecoration(
                  labelText: 'Select Item from Stock *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select item from stock...'),
                  ),
                  ...stockItems.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['docId'],
                      child: Text(
                        '${item['name']} (${item['sku']}) - Stock: ${item['quantity']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ],
                validator: (value) {
                  if (value == null) {
                    return 'Please select an item';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    final selectedItem = stockItems.firstWhere(
                      (item) => item['docId'] == value,
                      orElse: () => {},
                    );
                    
                    if (selectedItem.isNotEmpty) {
                      _safeSetState(() {
                        items[index]['stockItemId'] = value;
                        items[index]['name'] = selectedItem['name'];
                        items[index]['sku'] = selectedItem['sku'];
                        items[index]['tp'] = selectedItem['price'] ?? 0.0;
                        items[index]['unit'] = 'Pcs'; // Default unit
                        items[index]['availableStock'] = selectedItem['quantity'];
                      });
                    }
                  }
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Quantity and Unit Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: qty.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (value) {
                    final qty = int.tryParse(value ?? '');
                    if (qty == null || qty <= 0) {
                      return 'Enter valid quantity';
                    }
                    final availableStock = items[index]['availableStock'] as int? ?? 0;
                    if (qty > availableStock && availableStock > 0) {
                      return 'Only $availableStock available';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final newQty = int.tryParse(value) ?? 1;
                    _safeSetState(() {
                      items[index]['quantity'] = newQty;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: items[index]['unit']?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText: 'Unit *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    helperText: 'e.g., Pcs, Kg, Litre',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter unit';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _safeSetState(() {
                      items[index]['unit'] = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TP (Trade Price) and Total Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: tp == 0.0 ? '' : tp.toInt().toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'TP (Trade Price) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    helperText: 'Price per unit (whole numbers only)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter price';
                    }
                    final tp = int.tryParse(value);
                    if (tp == null || tp <= 0) {
                      return 'Enter valid whole number price';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final newTp = int.tryParse(value) ?? 0;
                    _safeSetState(() {
                      items[index]['tp'] = newTp.toDouble();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Line Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Rs ${itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
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
            'Discount Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Discount (%) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    helperText: 'Required discount percentage',
                  ),
                  validator: (value) {
                    final discount = double.tryParse(value ?? '');
                    if (discount == null || discount < 0 || discount > 100) {
                      return 'Enter valid discount (0-100%)';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _safeSetState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _extraDiscountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Extra Discount (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    helperText: 'Optional additional discount',
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final extraDiscount = double.tryParse(value);
                      if (extraDiscount == null || extraDiscount < 0 || extraDiscount > 100) {
                        return 'Enter valid discount (0-100%)';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _safeSetState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.shade100, Colors.blueAccent.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
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
            const Text(
              'Invoice Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', 'Rs ${subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Discount (${_discountController.text}%)', '- Rs ${discount.toStringAsFixed(2)}'),
            if ((double.tryParse(_extraDiscountController.text) ?? 0) > 0)
              _buildSummaryRow('Extra Discount (${_extraDiscountController.text}%)', '- Rs ${extraDiscount.toStringAsFixed(2)}'),
            const Divider(color: Colors.white70, thickness: 1),
            _buildSummaryRow('Final Total', 'Rs ${finalTotal.toStringAsFixed(2)}', isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Generate Invoice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _addItem() {
    if (!_isDisposed && mounted) {
      _safeSetState(() {
        items.add(_createEmptyItem());
      });
    }
  }

  void _removeItem(int index) {
    if (!_isDisposed && mounted) {
      _safeSetState(() {
        items.removeAt(index);
      });
    }
  }

  String _generateUniqueSKU() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final lastFourDigits = timestamp.toString().substring(timestamp.toString().length - 4);
    return 'SKU$lastFourDigits';
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    // Auto-generate SKUs for empty ones
    for (int i = 0; i < items.length; i++) {
      if (items[i]['sku'] == null || items[i]['sku'].toString().trim().isEmpty) {
        items[i]['sku'] = _generateUniqueSKU();
      }
    }

    // Validate that all items have required fields
    bool allItemsValid = items.every((item) =>
        (item['name'] ?? '').toString().isNotEmpty &&
        ((item['quantity'] ?? 0) as int) > 0 &&
        ((item['tp'] ?? 0.0) as double) > 0 &&
        (item['unit'] ?? '').toString().isNotEmpty);

    if (!allItemsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all item fields (name, quantity, unit, TP)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _safeSetState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get next invoice number
      final counterDoc = FirebaseFirestore.instance
          .collection('invoice_counters')
          .doc(userId);
      
      final counterSnapshot = await counterDoc.get();
      int nextNumber = 1;
      
      if (counterSnapshot.exists) {
        nextNumber = (counterSnapshot.data()?['count'] ?? 0) + 1;
      }

      final now = DateTime.now();
      
      // Prepare invoice data
      final invoiceData = {
        'id': nextNumber.toString(),
        'invoiceNumber': nextNumber,
        'userId': userId,
        'shop': _selectedShop,
        'items': items.map((item) => {
          'sku': item['sku']?.toString() ?? '',
          'name': item['name']?.toString() ?? '',
          'quantity': (item['quantity'] ?? 0) as int,
          'unit': item['unit']?.toString() ?? '',
          'tp': (item['tp'] ?? 0.0) as double,
          'total': ((item['quantity'] ?? 0) as int) * ((item['tp'] ?? 0.0) as double),
        }).toList(),
        'pricing': {
          'subtotal': subtotal,
          'discount': discount,
          'extraDiscount': extraDiscount,
          'totalDiscount': totalDiscount,
          'finalTotal': finalTotal,
          'discountPercentage': double.tryParse(_discountController.text) ?? 0.0,
          'extraDiscountPercentage': double.tryParse(_extraDiscountController.text) ?? 0.0,
        },
        'createdAt': now.toIso8601String(),
        'status': 'Generated',
        'header': {
          'companyName': 'Al Badar Traders',
          'date': now.toIso8601String().substring(0, 10),
          'invoiceNumber': nextNumber,
        },
      };

      // Save invoice
      await FirebaseFirestore.instance
          .collection('invoices')
          .add(invoiceData);

      // Update invoice counter
      await counterDoc.set({'count': nextNumber});

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
        
        _showSuccessDialog(invoiceData);
      }

    } catch (e) {
      debugPrint('Error saving invoice: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Invoice Created Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Al Badar Traders Header
                    Center(
                      child: Text(
                        'Al Badar Traders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Shop Details
                    Text('Shop: ${invoice['shop']?['name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Address: ${invoice['shop']?['address'] ?? 'N/A'}'),
                    Text('Date: ${DateTime.parse(invoice['createdAt']).toString().substring(0, 10)}'),
                    Text('Invoice #: ${invoice['invoiceNumber'] ?? invoice['id'] ?? 'N/A'}'),
                    const SizedBox(height: 16),
                    
                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text('S#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 2, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 2, child: Text('TP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                              ],
                            ),
                          ),
                          // Table Rows
                          ...List.generate(
                            (invoice['items'] as List).length,
                            (index) {
                              final item = (invoice['items'] as List)[index];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 2, child: Text(item['name'] ?? 'N/A', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 1, child: Text('${item['quantity']}', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 1, child: Text(item['unit'] ?? 'Pcs', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 2, child: Text('Rs ${(item['tp'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 2, child: Text('Rs ${((item['quantity'] as int) * (item['tp'] as double)).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pricing Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Rs ${(invoice['pricing']['subtotal'] as double).toStringAsFixed(2)}'),
                            ],
                          ),
                          if ((invoice['pricing']['discount'] as double) > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:', style: TextStyle(color: Colors.red)),
                                Text('-Rs ${(invoice['pricing']['discount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ],
                          if ((invoice['pricing']['extraDiscount'] as double) > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Extra Discount:', style: TextStyle(color: Colors.red)),
                                Text('-Rs ${(invoice['pricing']['extraDiscount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Final Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Rs ${(invoice['pricing']['finalTotal'] as double).toStringAsFixed(2)}', 
                                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to invoices list
                      },
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _showShareDialog(invoice);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Another'),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareDialog(Map<String, dynamic> invoice) {
    // Prepare data for export service
    final invoiceData = {
      'invoiceNumber': invoice['invoiceNumber'],
      'date': DateTime.parse(invoice['createdAt']).toString().substring(0, 10),
    };
    
    final customerData = invoice['shop'] ?? {};
    final items = List<Map<String, dynamic>>.from(invoice['items'] ?? []);
    final pricing = {
      'subtotal': invoice['pricing']['subtotal'],
      'discount': invoice['pricing']['discount'],
      'extraDiscount': invoice['pricing']['extraDiscount'],
      'total': invoice['pricing']['finalTotal'],
    };

    // Use the public showExportDialog method
    InvoiceExportService.showExportDialog(
      context,
      invoiceData,
      customerData,
      items,
      pricing,
    );
  }

  Future<List<Map<String, dynamic>>> _loadStockItems() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('userId', isEqualTo: userId)
          .where('quantity', isGreaterThan: 0) // Only show items with stock
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

  void _resetForm() {
    _safeSetState(() {
      _selectedShop = null;
      _selectedShopId = null;
      items = [_createEmptyItem()];
      _discountController.text = '0';
      _extraDiscountController.text = '0';
    });
    
    // Clear form validation
    _formKey.currentState?.reset();
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form has been reset'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadShops() async {
    if (_isDisposed) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('userId', isEqualTo: userId)
          .get();

      if (!_isDisposed && mounted) {
        // Process data in background to avoid blocking main thread
        final processedShops = await Future.microtask(() {
          return shopsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();
        });

        _safeSetState(() {
          _shops = processedShops;
        });
      }
    } catch (e) {
      debugPrint('Error loading shops: $e');
      if (!_isDisposed && mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading shops: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }
}
