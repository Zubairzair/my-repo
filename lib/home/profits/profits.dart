import 'package:flutter/material.dart';

class Profits extends StatefulWidget {
  const Profits({super.key});

  @override
  State<Profits> createState() => _ProfitsState();
}

class _ProfitsState extends State<Profits> {
  final List<Map<String, dynamic>> profitData = [
    {
      'date': '2024-01-15',
      'invoiceId': 'INV-001',
      'customer': 'John Doe',
      'revenue': 2250.00,
      'cost': 1800.00,
      'profit': 450.00,
      'margin': 20.0,
      'paymentStatus': 'Paid',
    },
    {
      'date': '2024-01-14',
      'invoiceId': 'INV-002',
      'customer': 'Jane Smith',
      'revenue': 1800.00,
      'cost': 1440.00,
      'profit': 360.00,
      'margin': 20.0,
      'paymentStatus': 'Pending',
    },
    {
      'date': '2024-01-13',
      'invoiceId': 'INV-003',
      'customer': 'Mike Johnson',
      'revenue': 2880.00,
      'cost': 2304.00,
      'profit': 576.00,
      'margin': 20.0,
      'paymentStatus': 'Paid',
    },
  ];

  String selectedPeriod = 'This Month';
  final List<String> periods = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
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
                            'Profit & Loss',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track your business profitability',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showPaymentLedger,
                      icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                      label: const Text(
                        'Ledger',
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
                
                // Period Filter
                Row(
                  children: [
                    const Text(
                      'Period: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    DropdownButton<String>(
                      value: selectedPeriod,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedPeriod = newValue!;
                        });
                      },
                      items: periods.map<DropdownMenuItem<String>>((String value) {
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
          
          // Profit Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Revenue',
                        '₹${_getTotalRevenue().toStringAsFixed(0)}',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Profit',
                        '₹${_getTotalProfit().toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Profit Margin',
                        '${_getAverageMargin().toStringAsFixed(1)}%',
                        Icons.percent,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Pending Payments',
                        '₹${_getPendingPayments().toStringAsFixed(0)}',
                        Icons.schedule,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profit Details List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: profitData.length,
              itemBuilder: (context, index) {
                final profit = profitData[index];
                return _buildProfitCard(profit);
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
              fontSize: 18,
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

  Widget _buildProfitCard(Map<String, dynamic> profit) {
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
                profit['invoiceId'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: profit['paymentStatus'] == 'Paid' 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profit['paymentStatus'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: profit['paymentStatus'] == 'Paid' 
                      ? Colors.green
                      : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${profit['customer']} • ${profit['date']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Financial Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Revenue:',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      '₹${profit['revenue'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cost:',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      '₹${profit['cost'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profit:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '₹${profit['profit'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Margin:',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      '${profit['margin'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalRevenue() {
    return profitData.fold(0, (sum, profit) => sum + profit['revenue']);
  }

  double _getTotalProfit() {
    return profitData.fold(0, (sum, profit) => sum + profit['profit']);
  }

  double _getAverageMargin() {
    if (profitData.isEmpty) return 0;
    double totalMargin = profitData.fold(0, (sum, profit) => sum + profit['margin']);
    return totalMargin / profitData.length;
  }

  double _getPendingPayments() {
    return profitData
        .where((profit) => profit['paymentStatus'] == 'Pending')
        .fold(0, (sum, profit) => sum + profit['revenue']);
  }

  void _showPaymentLedger() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Ledger'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accounts Receivable:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...profitData
                  .where((profit) => profit['paymentStatus'] == 'Pending')
                  .map((profit) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${profit['invoiceId']} - ${profit['customer']}'),
                            Text('₹${profit['revenue'].toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pending:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${_getPendingPayments().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
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