import 'dart:io';
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
    try {
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

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text('Al Badar Traders', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Shop: ${customerData['name'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Address: ${customerData['address'] ?? 'N/A'}'),
                    if (customerData['phone'] != null) pw.Text('Phone: ${customerData['phone']}'),
                    if (customerData['email'] != null) pw.Text('Email: ${customerData['email']}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}'),
                    pw.Text('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: ['Barcode', 'S#', 'SKU', 'Qty', 'Unit', 'TP', 'Total']
                      .map((text) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))))
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
                      item['barcode']?.toString() ?? 'N/A',
                      '${index + 1}',
                      item['sku']?.toString() ?? '',
                      '$quantity',
                      item['unit']?.toString() ?? 'Pcs',
                      'Rs ${tp.toStringAsFixed(2)}',
                      'Rs ${total.toStringAsFixed(2)}',
                    ].map((text) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(text))).toList(),
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
                        pw.Text('Final Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Rs ${((pricing['total'] ?? 0.0) as double).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ));

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(file.path)], text: 'Invoice PDF');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // Export as Excel
  static Future<void> _exportToExcel(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
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

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.xlsx');
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }
      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(file.path)], text: 'Invoice Excel');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating Excel: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // Export as Image
  static Future<void> _exportToImage(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
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
                              Expanded(flex: 2, child: Text('PKR ${tp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                              Expanded(flex: 2, child: Text('PKR ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
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

      ScreenshotController screenshotController = ScreenshotController();
      final imageBytes = await screenshotController.captureFromWidget(
        invoiceWidget,
        pixelRatio: 2.0,
        context: context,
      );
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(file.path)], text: 'Invoice Image');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating image: ${e.toString()}'), backgroundColor: Colors.red));
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
