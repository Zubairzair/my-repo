import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyapar_app/home/invoices/create_invoice.dart';

class Invoices extends StatefulWidget {
  const Invoices({super.key});

  @override
  State<Invoices> createState() => _InvoicesState();
}

class _InvoicesState extends State<Invoices> with AutomaticKeepAliveClientMixin {
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildInvoicesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "invoices_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateInvoice()),
          );
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Invoices',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your sales invoices',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          print('Error in stats: ${snapshot.error}');
          return _buildEmptyStatsRow();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStatsRow();
        }

        final invoices = snapshot.data!.docs;
        final totalInvoices = invoices.length;
        final totalAmount = invoices.fold<double>(0, (sum, doc) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return sum;
            
            final pricing = data['pricing'] as Map<String, dynamic>?;
            if (pricing == null) return sum;
            
            return sum + (pricing['total'] as double? ?? 0);
          } catch (e) {
            print('Error processing invoice: $e');
            return sum;
          }
        });
        final paidInvoices = totalInvoices; // All invoices are now paid by default

        return Row(
          children: [
            _buildStatCard('Total', totalInvoices.toString(), Icons.receipt_long, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard('Paid', paidInvoices.toString(), Icons.check_circle, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard('Amount', 'Rs ${totalAmount.toStringAsFixed(0)}', Icons.attach_money, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStatsRow() {
    return Row(
      children: [
        _buildStatCard('Total', '0', Icons.receipt_long, Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Paid', '0', Icons.check_circle, Colors.green),
        const SizedBox(width: 12),
        _buildStatCard('Amount', 'Rs 0', Icons.attach_money, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAllInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (snapshot.hasError) {
          print('Error loading invoices: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading invoices',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _safeSetState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final invoices = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: invoices.length + 1, // +1 for load more button
          itemBuilder: (context, index) {
            if (index == invoices.length) {
              // Load more button
              if (invoices.length >= _limit) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _loadMoreInvoices,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Load More'),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            
            try {
              final invoice = invoices[index].data() as Map<String, dynamic>?;
              if (invoice == null) return const SizedBox.shrink();
              return _buildInvoiceCard(invoice);
            } catch (e) {
              print('Error rendering invoice: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAllInvoices() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .limit(_limit);

    return query.snapshots();
  }

  void _loadMoreInvoices() {
    // This is a simple implementation. For proper pagination, 
    // you would need to implement startAfterDocument functionality
    _safeSetState(() {
      // Refresh the stream to load more
    });
  }

  Widget _buildEmptyState() {
    return Center(
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
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No invoices yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateInvoice()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    try {
      final createdAt = DateTime.parse(invoice['createdAt'] ?? DateTime.now().toIso8601String());
      final dueDate = DateTime.parse(invoice['dueDate'] ?? DateTime.now().toIso8601String());
      
      // All invoices are now considered "Paid" by default
      const status = 'Paid';
      const statusColor = Colors.green;

      // Safe access to nested fields
      final customer = invoice['customer'] as Map<String, dynamic>? ?? {};
      final pricing = invoice['pricing'] as Map<String, dynamic>? ?? {};
      final total = pricing['total'] as double? ?? 0.0;

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
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice),
          borderRadius: BorderRadius.circular(16),
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
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Amount',
                        'Rs ${total.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Created',
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Due',
                        '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text('Error displaying invoice: ${e.toString()}'),
      );
    }
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
                    child: _buildInvoiceDetailsContent(invoice),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceDetailsContent(Map<String, dynamic> invoice) {
    try {
      final items = List<Map<String, dynamic>>.from(invoice['items'] ?? []);
      final pricing = invoice['pricing'] as Map<String, dynamic>? ?? {};
      final customer = invoice['customer'] as Map<String, dynamic>? ?? {};
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invoice Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Invoice Info
          _buildDetailSection('Invoice Information', [
            _buildDetailRow('Invoice ID', invoice['id'] ?? 'Unknown'),
            _buildDetailRow('Status', 'Paid'), // Always show as Paid
            _buildDetailRow('Created', invoice['createdAt'] != null ? DateTime.parse(invoice['createdAt']).toString().substring(0, 10) : 'Unknown'),
            _buildDetailRow('Due Date', invoice['dueDate'] != null ? DateTime.parse(invoice['dueDate']).toString().substring(0, 10) : 'Unknown'),
            _buildDetailRow('Payment Terms', invoice['paymentTerms'] ?? 'Unknown'),
          ]),
          
          const SizedBox(height: 24),
          
          // Customer Info
          _buildDetailSection('Customer Information', [
            _buildDetailRow('Name', customer['name'] ?? 'Unknown'),
            if ((customer['email'] ?? '').isNotEmpty)
              _buildDetailRow('Email', customer['email']),
            if ((customer['phone'] ?? '').isNotEmpty)
              _buildDetailRow('Phone', '+92 ${customer['phone']}'),
          ]),
          
          const SizedBox(height: 24),
          
          // Items
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildItemDetailCard(item)),
          
          const SizedBox(height: 24),
          
          // Pricing Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Subtotal', 'Rs ${(pricing['subtotal'] as double? ?? 0).toStringAsFixed(2)}'),
                if ((pricing['discount'] as double? ?? 0) > 0)
                  _buildDetailRow('Item Discount', '- Rs ${(pricing['discount'] as double? ?? 0).toStringAsFixed(2)}'),
                if (pricing['extraDiscount'] != null && (pricing['extraDiscount'] as double? ?? 0) > 0)
                  _buildDetailRow('Extra Discount', '- Rs ${(pricing['extraDiscount'] as double? ?? 0).toStringAsFixed(2)}'),
                if ((pricing['taxAmount'] as double? ?? 0) > 0)
                  _buildDetailRow('Tax (${pricing['taxRate'] ?? 0}%)', 'Rs ${(pricing['taxAmount'] as double? ?? 0).toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow(
                  'Total Amount', 
                  'Rs ${(pricing['total'] as double? ?? 0).toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          
          if ((invoice['notes'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('Notes', [
              Text(invoice['notes'] ?? ''),
            ]),
          ],
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateInvoiceStatus(invoice['id'] ?? '', 'Paid');
                  },
                  child: const Text('Mark as Paid'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Center(
        child: Text('Error loading invoice details: ${e.toString()}'),
      );
    }
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailCard(Map<String, dynamic> item) {
    try {
      final quantity = item['quantity'] as int? ?? 1;
      final price = item['price'] as double? ?? 0.0;
      final total = quantity * price;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'] ?? 'Unknown Item',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((item['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$quantity × Rs ${price.toStringAsFixed(2)}'),
                Text(
                  'Rs ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Error displaying item: ${e.toString()}'),
      );
    }
  }

  Future<void> _updateInvoiceStatus(String invoiceId, String status) async {
    if (invoiceId.isEmpty) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoiceId)
          .update({'status': status});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice marked as $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating invoice status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}