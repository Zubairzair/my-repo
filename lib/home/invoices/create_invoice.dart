import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateInvoice extends StatefulWidget {
  const CreateInvoice({super.key});

  @override
  State<CreateInvoice> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoice> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _extraDiscountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '17'); // 17% GST for Pakistan
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> items = [
    {'name': '', 'quantity': 1, 'price': 0.0, 'description': ''}
  ];

  bool _isLoading = false;
  String _selectedPaymentTerms = '30 days';
  final List<String> _paymentTermsOptions = ['Immediate', '15 days', '30 days', '45 days', '60 days'];

  // Mathematical calculations with proper logic
  double get subtotal => items.fold(
      0.0,
      (sum, item) =>
          sum +
          ((item['quantity'] ?? 1) as int) *
              ((item['price'] ?? 0.0) as double));

  double get discount => double.tryParse(_discountController.text) ?? 0.0;
  double get extraDiscount => double.tryParse(_extraDiscountController.text) ?? 0.0;
  
  double get taxRate => (double.tryParse(_taxController.text) ?? 0.0) / 100;
  
  double get totalDiscount => discount + extraDiscount;
  double get discountedAmount => subtotal - totalDiscount;
  
  double get taxAmount => discountedAmount * taxRate;
  
  double get total => discountedAmount + taxAmount;

  @override
  void dispose() {
    _customerController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Invoice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernSectionCard(
                      'Customer Information',
                      Icons.person_outline,
                      _buildCustomerSection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildModernSectionCard(
                      'Invoice Items',
                      Icons.receipt_long_outlined,
                      _buildItemsSection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildModernSectionCard(
                      'Pricing & Terms',
                      Icons.calculate_outlined,
                      _buildPricingSection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildModernSectionCard(
                      'Additional Notes',
                      Icons.note_outlined,
                      _buildNotesSection(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSectionCard(String title, IconData icon, Widget content) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      children: [
        TextFormField(
          controller: _customerController,
          decoration: InputDecoration(
            labelText: 'Customer Name *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.business, color: Colors.blueAccent),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter customer name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _customerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Customer Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueAccent),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _customerPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Customer Phone',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.phone_outlined, color: Colors.blueAccent),
            prefixText: '+92 ',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          return _buildModernItemRow(index);
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernItemRow(int index) {
    final qty = (items[index]['quantity'] ?? 1) as int;
    final price = (items[index]['price'] ?? 0.0) as double;
    final itemTotal = qty * price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
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
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              if (items.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    iconSize: 20,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            initialValue: items[index]['name'] ?? '',
            decoration: InputDecoration(
              labelText: 'Item Name *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                items[index]['name'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter item name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          TextFormField(
            initialValue: items[index]['description'] ?? '',
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                items[index]['description'] = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: qty.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      items[index]['quantity'] = int.tryParse(value) ?? 1;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null ||
                        int.parse(value) <= 0) {
                      return 'Valid qty required';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: price.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price (PKR) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      items[index]['price'] = double.tryParse(value) ?? 0.0;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Valid price required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'PKR ${itemTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Discount (PKR)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.discount_outlined, color: Colors.green),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _taxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tax Rate (%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.percent_outlined, color: Colors.orange),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPaymentTerms,
          decoration: InputDecoration(
            labelText: 'Payment Terms',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.schedule_outlined, color: Colors.blue),
          ),
          items: _paymentTermsOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPaymentTerms = newValue!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Additional Notes (Optional)',
        hintText: 'Add any special instructions or terms...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.1),
            Colors.blueAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.summarize_outlined,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Invoice Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal:', 'PKR ${subtotal.toStringAsFixed(2)}', false),
            const SizedBox(height: 8),
            _buildSummaryRow('Discount:', '- PKR ${discount.toStringAsFixed(2)}', false, color: Colors.red),
            const SizedBox(height: 8),
            _buildSummaryRow('After Discount:', 'PKR ${discountedAmount.toStringAsFixed(2)}', false),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax (${_taxController.text}%):', 'PKR ${taxAmount.toStringAsFixed(2)}', false, color: Colors.orange),
            const Divider(thickness: 2, color: Colors.blueAccent),
            _buildSummaryRow('Total Amount:', 'PKR ${total.toStringAsFixed(2)}', true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isBold ? Colors.black87 : Colors.black54),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isBold ? Colors.green : Colors.black87),
          ),
        ),
      ],
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
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text(
                            'Create Invoice',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      items.add({'name': '', 'quantity': 1, 'price': 0.0, 'description': ''});
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    bool allItemsValid = items.every((item) =>
        (item['name'] ?? '').toString().isNotEmpty &&
        ((item['quantity'] ?? 0) as int) > 0 &&
        ((item['price'] ?? 0.0) as double) > 0);

    if (!allItemsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required item details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final invoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final now = DateTime.now();

      final invoice = {
        'id': invoiceId,
        'userId': user.uid,
        'customer': {
          'name': _customerController.text,
          'email': _customerEmailController.text,
          'phone': _customerPhoneController.text,
        },
        'items': List.from(items),
        'pricing': {
          'subtotal': subtotal,
          'discount': discount,
          'discountedAmount': discountedAmount,
          'taxRate': taxRate * 100, // Store as percentage
          'taxAmount': taxAmount,
          'total': total,
        },
        'paymentTerms': _selectedPaymentTerms,
        'notes': _notesController.text,
        'status': 'Pending',
        'createdAt': now.toIso8601String(),
        'dueDate': _calculateDueDate(now, _selectedPaymentTerms).toIso8601String(),
        'currency': 'PKR',
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoiceId)
          .set(invoice);

      // Automatically add transaction for invoice (like Udhar Book)
      await FirebaseFirestore.instance
          .collection('transactions')
          .add({
        'userId': user.uid,
        'type': 'Invoice Payment',
        'description': 'Invoice ${invoiceId} - ${_customerController.text}',
        'amount': total,
        'category': 'Sales',
        'createdAt': now.toIso8601String(),
        'date': now.toString().substring(0, 10),
        'relatedInvoiceId': invoiceId,
      });

      if (mounted) {
        _showSuccessDialog(invoice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _calculateDueDate(DateTime createdDate, String paymentTerms) {
    switch (paymentTerms) {
      case 'Immediate':
        return createdDate;
      case '15 days':
        return createdDate.add(const Duration(days: 15));
      case '30 days':
        return createdDate.add(const Duration(days: 30));
      case '45 days':
        return createdDate.add(const Duration(days: 45));
      case '60 days':
        return createdDate.add(const Duration(days: 60));
      default:
        return createdDate.add(const Duration(days: 30));
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
          padding: const EdgeInsets.all(24),
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
                    Text('Invoice ID: ${invoice['id']}'),
                    const SizedBox(height: 4),
                    Text('Customer: ${invoice['customer']['name']}'),
                    const SizedBox(height: 4),
                    Text('Amount: PKR ${(invoice['pricing']['total'] as double).toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Text('Status: ${invoice['status']}'),
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
                        _resetForm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create Another'),
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

  void _resetForm() {
    _customerController.clear();
    _customerEmailController.clear();
    _customerPhoneController.clear();
    _discountController.text = '0';
    _taxController.text = '17';
    _notesController.clear();
    setState(() {
      items = [{'name': '', 'quantity': 1, 'price': 0.0, 'description': ''}];
      _selectedPaymentTerms = '30 days';
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Invoice Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Creating an Invoice:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Fill in customer information'),
              Text('• Add items with quantities and prices'),
              Text('• Set discount and tax rates'),
              Text('• Choose payment terms'),
              Text('• Add any additional notes'),
              SizedBox(height: 16),
              Text(
                'Currency:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('All amounts are in Pakistani Rupees (PKR)'),
              SizedBox(height: 16),
              Text(
                'Tax Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Default tax rate is 17% (Pakistan GST)'),
              Text('You can adjust the tax rate as needed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}