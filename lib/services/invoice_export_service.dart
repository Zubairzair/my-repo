import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:screenshot/screenshot.dart';

class InvoiceExportService {

  // Show export options dialog
  static Future<void> showExportDialog(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Share Invoice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose format to share:'),
              const SizedBox(height: 16),
              _buildExportOption(
                context,
                icon: Icons.picture_as_pdf,
                title: 'PDF Format',
                subtitle: 'Professional document format',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _exportToPDF(context, invoiceData, customerData, items, pricing);
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.table_chart,
                title: 'Excel Format',
                subtitle: 'Spreadsheet format',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcel(context, invoiceData, customerData, items, pricing);
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.image,
                title: 'Image Format',
                subtitle: 'Screenshot format',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _exportToImage(context, invoiceData, customerData, items, pricing);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Export as PDF
  static Future<void> _exportToPDF(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    bool isDialogShowing = false;
    try {
      print('Starting PDF generation...');
      
      // Show loading dialog
      if (context.mounted) {
        isDialogShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating PDF...')],
            ),
          ),
        );
      }

      // Run PDF generation in background to prevent main thread blocking
      final pdfData = await _generatePDFInBackground(invoiceData, customerData, items, pricing);
      
      print('PDF bytes generated: ${pdfData.length} bytes');
      
      // Get temp directory and create file
      print('Getting temporary directory...');
      final output = await getTemporaryDirectory();
      final fileName = 'invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      
      print('Writing PDF file to: ${file.path}');
      await file.writeAsBytes(pdfData);
      
      // Validate file was created successfully
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('File created: $fileExists, Size: $fileSize bytes');
      
      if (!fileExists || fileSize == 0) {
        throw Exception('Failed to create PDF file or file is empty');
      }
      
      // Close loading dialog before sharing
      if (isDialogShowing && context.mounted) {
        Navigator.pop(context);
        isDialogShowing = false;
      }
      
      print('Sharing PDF file...');
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice PDF');
      print('PDF sharing completed successfully');
      
    } catch (e, stackTrace) {
      print('Error generating PDF: $e');
      print('Stack trace: $stackTrace');
      
      if (isDialogShowing && context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Generate PDF in background to prevent main thread blocking
  static Future<List<int>> _generatePDFInBackground(
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    return await compute(_createPDFDocument, {
      'invoiceData': invoiceData,
      'customerData': customerData,
      'items': items,
      'pricing': pricing,
    });
  }

  // Static function for compute isolate
  static Future<List<int>> _createPDFDocument(Map<String, dynamic> data) async {
    print('Creating PDF document in isolate...');
    
    final invoiceData = data['invoiceData'] as Map<String, dynamic>;
    final customerData = data['customerData'] as Map<String, dynamic>;
    final items = data['items'] as List<Map<String, dynamic>>;
    final pricing = data['pricing'] as Map<String, dynamic>;
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'Al Badar Traders',
                  style: const pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Invoice details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Shop: ${customerData['name'] ?? 'N/A'}'),
                      pw.Text('Address: ${customerData['address'] ?? 'N/A'}'),
                      if (customerData['phone'] != null) pw.Text('Phone: ${customerData['phone']}'),
                      if (customerData['email'] != null) pw.Text('Email: ${customerData['email']}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}'),
                      pw.Text('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: ['S#', 'Item Name', 'Qty', 'Unit', 'TP', 'Total']
                        .map((text) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
                            ))
                        .toList(),
                  ),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final tp = (item['tp'] ?? 0.0) as double;
                    final quantity = (item['quantity'] ?? 1) as int;
                    final total = tp * quantity;
                    return pw.TableRow(
                      children: [
                        '${index + 1}',
                        item['name']?.toString() ?? 'N/A',
                        '$quantity',
                        item['unit']?.toString() ?? 'Pcs',
                        'Rs ${tp.toStringAsFixed(2)}',
                        'Rs ${total.toStringAsFixed(2)}',
                      ].map((text) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8), 
                        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9))
                      )).toList(),
                    );
                  }).toList(),
                ],
              ),
          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 200,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal:'),
                      pw.Text('Rs ${((pricing['subtotal'] ?? 0.0) as double).toStringAsFixed(2)}'),
                    ],
                  ),
                  if ((pricing['discount'] ?? 0.0) > 0) ...[
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Discount:'),
                        pw.Text('-Rs ${((pricing['discount'] ?? 0.0) as double).toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  if ((pricing['extraDiscount'] ?? 0.0) > 0) ...[
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Extra Discount:'),
                        pw.Text('-Rs ${((pricing['extraDiscount'] ?? 0.0) as double).toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  pw.Container(height: 1, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 8)),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Final Total:'),
                      pw.Text('Rs ${((pricing['total'] ?? 0.0) as double).toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }),
  );

    final pdfBytes = await pdf.save();
    return pdfBytes;
  }

  // Export as Excel
  static Future<void> _exportToExcel(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    bool isDialogShowing = false;
    try {
      print('Starting Excel generation...');
      
      if (context.mounted) {
        isDialogShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating Excel...')],
            ),
          ),
        );
      }

      // Run Excel generation in background
      final excelData = await _generateExcelInBackground(invoiceData, customerData, items, pricing);
      
      print('Excel bytes generated: ${excelData.length} bytes');
      
      print('Getting temporary directory...');
      final output = await getTemporaryDirectory();
      final fileName = 'invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${output.path}/$fileName');
      
      print('Writing Excel file to: ${file.path}');
      await file.writeAsBytes(excelData);
      
      // Validate file was created successfully
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('File created: $fileExists, Size: $fileSize bytes');
      
      if (!fileExists || fileSize == 0) {
        throw Exception('Failed to create Excel file or file is empty');
      }
      
      // Close loading dialog before sharing
      if (isDialogShowing && context.mounted) {
        Navigator.pop(context);
        isDialogShowing = false;
      }
      
      print('Sharing Excel file...');
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice Excel');
      print('Excel sharing completed successfully');
      
    } catch (e, stackTrace) {
      print('Error generating Excel: $e');
      print('Stack trace: $stackTrace');
      
      if (isDialogShowing && context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Excel: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Generate Excel in background
  static Future<List<int>> _generateExcelInBackground(
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    return await compute(_createExcelDocument, {
      'invoiceData': invoiceData,
      'customerData': customerData,
      'items': items,
      'pricing': pricing,
    });
  }

  // Static function for Excel compute isolate
  static List<int> _createExcelDocument(Map<String, dynamic> data) {
    print('Creating Excel document in isolate...');
    
    final invoiceData = data['invoiceData'] as Map<String, dynamic>;
    final customerData = data['customerData'] as Map<String, dynamic>;
    final items = data['items'] as List<Map<String, dynamic>>;
    final pricing = data['pricing'] as Map<String, dynamic>;
    
    var excel = xl.Excel.createExcel();
    xl.Sheet sheetObject = excel['Invoice'];
    
    sheetObject.cell(xl.CellIndex.indexByString("A1")).value = 'Al Badar Traders';
    sheetObject.cell(xl.CellIndex.indexByString("A3")).value = 'Shop: ${customerData['name'] ?? 'N/A'}';
    sheetObject.cell(xl.CellIndex.indexByString("A4")).value = 'Address: ${customerData['address'] ?? 'N/A'}';
    sheetObject.cell(xl.CellIndex.indexByString("E3")).value = 'Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}';
    sheetObject.cell(xl.CellIndex.indexByString("E4")).value = 'Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}';
    
    int headerRow = 8;
    List<String> headers = ['Barcode', 'S#', 'SKU', 'Quantity', 'Unit', 'TP', 'Total'];
    for (int col = 0; col < headers.length; col++) {
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow)).value = headers[col];
    }
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final rowIndex = headerRow + 1 + i;
      final tp = (item['tp'] ?? 0.0) as double;
      final quantity = (item['quantity'] ?? 1) as int;
      final total = tp * quantity;
      
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = item['barcode']?.toString() ?? 'N/A';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = i + 1;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = item['sku']?.toString() ?? '';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = quantity;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = item['unit']?.toString() ?? 'Pcs';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = tp;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = total;
    }

    // Add pricing summary
    int summaryStartRow = headerRow + items.length + 3;
    sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = 'Subtotal:';
    sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: summaryStartRow)).value = (pricing['subtotal'] ?? 0.0) as double;
    
    if ((pricing['discount'] ?? 0.0) > 0) {
      summaryStartRow++;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = 'Discount:';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: summaryStartRow)).value = -((pricing['discount'] ?? 0.0) as double);
    }
    
    if ((pricing['extraDiscount'] ?? 0.0) > 0) {
      summaryStartRow++;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = 'Extra Discount:';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: summaryStartRow)).value = -((pricing['extraDiscount'] ?? 0.0) as double);
    }
    
    summaryStartRow++;
    sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = 'Final Total:';
    sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: summaryStartRow)).value = (pricing['total'] ?? 0.0) as double;

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file bytes');
    }
    
    return fileBytes;
  }

  // Export as Image
  static Future<void> _exportToImage(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    bool isDialogShowing = false;
    try {
      print('Starting Image generation...');
      
      if (context.mounted) {
        isDialogShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating Image...')],
            ),
          ),
        );
      }

      print('Creating invoice widget for screenshot...');
      final invoiceWidget = MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            width: 800,
            padding: const EdgeInsets.all(32),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Text('Al Badar Traders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade800))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shop: ${customerData['name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Address: ${customerData['address'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                        if (customerData['phone'] != null) Text('Phone: ${customerData['phone']}', style: const TextStyle(fontSize: 14)),
                        if (customerData['email'] != null) Text('Email: ${customerData['email']}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}', style: const TextStyle(fontSize: 14)),
                        Text('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 1, child: Text('S#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('TP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final tp = (item['tp'] ?? 0.0) as double;
                        final quantity = (item['quantity'] ?? 1) as int;
                        final total = tp * quantity;
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(item['barcode']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 2, child: Text(item['sku']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 1, child: Text('$quantity', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 1, child: Text(item['unit']?.toString() ?? 'Pcs', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 2, child: Text('Rs ${tp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 2, child: Text('Rs ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(color: Colors.black)),
                            Text('Rs ${((pricing['subtotal'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                        if ((pricing['discount'] ?? 0.0) > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount:', style: TextStyle(color: Colors.black)),
                              Text('-Rs ${((pricing['discount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ],
                        if ((pricing['extraDiscount'] ?? 0.0) > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Extra Discount:', style: TextStyle(color: Colors.black)),
                              Text('-Rs ${((pricing['extraDiscount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.purple)),
                            ],
                          ),
                        ],
                        const Divider(color: Colors.grey),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Final Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                            Text('Rs ${((pricing['total'] ?? 0.0) as double).toStringAsFixed(2)}', 
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      print('Capturing screenshot...');
      ScreenshotController screenshotController = ScreenshotController();
      final imageBytes = await screenshotController.captureFromWidget(
        invoiceWidget,
        pixelRatio: 2.0,
        context: context,
      );
      
      print('Screenshot captured: ${imageBytes.length} bytes');
      
      if (!context.mounted) {
        print('Context no longer mounted, aborting Image export');
        return;
      }

      print('Getting temporary directory...');
      final output = await getTemporaryDirectory();
      final fileName = 'invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${output.path}/$fileName');
      
      print('Writing Image file to: ${file.path}');
      await file.writeAsBytes(imageBytes);
      
      // Validate file was created successfully
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('File created: $fileExists, Size: $fileSize bytes');
      
      if (!fileExists || fileSize == 0) {
        throw Exception('Failed to create Image file or file is empty');
      }
      
      // Close loading dialog before sharing
      if (isDialogShowing && context.mounted) {
        Navigator.pop(context);
        isDialogShowing = false;
      }
      
      print('Sharing Image file...');
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice Image');
      print('Image sharing completed successfully');
      
    } catch (e, stackTrace) {
      print('Error generating Image: $e');
      print('Stack trace: $stackTrace');
      
      if (isDialogShowing && context.mounted) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static Widget _buildInvoiceWidget(
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Al Badar Traders
          const Center(
            child: Text(
              'Al Badar Traders',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Shop Information
          if (customerData['shopName'] != null) ...[
            Center(
              child: Text(
                'Shop: ${customerData['shopName']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
          if (customerData['shopAddress'] != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Address: ${customerData['shopAddress']}',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Date and Invoice Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              Text(
                'Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Items Table with new structure
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('S#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('TP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                    ],
                  ),
                ),
                // Items
                ...items.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('${item['barcode'] ?? 'N/A'}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 2, child: Text('${item['sku'] ?? 'N/A'}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 1, child: Text('${item['quantity'] ?? 0}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 1, child: Text('${item['unit'] ?? 'Pcs'}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 2, child: Text('Rs ${((item['price'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 2, child: Text('Rs ${(((item['quantity'] ?? 1) as int) * ((item['price'] ?? 0.0) as double)).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black))),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pricing Summary
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(color: Colors.black)),
                      Text('Rs ${((pricing['subtotal'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                  if ((pricing['discount'] ?? 0.0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(color: Colors.black)),
                        Text('-Rs ${((pricing['discount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                  if ((pricing['extraDiscount'] ?? 0.0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Extra Discount:', style: TextStyle(color: Colors.black)),
                        Text('-Rs ${((pricing['extraDiscount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.purple)),
                      ],
                    ),
                  ],
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      Text('Rs ${((pricing['total'] ?? 0.0) as double).toStringAsFixed(2)}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
