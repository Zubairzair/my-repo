import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentInvoices(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your sales and track performance',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('invoices')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final invoices = snapshot.data!.docs;
                    final totalAmount = invoices.fold<double>(0, (sum, doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return sum + (data['pricing']['total'] as double? ?? 0);
                    });

                    return Text(
                      'Total Sales: PKR ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard,
              size: 40,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyStatsGrid();
        }

        final invoices = snapshot.data!.docs;
        final totalInvoices = invoices.length;
        final pendingInvoices = invoices.where((doc) => doc['status'] == 'Pending').length;
        final paidInvoices = invoices.where((doc) => doc['status'] == 'Paid').length;
        
        final totalAmount = invoices.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['pricing']['total'] as double? ?? 0);
        });

        final paidAmount = invoices
            .where((doc) => doc['status'] == 'Paid')
            .fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['pricing']['total'] as double? ?? 0);
        });

        final pendingAmount = totalAmount - paidAmount;

        // Calculate overdue invoices
        final now = DateTime.now();
        final overdueInvoices = invoices.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dueDate = DateTime.parse(data['dueDate']);
          return dueDate.isBefore(now) && data['status'] == 'Pending';
        }).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive design based on screen width
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              double childAspectRatio = constraints.maxWidth > 600 ? 1.5 : 1.3;
              
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    'Total Invoices',
                    totalInvoices.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Pending',
                    pendingInvoices.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Paid Amount',
                    'PKR ${_formatAmount(paidAmount)}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Overdue',
                    overdueInvoices.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
          double childAspectRatio = constraints.maxWidth > 600 ? 1.5 : 1.3;
          
          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Total Invoices', '0', Icons.receipt_long, Colors.blue),
              _buildStatCard('Pending', '0', Icons.pending, Colors.orange),
              _buildStatCard('Paid Amount', 'PKR 0', Icons.check_circle, Colors.green),
              _buildStatCard('Overdue', '0', Icons.warning, Colors.red),
            ],
          );
        },
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(
              'Create Invoice',
              Icons.add_circle_outline,
              Colors.blueAccent,
              () {
                Navigator.pushNamed(context, '/home');
                // Navigate to invoices tab and open create invoice
                DefaultTabController.of(context)?.animateTo(1);
              },
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              'View Reports',
              Icons.analytics_outlined,
              Colors.green,
              () {
                Navigator.pushNamed(context, '/home');
                // Navigate to stock/reports tab
                DefaultTabController.of(context)?.animateTo(2);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionCard(
              'Check Profits',
              Icons.trending_up_outlined,
              Colors.orange,
              () {
                Navigator.pushNamed(context, '/home');
                // Navigate to profits tab
                DefaultTabController.of(context)?.animateTo(3);
              },
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              'Profile Settings',
              Icons.person_outline,
              Colors.purple,
              () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentInvoices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Invoices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
                // Navigate to invoices tab
                DefaultTabController.of(context)?.animateTo(1);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('invoices')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyRecentInvoices();
            }

            final invoices = snapshot.data!.docs;
            return Column(
              children: invoices.map((doc) {
                final invoice = doc.data() as Map<String, dynamic>;
                return _buildRecentInvoiceCard(invoice);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyRecentInvoices() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No invoices yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoiceCard(Map<String, dynamic> invoice) {
    final createdAt = DateTime.parse(invoice['createdAt']);
    
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt,
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice['customer']['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${(invoice['pricing']['total'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invoice['status'],
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(invoice['status']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}