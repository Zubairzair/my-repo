import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profits extends StatefulWidget {
  const Profits({super.key});

  @override
  State<Profits> createState() => _ProfitsState();
}

class _ProfitsState extends State<Profits> {
  String selectedPeriod = 'This Month';
  final List<String> periods = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildStatsCards(),
          Expanded(child: _buildProfitsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flex(
                  direction: isTablet ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isTablet 
                      ? CrossAxisAlignment.center 
                      : CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: isTablet ? 3 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Profit & Loss',
                              style: TextStyle(
                                fontSize: isTablet ? 32 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Track your business profitability',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isTablet) const SizedBox(width: 20),
                    if (!isTablet) const SizedBox(height: 16),
                    Flexible(
                      flex: isTablet ? 1 : 0,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          size: isTablet ? 40 : 32,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Period Filter
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Period: ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        DropdownButton<String>(
                          value: selectedPeriod,
                          underline: const SizedBox.shrink(),
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildEmptyStatsCards();
        }

        final invoices = snapshot.data!.docs;
        // Since all invoices are paid by default, use all invoices
        final totalRevenue = invoices.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['pricing']['total'] as double? ?? 0);
        });

        final totalCost = totalRevenue * 0.7; // Assume 70% cost ratio
        final totalProfit = totalRevenue - totalCost;
        final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;

        // Calculate this month's revenue
        final now = DateTime.now();
        final thisMonthRevenue = invoices.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = DateTime.parse(data['createdAt']);
          return createdAt.month == now.month && createdAt.year == now.year;
        }).fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['pricing']['total'] as double? ?? 0);
        });

        return Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                // Large screens: 4 cards in 2 rows
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Revenue',
                            'PKR ${totalRevenue.toStringAsFixed(0)}',
                            Icons.trending_up,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Profit',
                            'PKR ${totalProfit.toStringAsFixed(0)}',
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
                            '${profitMargin.toStringAsFixed(1)}%',
                            Icons.percent,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'This Month',
                            'PKR ${thisMonthRevenue.toStringAsFixed(0)}',
                            Icons.calendar_today,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else if (constraints.maxWidth > 400) {
                // Medium screens: 2 cards per row
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Revenue',
                            'PKR ${totalRevenue.toStringAsFixed(0)}',
                            Icons.trending_up,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Profit',
                            'PKR ${totalProfit.toStringAsFixed(0)}',
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
                            '${profitMargin.toStringAsFixed(1)}%',
                            Icons.percent,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'This Month',
                            'PKR ${thisMonthRevenue.toStringAsFixed(0)}',
                            Icons.calendar_today,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Small screens: Stack vertically
                return Column(
                  children: [
                    _buildSummaryCard(
                      'Total Revenue',
                      'PKR ${totalRevenue.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Total Profit',
                      'PKR ${totalProfit.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'Profit Margin',
                      '${profitMargin.toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      'This Month',
                      'PKR ${thisMonthRevenue.toStringAsFixed(0)}',
                      Icons.calendar_today,
                      Colors.purple,
                    ),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyStatsCards() {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('Total Revenue', 'PKR 0', Icons.trending_up, Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('Total Profit', 'PKR 0', Icons.account_balance_wallet, Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('Profit Margin', '0%', Icons.percent, Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('This Month', 'PKR 0', Icons.calendar_today, Colors.purple),
                    ),
                  ],
                ),
              ],
            );
          } else if (constraints.maxWidth > 400) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('Total Revenue', 'PKR 0', Icons.trending_up, Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('Total Profit', 'PKR 0', Icons.account_balance_wallet, Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('Profit Margin', '0%', Icons.percent, Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard('This Month', 'PKR 0', Icons.calendar_today, Colors.purple),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildSummaryCard('Total Revenue', 'PKR 0', Icons.trending_up, Colors.blue),
                const SizedBox(height: 12),
                _buildSummaryCard('Total Profit', 'PKR 0', Icons.account_balance_wallet, Colors.green),
                const SizedBox(height: 12),
                _buildSummaryCard('Profit Margin', '0%', Icons.percent, Colors.orange),
                const SizedBox(height: 12),
                _buildSummaryCard('This Month', 'PKR 0', Icons.calendar_today, Colors.purple),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isLargeCard = constraints.maxWidth > 200;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isLargeCard ? 10 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isLargeCard ? 24 : 20,
                ),
              ),
              SizedBox(height: isLargeCard ? 16 : 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isLargeCard ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              SizedBox(height: isLargeCard ? 6 : 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isLargeCard ? 14 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfitsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'Paid')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final invoices = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    // Stack title and button vertically on small screens
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Profit Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _showProfitAnalysis,
                            icon: const Icon(Icons.analytics_outlined, size: 18),
                            label: const Text('Analysis'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Side by side layout for larger screens
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Profit Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showProfitAnalysis,
                          icon: const Icon(Icons.analytics_outlined, size: 18),
                          label: const Text('Analysis'),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index].data() as Map<String, dynamic>;
                  return _buildProfitCard(invoice);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                Icons.trending_up_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'No profit data yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Complete some paid invoices to see your profit analysis',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(Map<String, dynamic> invoice) {
    final createdAt = DateTime.parse(invoice['createdAt']);
    final total = invoice['pricing']['total'] as double;
    final estimatedCost = total * 0.7; // Assuming 70% cost
    final estimatedProfit = total - estimatedCost;
    final profitMargin = (estimatedProfit / total) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isNarrow = constraints.maxWidth < 400;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flex(
                  direction: isNarrow ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isNarrow 
                      ? CrossAxisAlignment.start 
                      : CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              invoice['id'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              invoice['customer']['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isNarrow) const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildProfitRow(
                        'Revenue:',
                        'PKR ${total.toStringAsFixed(2)}',
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildProfitRow(
                        'Est. Cost:',
                        'PKR ${estimatedCost.toStringAsFixed(2)}',
                        Colors.red,
                      ),
                      const Divider(height: 20),
                      _buildProfitRow(
                        'Est. Profit:',
                        'PKR ${estimatedProfit.toStringAsFixed(2)}',
                        Colors.green,
                        isTotal: true,
                      ),
                      const SizedBox(height: 8),
                      _buildProfitRow(
                        'Margin:',
                        '${profitMargin.toStringAsFixed(1)}%',
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfitRow(String label, String value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProfitAnalysis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profit Analysis',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Key Insights:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildInsightCard(
                          'Revenue Trend',
                          'Your revenue is showing steady growth',
                          Icons.trending_up,
                          Colors.green,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInsightCard(
                          'Profit Margin',
                          'Healthy profit margins maintained',
                          Icons.pie_chart,
                          Colors.blue,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInsightCard(
                          'Payment Collection',
                          'Monitor pending payments for better cash flow',
                          Icons.account_balance_wallet,
                          Colors.orange,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Recommendations:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          '• Focus on collecting pending payments to improve cash flow\n'
                          '• Track actual costs for more accurate profit calculations\n'
                          '• Consider offering early payment discounts\n'
                          '• Analyze high-margin products for growth opportunities',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isNarrow = constraints.maxWidth < 300;
          
          return Flex(
            direction: isNarrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isNarrow 
                ? CrossAxisAlignment.start 
                : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(
                width: isNarrow ? 0 : 16,
                height: isNarrow ? 12 : 0,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}