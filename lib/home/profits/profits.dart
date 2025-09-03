import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profits extends StatefulWidget {
  const Profits({super.key});

  @override
  State<Profits> createState() => _ProfitsState();
}

class _ProfitsState extends State<Profits> with AutomaticKeepAliveClientMixin {
  String selectedPeriod = 'This Month';
  final List<String> periods = ['Today', 'This Week', 'This Month', 'This Year'];
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStatsCards()),
            SliverFillRemaining(child: _buildProfitsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profit & Loss',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your business profitability',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  size: 32,
                  color: Colors.green,
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
                      _safeSetState(() {
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEmptyStatsCards();
        }

        if (snapshot.hasError) {
          debugPrint('Error in profits stats: ${snapshot.error}');
          return _buildEmptyStatsCards();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStatsCards();
        }

        final invoices = snapshot.data!.docs;
        final totalRevenue = invoices.fold<double>(0, (sum, doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return sum;
            
            final pricing = data['pricing'] as Map<String, dynamic>?;
            if (pricing == null) return sum;
            
            return sum + (pricing['finalTotal'] as double? ?? 0);
          } catch (e) {
            debugPrint('Error processing invoice revenue: $e');
            return sum;
          }
        });

        final totalCost = totalRevenue * 0.7;
        final totalProfit = totalRevenue - totalCost;

        final now = DateTime.now();
        final filteredRevenue = invoices.where((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null || data['createdAt'] == null) return false;
            
            final createdAt = DateTime.parse(data['createdAt']);
            
            switch (selectedPeriod) {
              case 'Today':
                return createdAt.day == now.day && 
                       createdAt.month == now.month && 
                       createdAt.year == now.year;
              case 'This Week':
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 6));
                return createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                       createdAt.isBefore(endOfWeek.add(const Duration(days: 1)));
              case 'This Month':
                return createdAt.month == now.month && createdAt.year == now.year;
              case 'This Year':
                return createdAt.year == now.year;
              default:
                return createdAt.month == now.month && createdAt.year == now.year;
            }
          } catch (e) {
            debugPrint('Error processing invoice date: $e');
            return false;
          }
        }).fold<double>(0, (sum, doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return sum;
            
            final pricing = data['pricing'] as Map<String, dynamic>?;
            if (pricing == null) return sum;
            
            return sum + (pricing['finalTotal'] as double? ?? 0);
          } catch (e) {
            debugPrint('Error processing filtered revenue: $e');
            return sum;
          }
        });

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Revenue',
                      'Rs ${totalRevenue.toStringAsFixed(0)}',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Profit',
                      'Rs ${totalProfit.toStringAsFixed(0)}',
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
                      selectedPeriod,
                      'Rs ${filteredRevenue.toStringAsFixed(0)}',
                      Icons.calendar_today,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(), // Empty space to maintain layout
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStatsCards() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Total Revenue', 'Rs 0', Icons.trending_up, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard('Total Profit', 'Rs 0', Icons.account_balance_wallet, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(selectedPeriod, 'Rs 0', Icons.calendar_today, Colors.purple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(), // Empty space to maintain layout
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Profit Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Add export functionality here
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      'Export',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No profit data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                'Complete some paid invoices to see your profit analysis',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(Map<String, dynamic> invoice) {
    try {
      final createdAt = DateTime.parse(invoice['createdAt'] ?? DateTime.now().toIso8601String());
      final pricing = invoice['pricing'] as Map<String, dynamic>? ?? {};
      final total = pricing['total'] as double? ?? 0.0;
      final estimatedCost = total * 0.7;
      final estimatedProfit = total - estimatedCost;
      final customer = invoice['customer'] as Map<String, dynamic>? ?? {};

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
                          invoice['id'] ?? 'Unknown ID',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['name'] ?? 'Unknown Customer',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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
                      'Rs ${total.toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildProfitRow(
                      'Est. Cost:',
                      'Rs ${estimatedCost.toStringAsFixed(2)}',
                      Colors.red,
                    ),
                    const Divider(height: 20),
                    _buildProfitRow(
                      'Est. Profit:',
                      'Rs ${estimatedProfit.toStringAsFixed(2)}',
                      Colors.green,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building profit card: $e');
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text('Error displaying profit data: ${e.toString()}'),
      );
    }
  }

  Widget _buildProfitRow(String label, String value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black87 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: color,
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
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Profit Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Detailed profit analysis will be available in future updates.',
                      style: TextStyle(fontSize: 16),
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
}