import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:screenshot/screenshot.dart';

class InvoiceExportService {
  static final ScreenshotController _screenshotController = ScreenshotController();

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
            'Export Invoice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose export format:'),
              const SizedBox(height: 16),
              _buildExportOption(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Share as PDF',
                subtitle: 'Professional document format',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _exportAsPDF(context, invoiceData, customerData, items, pricing);
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.table_chart,
                title: 'Share as Excel',
                subtitle: 'Spreadsheet format',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _exportAsExcel(context, invoiceData, customerData, items, pricing);
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.image,
                title: 'Share as Image',
                subtitle: 'Screenshot format',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _exportAsImage(context, invoiceData, customerData, items, pricing);
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
                color: color.withOpacity(0.1),
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
  static Future<void> _exportAsPDF(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
      _showLoadingDialog(context, 'Generating PDF...');

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}'),
                        pw.Text('Date: ${invoiceData['date'] ?? 'N/A'}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Customer Info
                pw.Text(
                  'Bill To:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
                pw.SizedBox(height: 8),
                pw.Text('${customerData['name'] ?? 'N/A'}'),
                pw.Text('${customerData['address'] ?? 'N/A'}'),
                pw.Text('Phone: ${customerData['phone'] ?? 'N/A'}'),
                pw.Text('Email: ${customerData['email'] ?? 'N/A'}'),
                pw.SizedBox(height: 20),
                
                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Items
                    ...items.map((item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${item['name'] ?? 'N/A'}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${item['quantity'] ?? 0}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rs ${((item['price'] ?? 0.0) as double).toStringAsFixed(2)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rs ${(((item['quantity'] ?? 1) as int) * ((item['price'] ?? 0.0) as double)).toStringAsFixed(2)}'),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Pricing Summary
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 200,
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
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:'),
                              pw.Text('-Rs ${((pricing['discount'] ?? 0.0) as double).toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        if ((pricing['extraDiscount'] ?? 0.0) > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Extra Discount:'),
                              pw.Text('-Rs ${((pricing['extraDiscount'] ?? 0.0) as double).toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Tax:'),
                            pw.Text('Rs ${((pricing['taxAmount'] ?? 0.0) as double).toStringAsFixed(2)}'),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs ${((pricing['total'] ?? 0.0) as double).toStringAsFixed(2)}', 
                                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context); // Close loading dialog

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice #${invoiceData['invoiceNumber'] ?? 'N/A'}',
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'Error generating PDF: ${e.toString()}');
    }
  }

  // Export as Excel
  static Future<void> _exportAsExcel(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
      _showLoadingDialog(context, 'Generating Excel...');

      var excel = xl.Excel.createExcel();
      xl.Sheet sheetObject = excel['Invoice'];

      // Header
      sheetObject.cell(xl.CellIndex.indexByString("A1")).value = 'INVOICE';
      sheetObject.cell(xl.CellIndex.indexByString("A1")).cellStyle = xl.CellStyle(
        fontSize: 18,
        bold: true,
      );

      // Invoice Info
      sheetObject.cell(xl.CellIndex.indexByString("A3")).value = 'Invoice Number:';
      sheetObject.cell(xl.CellIndex.indexByString("B3")).value = '${invoiceData['invoiceNumber'] ?? 'N/A'}';
      sheetObject.cell(xl.CellIndex.indexByString("A4")).value = 'Date:';
      sheetObject.cell(xl.CellIndex.indexByString("B4")).value = '${invoiceData['date'] ?? 'N/A'}';

      // Customer Info
      sheetObject.cell(xl.CellIndex.indexByString("A6")).value = 'Bill To:';
      sheetObject.cell(xl.CellIndex.indexByString("A6")).cellStyle = xl.CellStyle(bold: true);
      sheetObject.cell(xl.CellIndex.indexByString("A7")).value = '${customerData['name'] ?? 'N/A'}';
      sheetObject.cell(xl.CellIndex.indexByString("A8")).value = '${customerData['address'] ?? 'N/A'}';
      sheetObject.cell(xl.CellIndex.indexByString("A9")).value = 'Phone: ${customerData['phone'] ?? 'N/A'}';
      sheetObject.cell(xl.CellIndex.indexByString("A10")).value = 'Email: ${customerData['email'] ?? 'N/A'}';

      // Items Header
      int startRow = 12;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow)).value = 'Item';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow)).value = 'Quantity';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: startRow)).value = 'Price';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: startRow)).value = 'Total';

      // Style header row
      for (int i = 0; i < 4; i++) {
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRow)).cellStyle = xl.CellStyle(bold: true);
      }

      // Items Data
      for (int i = 0; i < items.length; i++) {
        int row = startRow + 1 + i;
        var item = items[i];
        double price = (item['price'] ?? 0.0) as double;
        int quantity = (item['quantity'] ?? 1) as int;
        double total = price * quantity;

        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = '${item['name'] ?? 'N/A'}';
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = quantity;
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = price;
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = total;
      }

      // Pricing Summary
      int summaryRow = startRow + items.length + 3;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow)).value = 'Subtotal:';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow)).value = (pricing['subtotal'] ?? 0.0) as double;

      if ((pricing['discount'] ?? 0.0) > 0) {
        summaryRow++;
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow)).value = 'Discount:';
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow)).value = -((pricing['discount'] ?? 0.0) as double);
      }

      if ((pricing['extraDiscount'] ?? 0.0) > 0) {
        summaryRow++;
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow)).value = 'Extra Discount:';
        sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow)).value = -((pricing['extraDiscount'] ?? 0.0) as double);
      }

      summaryRow++;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow)).value = 'Tax:';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow)).value = (pricing['taxAmount'] ?? 0.0) as double;

      summaryRow++;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow)).value = 'Total:';
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow)).value = (pricing['total'] ?? 0.0) as double;
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: summaryRow)).cellStyle = xl.CellStyle(bold: true);
      sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: summaryRow)).cellStyle = xl.CellStyle(bold: true);

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.xlsx');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }

      Navigator.pop(context); // Close loading dialog

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice #${invoiceData['invoiceNumber'] ?? 'N/A'}',
      );

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'Error generating Excel: ${e.toString()}');
    }
  }

  // Export as Image (Screenshot)
  static Future<void> _exportAsImage(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
      _showLoadingDialog(context, 'Generating Image...');

      // Create a widget to capture
      final invoiceWidget = _buildInvoiceWidget(invoiceData, customerData, items, pricing);
      
      // Capture screenshot
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        invoiceWidget,
        pixelRatio: 2.0,
      );

      if (imageBytes != null) {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(imageBytes);

        Navigator.pop(context); // Close loading dialog

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Invoice #${invoiceData['invoiceNumber'] ?? 'N/A'}',
        );
      } else {
        Navigator.pop(context);
        _showErrorDialog(context, 'Failed to capture invoice image');
      }

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'Error generating image: ${e.toString()}');
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INVOICE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Text(
                    'Date: ${invoiceData['date'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Customer Info
          const Text(
            'Bill To:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text('${customerData['name'] ?? 'N/A'}', style: const TextStyle(fontSize: 16, color: Colors.black)),
          Text('${customerData['address'] ?? 'N/A'}', style: const TextStyle(fontSize: 16, color: Colors.black)),
          Text('Phone: ${customerData['phone'] ?? 'N/A'}', style: const TextStyle(fontSize: 16, color: Colors.black)),
          Text('Email: ${customerData['email'] ?? 'N/A'}', style: const TextStyle(fontSize: 16, color: Colors.black)),
          const SizedBox(height: 24),
          
          // Items Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                    ],
                  ),
                ),
                // Items
                ...items.map((item) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('${item['name'] ?? 'N/A'}', style: const TextStyle(color: Colors.black))),
                      Expanded(flex: 1, child: Text('${item['quantity'] ?? 0}', style: const TextStyle(color: Colors.black))),
                      Expanded(flex: 2, child: Text('Rs ${((item['price'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black))),
                      Expanded(flex: 2, child: Text('Rs ${(((item['quantity'] ?? 1) as int) * ((item['price'] ?? 0.0) as double)).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black))),
                    ],
                  ),
                )).toList(),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax:', style: TextStyle(color: Colors.black)),
                      Text('Rs ${((pricing['taxAmount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
