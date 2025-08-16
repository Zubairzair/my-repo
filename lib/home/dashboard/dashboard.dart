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
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: 16,
        ),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isTablet = constraints.maxWidth > 600;
          
          return Flex(
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
                        'Welcome to Dashboard',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Manage your sales and track performance',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: Colors.grey[600],
                        ),
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

                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Total Sales: PKR ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        );
                      },
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
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dashboard,
                    size: isTablet ? 48 : 40,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          );
        },
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
        final paidInvoices = totalInvoices; // All invoices are paid now
        
        final totalAmount = invoices.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['pricing']['total'] as double? ?? 0);
        });

        // Since all invoices are paid by default, paid amount = total amount
        final paidAmount = totalAmount;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive design based on screen width
            int crossAxisCount = 2;
            double childAspectRatio = 1.2;
            
            if (constraints.maxWidth > 900) {
              crossAxisCount = 4;
              childAspectRatio = 1.3;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 3;
              childAspectRatio = 1.25;
            } else if (constraints.maxWidth > 400) {
              crossAxisCount = 2;
              childAspectRatio = 1.15;
            }
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Total Invoices',
                  totalInvoices.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Paid Invoices',
                  paidInvoices.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Revenue',
                  'PKR ${_formatAmount(paidAmount)}',
                  Icons.trending_up,
                  Colors.purple,
                ),
                _buildStatCard(
                  'This Month',
                  '${DateTime.now().day}/${DateTime.now().month}',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double childAspectRatio = 1.2;
        
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
          childAspectRatio = 1.3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.25;
        } else if (constraints.maxWidth > 400) {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        }
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard('Total Invoices', '0', Icons.receipt_long, Colors.blue),
            _buildStatCard('Pending', '0', Icons.pending, Colors.orange),
            _buildStatCard('Paid Amount', 'PKR 0', Icons.check_circle, Colors.green),
            _buildStatCard('Overdue', '0', Icons.warning, Colors.red),
          ],
        );
      },
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
      padding: const EdgeInsets.all(12),
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
          bool isSmallCard = constraints.maxWidth < 120;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallCard ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallCard ? 18 : 20,
                ),
              ),
              SizedBox(height: isSmallCard ? 4 : 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmallCard ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(height: isSmallCard ? 2 : 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallCard ? 9 : 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          );
        },
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
        LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isTablet 
                      ? (constraints.maxWidth - 36) / 4 
                      : (constraints.maxWidth - 12) / 2,
                  child: _buildActionCard(
                    'Create Invoice',
                    Icons.add_circle_outline,
                    Colors.blueAccent,
                    () {
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                ),
                SizedBox(
                  width: isTablet 
                      ? (constraints.maxWidth - 36) / 4 
                      : (constraints.maxWidth - 12) / 2,
                  child: _buildActionCard(
                    'View Reports',
                    Icons.analytics_outlined,
                    Colors.green,
                    () {
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                ),
                SizedBox(
                  width: isTablet 
                      ? (constraints.maxWidth - 36) / 4 
                      : (constraints.maxWidth - 12) / 2,
                  child: _buildActionCard(
                    'Check Profits',
                    Icons.trending_up_outlined,
                    Colors.orange,
                    () {
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                ),
                SizedBox(
                  width: isTablet 
                      ? (constraints.maxWidth - 36) / 4 
                      : (constraints.maxWidth - 12) / 2,
                  child: _buildActionCard(
                    'Profile Settings',
                    Icons.person_outline,
                    Colors.purple,
                    () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
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
          mainAxisSize: MainAxisSize.min,
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
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
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Recent Invoices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
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
      width: double.infinity,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isNarrow = constraints.maxWidth < 350;
          
          return Column(
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            invoice['customer']['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
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
                  if (!isNarrow) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PKR ${(invoice['pricing']['total'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
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
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'PKR ${(invoice['pricing']['total'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
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
            ],
          );
        },
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