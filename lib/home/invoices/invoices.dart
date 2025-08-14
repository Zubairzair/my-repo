import 'package:flutter/material.dart';
import 'package:vyapar_app/home/invoices/create_invoice.dart';

class Invoices extends StatefulWidget {
  const Invoices({super.key});

  @override
  State<Invoices> createState() => _InvoicesState();
}

class _InvoicesState extends State<Invoices> {
  final List<Map<String, dynamic>> invoices = [
    {
      'id': 'INV-001',
      'customer': 'John Doe',
      'amount': 2500.00,
      'discount': 250.00,
      'finalAmount': 2250.00,
      'date': '2024-01-15',
      'status': 'Paid',
      'items': [
        {'name': 'Laptop', 'quantity': 1, 'price': 2500.00}
      ]
    },
    {
      'id': 'INV-002',
      'customer': 'Jane Smith',
      'amount': 1800.00,
      'discount': 0.00,
      'finalAmount': 1800.00,
      'date': '2024-01-14',
      'status': 'Pending',
      'items': [
        {'name': 'Mouse', 'quantity': 2, 'price': 500.00},
        {'name': 'Keyboard', 'quantity': 1, 'price': 800.00}
      ]
    },
    {
      'id': 'INV-003',
      'customer': 'Mike Johnson',
      'amount': 3200.00,
      'discount': 320.00,
      'finalAmount': 2880.00,
      'date': '2024-01-13',
      'status': 'Paid',
      'items': [
        {'name': 'Monitor', 'quantity': 2, 'price': 1600.00}
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create and track your invoices',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateInvoice(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Invoices',
                    invoices.length.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Amount',
                    '₹${_getTotalAmount().toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Invoice List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _buildInvoiceCard(invoice);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice['id'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: invoice['status'] == 'Paid' 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invoice['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: invoice['status'] == 'Paid' 
                      ? Colors.green
                      : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: ${invoice['customer']}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Date: ${invoice['date']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount: ₹${invoice['amount'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (invoice['discount'] > 0) ...[
                    Text(
                      'Discount: -₹${invoice['discount'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  Text(
                    'Final: ₹${invoice['finalAmount'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _viewInvoiceDetails(invoice),
                    icon: const Icon(Icons.visibility_outlined),
                    color: Colors.blueAccent,
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: () => _editInvoice(invoice),
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.orange,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getTotalAmount() {
    return invoices.fold(0, (sum, invoice) => sum + invoice['finalAmount']);
  }

  void _viewInvoiceDetails(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice ${invoice['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${invoice['customer']}'),
              Text('Date: ${invoice['date']}'),
              Text('Status: ${invoice['status']}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...invoice['items'].map<Widget>((item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${item['name']} x${item['quantity']} = ₹${item['price']}'),
              )),
              const SizedBox(height: 16),
              Text('Subtotal: ₹${invoice['amount']}'),
              if (invoice['discount'] > 0)
                Text('Discount: -₹${invoice['discount']}', style: const TextStyle(color: Colors.red)),
              Text('Final Amount: ₹${invoice['finalAmount']}', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editInvoice(Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit invoice feature coming soon!')),
    );
  }
}