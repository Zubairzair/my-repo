import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyapar_app/home/invoices/create_invoice.dart';
import '../../services/invoice_export_service.dart';

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
            
            return sum + (pricing['finalTotal'] as double? ?? 0);
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
            _buildStatCard('Amount', 'PKR ${totalAmount.toStringAsFixed(0)}', Icons.money, Colors.purple),
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
        _buildStatCard('Amount', 'PKR 0', Icons.money, Colors.purple),
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

      // Safe access to nested fields - use shop data if available, otherwise customer
      final shop = invoice['shop'] as Map<String, dynamic>?;
      final customer = invoice['customer'] as Map<String, dynamic>? ?? {};
      final pricing = invoice['pricing'] as Map<String, dynamic>? ?? {};
      final total = pricing['finalTotal'] as double? ?? 0.0;

      // Use shop name if available, otherwise customer name
      final displayName = shop?['name'] ?? customer['name'] ?? 'Unknown Customer';

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
                            displayName,
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
                        Icons.money,
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
      final shop = invoice['shop'] as Map<String, dynamic>?;
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
          ]),
          
          const SizedBox(height: 24),
          
          // Customer/Shop Info
          if (shop != null) ...[
            _buildDetailSection('Shop Information', [
              _buildDetailRow('Name', shop['name'] ?? 'Unknown'),
              if ((shop['address'] ?? '').isNotEmpty)
                _buildDetailRow('Address', shop['address']),
              if ((shop['phone'] ?? '').isNotEmpty)
                _buildDetailRow('Phone', shop['phone']),
              if ((shop['email'] ?? '').isNotEmpty)
                _buildDetailRow('Email', shop['email']),
            ]),
          ] else ...[
            _buildDetailSection('Customer Information', [
              _buildDetailRow('Name', customer['name'] ?? 'Unknown'),
              if ((customer['email'] ?? '').isNotEmpty)
                _buildDetailRow('Email', customer['email']),
              if ((customer['phone'] ?? '').isNotEmpty)
                _buildDetailRow('Phone', customer['phone']),
            ]),
          ],
          
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
                _buildDetailRow('Subtotal', 'PKR ${(pricing['subtotal'] as double? ?? 0).toStringAsFixed(2)}'),
                if ((pricing['discount'] as double? ?? 0) > 0)
                  _buildDetailRow('Discount', '- PKR ${(pricing['discount'] as double? ?? 0).toStringAsFixed(2)}'),
                if (pricing['extraDiscount'] != null && (pricing['extraDiscount'] as double? ?? 0) > 0)
                  _buildDetailRow('Extra Discount', '- PKR ${(pricing['extraDiscount'] as double? ?? 0).toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow(
                  'Total Amount', 
                  'PKR ${(pricing['finalTotal'] as double? ?? 0).toStringAsFixed(2)}',
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
                    final displayName = shop?['name'] ?? customer['name'] ?? 'Unknown Customer';
                    _deleteInvoice(invoice['id'] ?? '', displayName);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareInvoice(invoice);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black87 : Colors.grey[600],
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? Colors.green : Colors.black87,
              ),
              textAlign: TextAlign.end,
              softWrap: true,
              overflow: TextOverflow.visible,
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
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '$quantity × PKR ${price.toStringAsFixed(2)}',
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'PKR ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
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

  Future<void> _deleteInvoice(String invoiceId, String customerName) async {
    if (invoiceId.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete this invoice for "$customerName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('invoices')
                    .doc(invoiceId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invoice deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting invoice: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareInvoice(Map<String, dynamic> invoice) async {
    try {
      // Prepare data for export service
      final shop = invoice['shop'] as Map<String, dynamic>?;
      final customer = invoice['customer'] as Map<String, dynamic>? ?? {};
      final items = List<Map<String, dynamic>>.from(invoice['items'] ?? []);
      final pricing = invoice['pricing'] as Map<String, dynamic>? ?? {};
      
      // Use shop data if available, otherwise customer data
      final customerData = shop ?? customer;
      
      // Show export dialog with proper data structure
      await InvoiceExportService.showExportDialog(
        context,
        {
          'invoiceNumber': invoice['id'],
          'date': invoice['createdAt'] != null ? DateTime.parse(invoice['createdAt']).toString().substring(0, 10) : DateTime.now().toString().substring(0, 10),
        },
        customerData,
        items,
        {
          'subtotal': pricing['subtotal'] ?? 0.0,
          'discount': pricing['discount'] ?? 0.0,
          'extraDiscount': pricing['extraDiscount'] ?? 0.0,
          'taxAmount': 0.0, // No tax in current system
          'total': pricing['finalTotal'] ?? 0.0,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing invoice: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}