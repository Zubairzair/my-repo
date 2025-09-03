void _showSuccessDialog(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Invoice Created Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Al Badar Traders Header
                    Center(
                      child: Text(
                        'Al Badar Traders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Shop Details
                    Text('Shop: ${invoice['shop']?['name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Address: ${invoice['shop']?['address'] ?? 'N/A'}'),
                    Text('Date: ${DateTime.parse(invoice['createdAt']).toString().substring(0, 10)}'),
                    Text('Invoice #: ${invoice['invoiceNumber'] ?? invoice['id'] ?? 'N/A'}'),
                    const SizedBox(height: 16),
                    
                    // Items Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 1, child: Text('S#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 2, child: Text('TP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                              ],
                            ),
                          ),
                          // Table Rows
                          ...List.generate(
                            (invoice['items'] as List).length,
                            (index) {
                              final item = (invoice['items'] as List)[index];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(item['barcode'] ?? 'N/A', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 2, child: Text(item['sku'] ?? '', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 1, child: Text('${item['quantity']}', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 1, child: Text(item['unit'] ?? 'Pcs', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 2, child: Text('Rs ${(item['tp'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10))),
                                    Expanded(flex: 2, child: Text('Rs ${((item['quantity'] as int) * (item['tp'] as double)).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pricing Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('Rs ${(invoice['pricing']['subtotal'] as double).toStringAsFixed(2)}'),
                            ],
                          ),
                          if ((invoice['pricing']['discount'] as double) > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:', style: TextStyle(color: Colors.red)),
                                Text('-Rs ${(invoice['pricing']['discount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ],
                          if ((invoice['pricing']['extraDiscount'] as double) > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Extra Discount:', style: TextStyle(color: Colors.red)),
                                Text('-Rs ${(invoice['pricing']['extraDiscount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Final Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Rs ${(invoice['pricing']['finalTotal'] as double).toStringAsFixed(2)}', 
                                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to invoices list
                      },
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _showShareDialog(invoice);
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Another'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
