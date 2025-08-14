import 'package:flutter/material.dart';

class StockReports extends StatefulWidget {
  const StockReports({super.key});

  @override
  State<StockReports> createState() => _StockReportsState();
}

class _StockReportsState extends State<StockReports> {
  final List<Map<String, dynamic>> stockItems = [
    {
      'id': 'PROD-001',
      'name': 'Laptop',
      'category': 'Electronics',
      'quantity': 25,
      'minStock': 10,
      'price': 2500.00,
      'supplier': 'Tech Supplier Co.',
      'lastUpdated': '2024-01-15',
    },
    {
      'id': 'PROD-002',
      'name': 'Mouse',
      'category': 'Accessories',
      'quantity': 5,
      'minStock': 15,
      'price': 500.00,
      'supplier': 'Hardware Inc.',
      'lastUpdated': '2024-01-14',
    },
    {
      'id': 'PROD-003',
      'name': 'Keyboard',
      'category': 'Accessories',
      'quantity': 30,
      'minStock': 20,
      'price': 800.00,
      'supplier': 'Hardware Inc.',
      'lastUpdated': '2024-01-13',
    },
    {
      'id': 'PROD-004',
      'name': 'Monitor',
      'category': 'Electronics',
      'quantity': 12,
      'minStock': 8,
      'price': 1600.00,
      'supplier': 'Display World',
      'lastUpdated': '2024-01-12',
    },
  ];

  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Electronics', 'Accessories'];

  @override
  Widget build(BuildContext context) {
    final filteredItems = selectedCategory == 'All' 
        ? stockItems 
        : stockItems.where((item) => item['category'] == selectedCategory).toList();

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
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Reports',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Real-time inventory tracking',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddStockDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Stock',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filter Dropdown
                Row(
                  children: [
                    const Text(
                      'Category: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    DropdownButton<String>(
                      value: selectedCategory,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      items: categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stock Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Items',
                    stockItems.length.toString(),
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Low Stock',
                    _getLowStockCount().toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Value',
                    '₹${_getTotalStockValue().toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Stock Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildStockCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> item) {
    bool isLowStock = item['quantity'] < item['minStock'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLowStock ? Border.all(color: Colors.orange, width: 2) : null,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['id']} • ${item['category']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LOW STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${item['quantity']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isLowStock ? Colors.orange : Colors.blueAccent,
                          ),
                        ),
                        Text(
                          ' (Min: ${item['minStock']})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '₹${item['price'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Value: ₹${(item['quantity'] * item['price']).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated: ${item['lastUpdated']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Supplier: ${item['supplier']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _updateStock(item),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _viewStockHistory(item),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('History'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getLowStockCount() {
    return stockItems.where((item) => item['quantity'] < item['minStock']).length;
  }

  double _getTotalStockValue() {
    return stockItems.fold(0, (sum, item) => sum + (item['quantity'] * item['price']));
  }

  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Stock Item'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock item added successfully!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateStock(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Quantity: ${item['quantity']}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'New Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully!')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _viewStockHistory(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock History - ${item['name']}'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Recent Stock Movements:'),
              SizedBox(height: 12),
              Text('• 2024-01-15: +10 units (Purchase)'),
              Text('• 2024-01-14: -5 units (Sale)'),
              Text('• 2024-01-13: +20 units (Purchase)'),
              Text('• 2024-01-12: -3 units (Sale)'),
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
}