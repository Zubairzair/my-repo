import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateInvoice extends StatefulWidget {
  const CreateInvoice({super.key});

  @override
  State<CreateInvoice> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoice> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  
  List<Map<String, dynamic>> items = [
    {'name': '', 'quantity': 1, 'price': 0.0}
  ];

  double get subtotal => items.fold(0, (sum, item) => 
    sum + (item['quantity'] * item['price']));
  
  double get discount => double.tryParse(_discountController.text) ?? 0;
  
  double get total => subtotal - discount;

  @override
  void dispose() {
    _customerController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    // Customer Information
                    _buildSectionHeader('Customer Information'),
                    TextFormField(
                      controller: _customerController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Items Section
                    _buildSectionHeader('Items'),
                    ...items.asMap().entries.map((entry) {
                      int index = entry.key;
                      return _buildItemRow(index);
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Discount Section
                    _buildSectionHeader('Discount'),
                    TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Discount Amount (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.discount),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Summary Section
                    _buildSummarySection(),
                  ],
                ),
              ),
            ),

            // Bottom Action Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveInvoice,
                      child: const Text('Create Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (items.length > 1)
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: items[index]['name'],
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: items[index]['quantity'].toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Qty *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      items[index]['quantity'] = int.tryParse(value) ?? 1;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
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
                  initialValue: items[index]['price'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹) *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      items[index]['price'] = double.tryParse(value) ?? 0.0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Valid price required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ₹${(items[index]['quantity'] * items[index]['price']).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'Invoice Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('₹${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount:', style: TextStyle(color: Colors.red)),
              Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addItem() {
    setState(() {
      items.add({'name': '', 'quantity': 1, 'price': 0.0});
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _saveInvoice() {
    if (_formKey.currentState!.validate()) {
      // Validate that all items have names
      bool allItemsValid = items.every((item) => 
        item['name'].toString().isNotEmpty && 
        item['quantity'] > 0 && 
        item['price'] > 0
      );

      if (!allItemsValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all item details')),
        );
        return;
      }

      // Generate invoice ID
      final invoiceId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // Create invoice object
      final invoice = {
        'id': invoiceId,
        'customer': _customerController.text,
        'amount': subtotal,
        'discount': discount,
        'finalAmount': total,
        'date': DateTime.now().toString().substring(0, 10),
        'status': 'Pending',
        'items': List.from(items),
      };

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invoice Created!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice ID: ${invoice['id']}'),
              Text('Customer: ${invoice['customer']}'),
              Text('Amount: ₹${invoice['finalAmount'].toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to invoices list
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}