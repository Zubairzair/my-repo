import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Dashboard extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const Dashboard({super.key, required this.onNavigateToTab});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with AutomaticKeepAliveClientMixin {
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
      return const Center(child: CircularProgressIndicator());
    }

    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Not authenticated',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to view dashboard',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildMonthlySalesChart(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ]),
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                          try {
                            final data = doc.data() as Map<String, dynamic>;
                            final pricing = data['pricing'] as Map<String, dynamic>?;
                            if (pricing == null) return sum;
                            final total = pricing?['finalTotal'] as double? ?? 0.0;
                            return sum + total;
                          } catch (e) {
                            debugPrint('Error processing invoice total: $e');
                            return sum;
                          }
                        });

                        return Text(
                          'Total Sales: Rs ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
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
              const SizedBox(width: 16),
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

        if (snapshot.hasError) {
          debugPrint('Dashboard stats error: ${snapshot.error}');
          return _buildErrorStatsGrid(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyStatsGrid();
        }

        try {
          final invoices = snapshot.data!.docs;
          final totalInvoices = invoices.length;
          final paidInvoices = totalInvoices; // All invoices are paid now

          final totalAmount = invoices.fold<double>(0, (sum, doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final pricing = data['pricing'] as Map<String, dynamic>?;
              return sum + (pricing?['finalTotal'] as double? ?? 0);
            } catch (e) {
              debugPrint('Error processing invoice ${doc.id}: $e');
              return sum;
            }
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
                    'Rs ${_formatAmount(paidAmount)}',
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
        } catch (e) {
          debugPrint('Error building stats grid: $e');
          return _buildErrorStatsGrid(e.toString());
        }
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
            _buildStatCard('Paid Invoices', '0', Icons.check_circle, Colors.green),
            _buildStatCard('Total Revenue', 'Rs 0', Icons.trending_up, Colors.purple),
            _buildStatCard('This Month', '${DateTime.now().day}/${DateTime.now().month}', Icons.calendar_today, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildErrorStatsGrid(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Error loading dashboard data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _safeSetState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
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
                      widget.onNavigateToTab(1); // Navigate to Invoices tab
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
                      widget.onNavigateToTab(2); // Navigate to Stock Reports tab
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
                      widget.onNavigateToTab(3); // Navigate to Profits tab
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


  Widget _buildMonthlySalesChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Sales Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('invoices')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Unable to load chart data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final invoices = snapshot.data!.docs;
              final monthlyData = _calculateMonthlyData(invoices);

              return Column(
                children: [
                  Text(
                    'Sales trend over the last 6 months',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildCustomChart(monthlyData),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateMonthlyData(List<QueryDocumentSnapshot> invoices) {
    final now = DateTime.now();
    final monthlyTotals = <String, double>{};
    
    // Initialize last 6 months with month names
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = _getMonthName(month.month);
      monthlyTotals[monthKey] = 0.0;
    }

    // Calculate totals for each month
    for (final doc in invoices) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = DateTime.parse(data['createdAt']);
        final monthKey = _getMonthName(createdAt.month);
        
        // Only include data from the last 6 months
        final monthsAgo = (now.year - createdAt.year) * 12 + (now.month - createdAt.month);
        if (monthsAgo >= 0 && monthsAgo <= 5 && monthlyTotals.containsKey(monthKey)) {
          final pricing = data['pricing'] as Map<String, dynamic>?;
          final total = pricing?['finalTotal'] as double? ?? 0.0;
          monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + total;
        }
      } catch (e) {
        debugPrint('Error processing invoice for chart: $e');
      }
    }

    return monthlyTotals;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  Widget _buildCustomChart(Map<String, double> monthlyData) {
    if (monthlyData.isEmpty) {
      return const Center(
        child: Text(
          'No sales data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxValue = monthlyData.values.isNotEmpty 
        ? monthlyData.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxWidth > 600 ? 160.0 : 120.0;
        final barSpacing = constraints.maxWidth > 400 ? 8.0 : 4.0;
        final fontSize = constraints.maxWidth > 400 ? 10.0 : 8.0;
        
        return Container(
          padding: EdgeInsets.all(constraints.maxWidth > 400 ? 16.0 : 12.0),
          child: Column(
            children: [
              // Chart bars
              SizedBox(
                height: chartHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: monthlyData.entries.map((entry) {
                    final barHeight = maxValue > 0 
                        ? (entry.value / maxValue) * (chartHeight - 30)
                        : 0.0;
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: barSpacing / 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Value label
                            if (entry.value > 0) ...[
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Rs ${_formatChartAmount(entry.value)}',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueAccent,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            // Bar
                            Container(
                              height: barHeight.clamp(entry.value > 0 ? 8.0 : 2.0, chartHeight - 30),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: entry.value > 0 
                                    ? LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.blueAccent,
                                          Colors.blueAccent.withOpacity(0.6),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.grey.withOpacity(0.3),
                                          Colors.grey.withOpacity(0.1),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Month labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: monthlyData.keys.map((month) {
                  return Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        month,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize + 2,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatChartAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}